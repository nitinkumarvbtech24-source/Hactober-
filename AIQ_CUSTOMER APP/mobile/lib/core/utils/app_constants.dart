class AppConstants {
  // API
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:3000', // Changed to 127.0.0.1
  );
  static const String apiUrl = '$baseUrl/api';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Waste Types
  static const List<Map<String, String>> wasteTypes = [
    {'value': 'general', 'label': 'General Waste', 'emoji': '🗑️'},
    {'value': 'recyclable', 'label': 'Recyclable', 'emoji': '♻️'},
    {'value': 'organic', 'label': 'Organic / Food', 'emoji': '🌱'},
    {'value': 'electronic', 'label': 'E-Waste', 'emoji': '📱'},
    {'value': 'hazardous', 'label': 'Hazardous', 'emoji': '⚠️'},
  ];

  // Quantities
  static const List<Map<String, dynamic>> quantities = [
    {'value': 'small', 'label': 'Small (1–2 bags)', 'price': 49},
    {'value': 'medium', 'label': 'Medium (3–5 bags)', 'price': 74},
    {'value': 'large', 'label': 'Large (6–10 bags)', 'price': 99},
    {'value': 'bulk', 'label': 'Bulk (10+ bags)', 'price': 149},
  ];

  // Quick address suggestions (demo)
  static const List<Map<String, dynamic>> mockAddresses = [
    {
      'label': '123 MG Road, Bengaluru, Karnataka 560001',
      'lat': 12.9716,
      'lng': 77.5946,
    },
    {
      'label': '456 Anna Salai, Chennai, Tamil Nadu 600002',
      'lat': 13.0827,
      'lng': 80.2707,
    },
    {
      'label': '789 Banjara Hills, Hyderabad, Telangana 500034',
      'lat': 17.3850,
      'lng': 78.4867,
    },
    {
      'label': '321 Koregaon Park, Pune, Maharashtra 411001',
      'lat': 18.5362,
      'lng': 73.8936,
    },
  ];
}
