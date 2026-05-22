import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dari_app/models/property_model.dart';
import 'package:dari_app/repositories/property_repository.dart';

final propertyRepositoryProvider =
    Provider<PropertyRepository>((ref) => PropertyRepository());

// Filter state
class PropertyFilter {
  final String? city;
  final String? type;
  final double? minPrice;
  final double? maxPrice;
  final String? searchQuery;

  const PropertyFilter({
    this.city,
    this.type,
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
  });

  PropertyFilter copyWith({
    String? city,
    String? type,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) =>
      PropertyFilter(
        city: city ?? this.city,
        type: type ?? this.type,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  bool get hasFilters =>
      city != null || type != null || minPrice != null || maxPrice != null;
}

final propertyFilterProvider =
    StateProvider<PropertyFilter>((ref) => const PropertyFilter());

// Keep alive for 5 minutes to avoid re-fetching on tab switch
final propertiesProvider =
    FutureProvider.autoDispose<List<PropertyModel>>((ref) async {
  // Keep the data alive for 5 minutes after the last listener unsubscribes
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());

  final repo = ref.watch(propertyRepositoryProvider);
  final filter = ref.watch(propertyFilterProvider);
  return repo.getPublishedProperties(
    city: filter.city,
    type: filter.type,
    minPrice: filter.minPrice,
    maxPrice: filter.maxPrice,
    searchQuery: filter.searchQuery,
  );
});

final propertyDetailProvider =
    FutureProvider.autoDispose.family<PropertyModel?, int>((ref, id) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());

  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getPropertyById(id);
});

final ownerPropertiesProvider = FutureProvider.autoDispose
    .family<List<PropertyModel>, String>((ref, ownerId) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());

  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getOwnerProperties(ownerId);
});

final favoritesProvider = FutureProvider.autoDispose
    .family<List<PropertyModel>, String>((ref, userId) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 2), () => link.close());

  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getFavorites(userId);
});

final isFavoriteProvider = FutureProvider.autoDispose
    .family<bool, ({String userId, int propertyId})>((ref, params) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.isFavorite(params.userId, params.propertyId);
});
