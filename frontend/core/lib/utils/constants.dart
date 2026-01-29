/// Application constants
class AppConstants {
  // App Information
  static const String appName = 'School Management System';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String apiBaseUrl = 'https://api.example.com/v1';
  static const int apiTimeoutSeconds = 30;

  // Storage Keys
  static const String storageAuthToken = 'auth_token';
  static const String storageUserData = 'user_data';
  static const String storageUserRole = 'user_role';
  static const String storageThemeMode = 'theme_mode';
  static const String storageLanguage = 'language';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleManagement = 'management';
  static const String roleTeacher = 'teacher';
  static const String roleParent = 'parent';

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayDateTimeFormat = 'MMM dd, yyyy HH:mm';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 255;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxFileSizeMB = 10;
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];
  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];

  // Colors (if needed for consistency)
  static const int primaryColorValue = 0xFF667EEA;
  static const int secondaryColorValue = 0xFF764BA2;
  static const int errorColorValue = 0xFFE53E3E;
  static const int successColorValue = 0xFF38A169;
  static const int warningColorValue = 0xFFD69E2E;
}

