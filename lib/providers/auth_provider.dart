import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dari_app/models/user_model.dart';
import 'package:dari_app/repositories/auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<UserModel?> {
  late final AuthRepository _repo;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  Future<UserModel?> build() async {
    _repo = ref.read(authRepositoryProvider);

    // Listen to Supabase auth state changes
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      try {
        final session = data.session;
        if (session == null) {
          state = const AsyncData(null);
        } else {
          final user = await _repo.getUserById(session.user.id);
          state = AsyncData(user);
        }
      } catch (_) {
        state = const AsyncData(null);
      }
    });
    ref.onDispose(() => _authSubscription?.cancel());

    return await _restoreSession();
  }

  Future<UserModel?> _restoreSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return null;
      return await _repo.getUserById(session.user.id);
    } catch (_) {
      return null;
    }
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.login(email, password);
      if (user == null) {
        state = const AsyncData(null);
        return 'Email ou mot de passe incorrect ou compte inactif';
      }
      state = AsyncData(user);
      return null;
    } catch (e) {
      state = const AsyncData(null);
      if (e is AuthException) {
        return 'Email ou mot de passe incorrect';
      }
      return 'Erreur de connexion: $e';
    }
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      if (user == null) {
        state = const AsyncData(null);
        return 'Compte créé, mais profil introuvable. Vérifiez la confirmation email ou la table users.';
      }
      state = AsyncData(user);
      return null;
    } catch (e) {
      state = const AsyncData(null);
      return 'Erreur d\'inscription: $e';
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    // state is updated automatically via onAuthStateChange
  }

  Future<bool> updateProfile(UserModel user) async {
    final success = await _repo.updateUser(user);
    if (success) state = AsyncData(user);
    return success;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    // Note: oldPassword is not needed for Supabase if the user is already authenticated
    return await _repo.changePassword(newPassword);
  }
}

// Convenience provider for current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value;
});
