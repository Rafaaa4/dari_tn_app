import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/screens/auth/splash_screen.dart';
import 'package:dari_app/screens/auth/onboarding_screen.dart';
import 'package:dari_app/screens/auth/login_screen.dart';
import 'package:dari_app/screens/auth/register_screen.dart';
import 'package:dari_app/screens/home/main_shell.dart';
import 'package:dari_app/screens/home/home_screen.dart';
import 'package:dari_app/screens/property/property_detail_screen.dart';
import 'package:dari_app/screens/property/add_property_screen.dart';
import 'package:dari_app/screens/owner/owner_dashboard_screen.dart';
import 'package:dari_app/screens/owner/sponsor_screen.dart';
import 'package:dari_app/screens/booking/booking_screen.dart';
import 'package:dari_app/screens/booking/my_bookings_screen.dart';
import 'package:dari_app/screens/profile/profile_screen.dart';
import 'package:dari_app/screens/admin/admin_dashboard_screen.dart';
import 'package:dari_app/screens/home/favorites_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier(0);
  ref.listen(authStateProvider, (_, __) {
    refreshNotifier.value++;
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;
      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.adminLogin ||
          location == AppRoutes.register;
      final isAdminRoute = location == AppRoutes.admin;

      if (isLoading) {
        if (isSplash || isAuthRoute) return null;
        return AppRoutes.splash;
      }
      if (!isLoggedIn) {
        if (isSplash) return AppRoutes.onboarding;
        if (isAdminRoute) return AppRoutes.adminLogin;
        if (!isAuthRoute && !isOnboarding) return AppRoutes.login;
        return null;
      }
      if (isAdminRoute && !user.isAdmin) return AppRoutes.home;
      if (location == AppRoutes.adminLogin) {
        return user.isAdmin ? AppRoutes.admin : AppRoutes.home;
      }
      if (isSplash || isOnboarding || isAuthRoute) {
        return user.isAdmin ? AppRoutes.admin : AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (_, __) => const LoginScreen(
          adminMode: true,
          showRegisterLink: false,
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: AppRoutes.favorites,
              builder: (_, __) => const FavoritesScreen()),
          GoRoute(
              path: AppRoutes.myBookings,
              builder: (_, __) => const MyBookingsScreen()),
          GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/property/:id',
        builder: (_, state) => PropertyDetailScreen(
          propertyId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
          path: AppRoutes.addProperty,
          builder: (_, __) => const AddPropertyScreen()),
      GoRoute(
        path: '/edit-property/:id',
        builder: (_, state) => AddPropertyScreen(
          propertyId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
          path: AppRoutes.ownerDashboard,
          builder: (_, __) => const OwnerDashboardScreen()),
      GoRoute(
        path: '/sponsor/:propertyId',
        builder: (_, state) => SponsorScreen(
          propertyId: int.parse(state.pathParameters['propertyId']!),
        ),
      ),
      GoRoute(
        path: '/booking/:propertyId',
        builder: (_, state) => BookingScreen(
          propertyId: int.parse(state.pathParameters['propertyId']!),
        ),
      ),
      GoRoute(
          path: AppRoutes.admin,
          builder: (_, __) => const AdminDashboardScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page introuvable: ${state.error}')),
    ),
  );
});
