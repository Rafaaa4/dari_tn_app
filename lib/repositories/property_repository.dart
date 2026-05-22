import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dari_app/models/property_model.dart';
import 'package:dari_app/models/review_model.dart';
import 'package:dari_app/models/user_model.dart';

class PropertyRepository {
  final _supabase = Supabase.instance.client;

  // Base select query with all joins including images
  static const _fullSelect =
      '*, users!properties_owner_id_fkey(full_name), reviews(rating), property_images(image_path)';

  Future<List<PropertyModel>> getPublishedProperties({
    String? city,
    String? type,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) async {
    var query = _supabase
        .from('properties')
        .select(_fullSelect)
        .eq('status', 'published');

    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }
    if (type != null && type.isNotEmpty) {
      query = query.eq('type', type);
    }
    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
          'title.ilike.%$searchQuery%,description.ilike.%$searchQuery%,city.ilike.%$searchQuery%');
    }

    final data = await query
        .order('is_sponsored', ascending: false)
        .order('created_at', ascending: false);
    return _processProperties(data);
  }

  Future<PropertyModel?> getPropertyById(int id) async {
    try {
      // Fire-and-forget: increment views without blocking the UI
      _supabase
          .rpc('increment_views', params: {'row_id': id})
          .then((_) {})
          .catchError((_) {
            // Fallback: manual increment if RPC doesn't exist
            _supabase
                .from('properties')
                .select('views')
                .eq('id', id)
                .single()
                .then((current) {
              final int views = current['views'] ?? 0;
              _supabase
                  .from('properties')
                  .update({'views': views + 1}).eq('id', id);
            });
          });

      final data = await _supabase
          .from('properties')
          .select(_fullSelect)
          .eq('id', id)
          .single();

      final list = _processProperties([data]);
      return list.isNotEmpty ? list.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<PropertyModel>> getOwnerProperties(String ownerId) async {
    final data = await _supabase
        .from('properties')
        .select(_fullSelect)
        .eq('owner_id', ownerId)
        .neq('status', 'deleted')
        .order('created_at', ascending: false);
    return _processProperties(data);
  }

  Future<List<String>> getPropertyImages(int propertyId) async {
    final data = await _supabase
        .from('property_images')
        .select('image_path')
        .eq('property_id', propertyId)
        .order('created_at', ascending: true);
    return data.map((e) => e['image_path'] as String).toList();
  }

  Future<void> ensureOwnerProfile(UserModel user) async {
    if (user.id == null) {
      throw StateError('Utilisateur connecté sans identifiant.');
    }

    final existing =
        await _supabase.from('users').select('id').eq('id', user.id!).limit(1);
    if (existing.isNotEmpty) return;

    await _supabase.from('users').insert({
      'id': user.id,
      'full_name': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'role': user.role,
      'status': user.status,
    });
  }

  Future<int?> addProperty(PropertyModel property) async {
    final payload = property.toMap();
    final data = await _insertProperty(payload);
    return data['id'] as int?;
  }

  Future<bool> updateProperty(PropertyModel property) async {
    try {
      final payload = Map<String, dynamic>.from(property.toMap())..remove('id');
      await _supabase
          .from('properties')
          .update(payload)
          .eq('id', property.id!)
          .eq('owner_id', property.ownerId);
      return true;
    } on PostgrestException catch (e) {
      if (!_isMissingConditionsColumn(e)) return false;
      final payload = _withoutConditions(property.toMap())..remove('id');
      try {
        await _supabase
            .from('properties')
            .update(payload)
            .eq('id', property.id!)
            .eq('owner_id', property.ownerId);
        return true;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> replacePropertyImages(
      int propertyId, List<String> imagePaths) async {
    try {
      await deletePropertyImages(propertyId);
      for (final imagePath in imagePaths) {
        await addPropertyImage(propertyId, imagePath);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProperty(int id, String ownerId) async {
    try {
      await _supabase
          .from('properties')
          .update({'status': 'deleted'})
          .eq('id', id)
          .eq('owner_id', ownerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addPropertyImage(int propertyId, String imagePath) async {
    await _supabase.from('property_images').insert({
      'property_id': propertyId,
      'image_path': imagePath,
    });
  }

  Future<void> deletePropertyImages(int propertyId) async {
    await _supabase
        .from('property_images')
        .delete()
        .eq('property_id', propertyId);
  }

  // Favorites
  Future<bool> isFavorite(String userId, int propertyId) async {
    final data = await _supabase
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .eq('property_id', propertyId);
    return data.isNotEmpty;
  }

  Future<void> toggleFavorite(String userId, int propertyId) async {
    final isFav = await isFavorite(userId, propertyId);
    if (isFav) {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('property_id', propertyId);
    } else {
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'property_id': propertyId,
      });
    }
  }

  Future<List<PropertyModel>> getFavorites(String userId) async {
    final favs = await _supabase
        .from('favorites')
        .select('property_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    if (favs.isEmpty) return [];

    final propertyIds = favs.map((f) => f['property_id'] as int).toList();

    final data = await _supabase
        .from('properties')
        .select(_fullSelect)
        .inFilter('id', propertyIds)
        .eq('status', 'published');

    return _processProperties(data);
  }

  // Reviews
  Future<List<ReviewModel>> getPropertyReviews(int propertyId) async {
    final data = await _supabase
        .from('reviews')
        .select('*, users!reviews_tenant_id_fkey(full_name)')
        .eq('property_id', propertyId)
        .order('created_at', ascending: false);

    return data.map((e) {
      final map = Map<String, dynamic>.from(e);
      if (map['users'] != null) {
        map['tenant_name'] = map['users']['full_name'];
      }
      return ReviewModel.fromMap(map);
    }).toList();
  }

  Future<void> addReview(ReviewModel review) async {
    await _supabase.from('reviews').insert(review.toMap());
  }

  // Admin
  Future<List<PropertyModel>> getAllProperties() async {
    final data = await _supabase
        .from('properties')
        .select('*, users!properties_owner_id_fkey(full_name)')
        .neq('status', 'deleted')
        .order('created_at', ascending: false);

    return data.map((e) {
      final map = Map<String, dynamic>.from(e);
      if (map['users'] != null) {
        map['owner_name'] = map['users']['full_name'];
      }
      return PropertyModel.fromMap(map);
    }).toList();
  }

  Future<bool> setPropertyStatus(int id, String status) async {
    try {
      await _supabase
          .from('properties')
          .update({'status': status}).eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper to map relational data — now processes images inline (no extra queries!)
  List<PropertyModel> _processProperties(List<dynamic> data) {
    List<PropertyModel> properties = [];
    for (var e in data) {
      final map = Map<String, dynamic>.from(e);

      // Map owner name
      if (map['users'] != null) {
        map['owner_name'] = map['users']['full_name'];
      }

      // Calculate average rating
      if (map['reviews'] != null) {
        final List reviews = map['reviews'];
        map['review_count'] = reviews.length;
        if (reviews.isNotEmpty) {
          final total = reviews.fold(0, (sum, r) => sum + (r['rating'] as int));
          map['avg_rating'] = total / reviews.length;
        }
      }

      // Extract images from the join (no extra query needed!)
      List<String> images = [];
      if (map['property_images'] != null) {
        final List imgList = map['property_images'];
        images = imgList.map((img) => img['image_path'] as String).toList();
      }

      final property = PropertyModel.fromMap(map);
      properties.add(property.copyWith(images: images));
    }
    return properties;
  }

  Future<Map<String, dynamic>> _insertProperty(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _supabase
          .from('properties')
          .insert(payload)
          .select('id')
          .single();
    } on PostgrestException catch (e) {
      if (!_isMissingConditionsColumn(e)) rethrow;
      return _supabase
          .from('properties')
          .insert(_withoutConditions(payload))
          .select('id')
          .single();
    }
  }

  Map<String, dynamic> _withoutConditions(Map<String, dynamic> payload) =>
      Map<String, dynamic>.from(payload)..remove('conditions');

  bool _isMissingConditionsColumn(PostgrestException error) {
    return error.code == 'PGRST204' && error.message.contains("'conditions'");
  }
}
