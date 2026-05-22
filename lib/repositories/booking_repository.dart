import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dari_app/models/booking_model.dart';

class BookingRepository {
  final _supabase = Supabase.instance.client;

  Future<int> createBooking(BookingModel booking) async {
    final data = await _supabase
        .from('bookings')
        .insert(booking.toMap())
        .select('id')
        .single();
    return data['id'] as int;
  }

  Future<List<BookingModel>> getTenantBookings(String tenantId) async {
    final data = await _supabase
        .from('bookings')
        .select(
            '*, properties(title, city), users!bookings_owner_id_fkey(full_name)')
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);
    return data.map((e) => _bookingFromJoinedMap(e)).toList();
  }

  Future<List<BookingModel>> getOwnerBookings(String ownerId) async {
    final data = await _supabase
        .from('bookings')
        .select(
            '*, properties(title, city), users!bookings_tenant_id_fkey(full_name)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return data.map((e) => _bookingFromJoinedMap(e)).toList();
  }

  Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': status}).eq('id', bookingId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> payBooking(int bookingId) async {
    try {
      await _supabase.from('bookings').update(
          {'payment_status': 'paid', 'status': 'accepted'}).eq('id', bookingId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasConfirmedBooking(String tenantId, int propertyId) async {
    final results = await _supabase
        .from('bookings')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('property_id', propertyId)
        .eq('status', 'accepted')
        .limit(1);
    return results.isNotEmpty;
  }

  Future<List<BookingModel>> getAllBookings() async {
    final data = await _supabase
        .from('bookings')
        .select(
            '*, properties(title, city), tenant:users!bookings_tenant_id_fkey(full_name), owner:users!bookings_owner_id_fkey(full_name)')
        .order('created_at', ascending: false);
    return data.map((e) => _bookingFromJoinedMap(e)).toList();
  }

  BookingModel _bookingFromJoinedMap(Map<String, dynamic> data) {
    final map = Map<String, dynamic>.from(data);
    final property = map['properties'];
    if (property is Map<String, dynamic>) {
      map['property_title'] = property['title'];
      map['property_city'] = property['city'];
    }

    final users = map['users'];
    if (users is Map<String, dynamic>) {
      map['tenant_name'] ??= users['full_name'];
      map['owner_name'] ??= users['full_name'];
    }

    final tenant = map['tenant'];
    if (tenant is Map<String, dynamic>) {
      map['tenant_name'] = tenant['full_name'];
    }

    final owner = map['owner'];
    if (owner is Map<String, dynamic>) {
      map['owner_name'] = owner['full_name'];
    }

    return BookingModel.fromMap(map);
  }
}

class SponsorRepository {
  final _supabase = Supabase.instance.client;

  Future<int> createSponsor(SponsoredAdModel sponsor) async {
    final data = await _supabase
        .from('sponsored_ads')
        .insert(sponsor.toMap())
        .select('id')
        .single();

    await _supabase
        .from('properties')
        .update({'is_sponsored': true})
        .eq('id', sponsor.propertyId)
        .eq('owner_id', sponsor.ownerId);

    return data['id'] as int;
  }

  Future<List<SponsoredAdModel>> getOwnerSponsors(String ownerId) async {
    final results = await _supabase
        .from('sponsored_ads')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return results.map(SponsoredAdModel.fromMap).toList();
  }

  Future<SponsoredAdModel?> getActiveSponsor(int propertyId) async {
    final results = await _supabase
        .from('sponsored_ads')
        .select()
        .eq('property_id', propertyId)
        .eq('status', 'active')
        .gt('end_date', DateTime.now().toIso8601String())
        .order('end_date', ascending: false)
        .limit(1);
    if (results.isEmpty) return null;
    return SponsoredAdModel.fromMap(results.first);
  }

  Future<List<SponsoredAdModel>> getAllSponsors() async {
    final results = await _supabase
        .from('sponsored_ads')
        .select()
        .order('created_at', ascending: false);
    return results.map(SponsoredAdModel.fromMap).toList();
  }
}

class SponsoredAdModel {
  final int? id;
  final int propertyId;
  final String ownerId;
  final String planName;
  final double price;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;

  const SponsoredAdModel({
    this.id,
    required this.propertyId,
    required this.ownerId,
    required this.planName,
    required this.price,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    required this.createdAt,
  });

  factory SponsoredAdModel.fromMap(Map<String, dynamic> map) =>
      SponsoredAdModel(
        id: map['id'],
        propertyId: map['property_id'],
        ownerId: map['owner_id'],
        planName: map['plan_name'],
        price: (map['price'] as num).toDouble(),
        startDate: map['start_date'],
        endDate: map['end_date'],
        status: map['status'] ?? 'active',
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'property_id': propertyId,
        'owner_id': ownerId,
        'plan_name': planName,
        'price': price,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
        'created_at': createdAt,
      };
}
