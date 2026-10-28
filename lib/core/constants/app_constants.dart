class AppConstants {
  AppConstants._();

  static const String appName = 'SnapExpiry';
  static const String appVersion = '1.0.0';

  static const int defaultExpiryThresholdDays = 7;

  static const List<int> expiryThresholdOptions = [3, 7, 14];

  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String themeModeKey = 'theme_mode';
  static const String expiryThresholdKey = 'expiry_threshold';

  static const String openFoodFactsBaseUrl =
      'https://world.openfoodfacts.org/api/v2/product';

  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String addProductRoute = '/add-product';
  static const String productDetailsRoute = '/product/:id';
  static const String profileRoute = '/profile';
}