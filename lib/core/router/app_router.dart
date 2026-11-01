import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/onboarding_view.dart';
import '../../features/auth/presentation/login_view.dart';
import '../../features/auth/presentation/signup_view.dart';
import '../../features/products/presentation/home_view.dart';
import '../../features/products/presentation/add_product_view.dart';
import '../../features/products/presentation/product_details_view.dart';
import '../../features/profile/presentation/profile_view.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupView(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: '/add-product',
        builder: (context, state) => const AddProductView(),
      ),

      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;

          return ProductDetailsView(productId: productId);
        },
      ),
    ],
  );
}
