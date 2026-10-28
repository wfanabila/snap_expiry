import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

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
      },
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        final isLoading = state.status == AuthStatus.loading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Create account'),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: Form(
                    key: cubit.signupFormKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Join SnapExpiry',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keep track of expiry dates and '
                          'reduce product waste.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                        const SizedBox(height: 28),
                        AppTextField(
                          label: 'Full name',
                          controller: cubit.signupNameController,
                          onChanged: (_) {},
                          prefixIcon: Icons.person_outline,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          validator: cubit.validateName,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Email address',
                          controller: cubit.signupEmailController,
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
                              cubit.signupPasswordController,
                          onChanged: (_) {
                            cubit.signupFormKey.currentState
                                ?.validate();
                          },
                          prefixIcon: Icons.lock_outline,
                          obscureText: !state.isPasswordVisible,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.next,
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
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Confirm password',
                          controller:
                              cubit.signupConfirmPasswordController,
                          onChanged: (_) {},
                          prefixIcon: Icons.lock_reset_outlined,
                          obscureText:
                              !state.isConfirmPasswordVisible,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.done,
                          validator:
                              cubit.validateConfirmPassword,
                          suffixIcon: IconButton(
                            tooltip:
                                state.isConfirmPasswordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                            onPressed: isLoading
                                ? null
                                : cubit
                                    .toggleConfirmPasswordVisibility,
                            icon: Icon(
                              state.isConfirmPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Create account',
                          isLoading: isLoading,
                          onPressed: isLoading
                              ? null
                              : cubit.signUp,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                'Already have an account?',
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(
                                        AppConstants.loginRoute,
                                      ),
                              child: const Text('Log In'),
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