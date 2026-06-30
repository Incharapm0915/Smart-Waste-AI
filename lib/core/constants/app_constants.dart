class AppConstants {
  // Backend URL (Render hosted FastAPI)
  static const String baseUrl = 'https://smart-waste-ai.onrender.com';
  static const String apiVersion = '/api/v1';
  static const String apiBase = '$baseUrl$apiVersion';

  // API Endpoints
  static const String detectEndpoint = '$apiBase/detect';
  static const String ocrEndpoint = '$apiBase/ocr';
  static const String recipesEndpoint = '$apiBase/recipes/generate';
  static const String shoppingEndpoint = '$apiBase/shopping/suggest';
  static const String wasteReportEndpoint = '$apiBase/analytics/waste-report';
  static const String chatEndpoint = '$apiBase/chat';

  // Expiry Thresholds (days)
  static const int dangerThreshold = 2;
  static const int warningThreshold = 5;
  static const int safeThreshold = 14;

  // Local storage keys
  static const String userIdKey = 'user_id';
  static const String onboardingKey = 'onboarding_complete';
  static const String themeKey = 'app_theme';
  static const String notificationsKey = 'notifications_enabled';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String itemsCollection = 'items';
  static const String inventoryCollection = 'inventory';
  static const String usageHistoryCollection = 'usage_history';
  static const String wasteLogsCollection = 'waste_logs';
  static const String recipesCollection = 'saved_recipes';
  static const String shoppingListCollection = 'shopping_lists';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Pagination
  static const int pageSize = 20;

  // Image processing
  static const int maxImageSize = 1024;
  static const double imageQuality = 0.85;

  // Notification IDs
  static const int expiryNotificationId = 1001;
  static const int weeklyReportNotificationId = 1002;
}
