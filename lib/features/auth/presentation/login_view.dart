import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        // Navigate after successful authentication.
        if (state.status == AuthStatus.success &&
            state.user != null &&
            !state.isAppLocked) {
          context.go(AppConstants.homeRoute);
          return;
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }

        if (state.infoMessage != null && state.user == null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.infoMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        final isLoading = state.status == AuthStatus.loading;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F0),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: Form(
                    key: cubit.loginFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 72,
                          color: const Color(0xFF2E7D5B),
                          semanticLabel: 'SnapExpiry logo',
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Welcome back!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Log in to track freshness and save on household groceries.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 32),

                        // Email field
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDFFF3),
                              border: Border.all(
                                color: const Color(0xFF2E7D5B),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(
                                    93,
                                    93,
                                    93,
                                    0.251,
                                  ),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextFormField(
                                controller: cubit.loginEmailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !isLoading,
                                validator: cubit.validateEmail,
                                decoration: const InputDecoration(
                                  hintText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Password field
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDFFF3),
                              border: Border.all(
                                color: const Color(0xFF2E7D5B),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(
                                    93,
                                    93,
                                    93,
                                    0.251,
                                  ),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TextFormField(
                                controller: cubit.loginPasswordController,
                                obscureText: !state.isPasswordVisible,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                enabled: !isLoading,
                                validator: cubit.validatePassword,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed:
                                        cubit.togglePasswordVisibility,
                                    icon: Icon(
                                      state.isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    context.push('/forgot-password');
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerRight,
                              foregroundColor: const Color(0xFF0052DD),
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Email login button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : cubit.signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D5B),
                              foregroundColor: Colors.white,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // OR divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Google sign-in button
                        ElevatedButton(
                          onPressed: isLoading
                                ? null
                                : () => cubit.signInWithGoogle(), // FIX 2: Updated function name
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8E8E8),
                            foregroundColor: const Color(0xFF4B4B4B),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: BorderSide(color: Colors.grey.shade300), 
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/google.png',
                                height: 24,
                                width: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text("Continue with Google", style: TextStyle(fontSize: 16),),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Sign up navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                "Don't have an account?",
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0052DD),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(
                                        AppConstants.signupRoute,
                                      ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
