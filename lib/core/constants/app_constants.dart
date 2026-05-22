class AppConstants {
  // App info
  static const String appName = 'Dari.tn';
  static const String appVersion = '1.0.0';

  // Roles
  static const String roleTenant = 'tenant';
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';

  // Property types
  static const List<String> propertyTypes = [
    'Maison', 'Appartement', 'Studio', 'Chambre', 'Villa', 'Duplex'
  ];

  // Price types
  static const String pricePerDay = 'day';
  static const String pricePerWeek = 'week';
  static const String pricePerMonth = 'month';

  // Booking statuses
  static const String bookingPending = 'pending';
  static const String bookingAccepted = 'accepted';
  static const String bookingRefused = 'refused';
  static const String bookingCancelled = 'cancelled';
  static const String bookingCompleted = 'completed';

  // Payment statuses
  static const String paymentUnpaid = 'unpaid';
  static const String paymentPaid = 'paid';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';

  // Property statuses
  static const String propertyPending = 'pending';
  static const String propertyPublished = 'published';
  static const String propertyRefused = 'refused';
  static const String propertyDeleted = 'deleted';

  // Sponsor plans
  static const List<Map<String, dynamic>> sponsorPlans = [
    {
      'name': 'Basic Boost',
      'duration': 3,
      'price': 15.0,
      'description': "L'annonce apparaît au-dessus des annonces normales",
      'color': 0xFF64748B,
    },
    {
      'name': 'Premium Boost',
      'duration': 7,
      'price': 35.0,
      'description': "Première position + badge premium",
      'color': 0xFF2563EB,
    },
    {
      'name': 'Pro Boost',
      'duration': 30,
      'price': 99.0,
      'description': "Position top + statistiques détaillées",
      'color': 0xFFF59E0B,
    },
  ];

  // Tunisian cities
  static const List<String> tunisianCities = [
    'Tunis', 'Sfax', 'Sousse', 'Monastir', 'Bizerte',
    'Gabès', 'Ariana', 'Gafsa', 'Nabeul', 'Ben Arous',
    'Kairouan', 'Hammamet', 'Djerba', 'La Marsa', 'Carthage',
    'La Goulette', 'Mahdia', 'Zarzis', 'Tabarka', 'Tozeur',
  ];

  // Secure storage keys
  static const String sessionKey = 'dari_session';
  static const String userIdKey = 'dari_user_id';
  static const String userRoleKey = 'dari_user_role';

  // Currency
  static const String currency = 'TND';
}
