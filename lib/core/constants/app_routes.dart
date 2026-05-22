class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/auth/login';
  static const adminLogin = '/admin-login';
  static const register = '/auth/register';
  static const home = '/home';
  static const favorites = '/favorites';
  static const myBookings = '/my-bookings';
  static const profile = '/profile';
  static const addProperty = '/add-property';
  static const ownerDashboard = '/owner-dashboard';
  static const admin = '/admin';

  static String property(int id) => '/property/$id';
  static String editProperty(int id) => '/edit-property/$id';
  static String sponsor(int propertyId) => '/sponsor/$propertyId';
  static String booking(int propertyId) => '/booking/$propertyId';
}
