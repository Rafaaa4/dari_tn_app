import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dari_app/models/user_model.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  Future<UserModel?> login(String email, String password) async {
    final response = await _supabase.auth
        .signInWithPassword(email: email, password: password);
    if (response.user == null) return null;
    return getUserById(response.user!.id);
  }

  Future<UserModel?> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role, 'phone': phone},
    );
    if (response.user == null) return null;

    final authUser = response.user!;
    final profile = UserModel(
      id: authUser.id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _ensureUserProfile(profile);

    for (var attempt = 0; attempt < 5; attempt++) {
      final user = await getUserById(authUser.id);
      if (user != null) return user;
      await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }

    return profile;
  }

  Future<void> _ensureUserProfile(UserModel user) async {
    try {
      await _supabase.from('users').upsert({
        'id': user.id,
        'full_name': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'role': user.role,
        'status': user.status,
      }, onConflict: 'id');
    } catch (_) {
      // The Supabase trigger may already create this row. If RLS blocks this
      // client-side fallback, registration can still continue with metadata.
    }
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      final data = await _supabase.from('users').select().eq('id', id).single();
      return UserModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      await _supabase.from('users').update(user.toMap()).eq('id', user.id!);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    final data = await _supabase
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return data.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<bool> toggleUserStatus(String userId, String status) async {
    try {
      await _supabase.from('users').update({'status': status}).eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
