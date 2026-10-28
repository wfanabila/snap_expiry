import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
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

        if (state.infoMessage != null &&
            state.user == null) {
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
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 72,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
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
                          'Sign in to manage your product expiry dates.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        AppTextField(
                          label: 'Email address',
                          controller: cubit.loginEmailController,
                          onChanged: (_) {},
                          prefixIcon: Icons.email_outlined,
                          keyboardType:
                              TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          validator: cubit.validateEmail,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Password',
                          controller:
                              cubit.loginPasswordController,
                          onChanged: (_) {},
                          prefixIcon: Icons.lock_outline,
                          obscureText: !state.isPasswordVisible,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.done,
                          validator: cubit.validatePassword,
                          suffixIcon: IconButton(
                            tooltip: state.isPasswordVisible
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: isLoading
                                ? null
                                : cubit.togglePasswordVisibility,
                            icon: Icon(
                              state.isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => _showForgotPasswordDialog(
                                      context,
                                    ),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Log In',
                          isLoading: isLoading,
                          onPressed: isLoading
                              ? null
                              : cubit.signIn,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                "Don't have an account?",
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(
                                        AppConstants.signupRoute,
                                      ),
                              child: const Text('Sign Up'),
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

  void _showForgotPasswordDialog(BuildContext context) {
    final cubit = context.read<AuthCubit>();

    cubit.forgotEmailController.text =
        cubit.loginEmailController.text;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading =
                state.status == AuthStatus.loading;

            return AlertDialog(
              title: const Text('Reset password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your email address to receive '
                    'password reset instructions.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cubit.forgotEmailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .error,
                      ),
                    ),
                  ],
                  if (state.infoMessage != null &&
                      state.user == null) ...[
                    const SizedBox(height: 12),
                    Text(state.infoMessage!),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          await cubit.sendPasswordResetEmail();

                          if (!dialogContext.mounted) return;

                          if (cubit.state.status ==
                                  AuthStatus.success &&
                              cubit.state.infoMessage != null) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Send email'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}