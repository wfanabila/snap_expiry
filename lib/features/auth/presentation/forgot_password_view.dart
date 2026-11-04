
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';

// ==========================================
// FORGOT PASSWORD STATE
// ==========================================

enum ForgotPasswordStatus {
  initial,
  loading,
  success,
  failure,
}

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStatus status;
  final String email;
  final String? errorMessage;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.email = '',
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? email,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, email, errorMessage];
}

// ==========================================
// FORGOT PASSWORD CUBIT
// ==========================================

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(const ForgotPasswordState());

  void emailChanged(String email) {
    emit(state.copyWith(
      email: email.trim(),
      status: ForgotPasswordStatus.initial,
      clearError: true,
    ));
  }

  Future<void> sendResetLink() async {
    final email = state.email.trim();

    if (email.isEmpty) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: 'Please enter your email address.',
      ));
      return;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: 'Please enter a valid email address.',
      ));
      return;
    }

    emit(state.copyWith(
      status: ForgotPasswordStatus.loading,
      clearError: true,
    ));

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      emit(state.copyWith(
        status: ForgotPasswordStatus.success,
        clearError: true,
      ));
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Please check your internet connection.';
          break;
        default:
          message = 'Unable to send the reset email. Please try again.';
      }

      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }
}

// ==========================================
// FORGOT PASSWORD VIEW
// ==========================================

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  static const Color backgroundColor = Color(0xFFF4F6EF);
  static const Color primaryColor = Color(0xFF4B7655);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordCubit(),
      child: const _ForgotPasswordContent(),
    );
  }
}

class _ForgotPasswordContent extends StatelessWidget {
  const _ForgotPasswordContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgotPasswordView.backgroundColor,
      appBar: AppBar(
        backgroundColor: ForgotPasswordView.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 35,
          ),
          child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
            listener: (context, state) {
              if (state.status == ForgotPasswordStatus.failure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        state.errorMessage ?? 'Something went wrong.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            builder: (context, state) {
              final cubit = context.read<ForgotPasswordCubit>();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 35),

                  // Email icon
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EBDD),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 65,
                      color: ForgotPasswordView.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    'Forgot Password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    state.status == ForgotPasswordStatus.success
                        ? 'If an account is registered with this email, '
                            'you will receive a password reset link. '
                            'Please check your inbox.'
                        : 'Don’t worry! Enter your registered email address '
                            'and we will send you a link to reset your password.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (state.status != ForgotPasswordStatus.success) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      initialValue: state.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onChanged: cubit.emailChanged,
                      onFieldSubmitted: (_) => cubit.sendResetLink(),
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: ForgotPasswordView.primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed:
                            state.status == ForgotPasswordStatus.loading
                                ? null
                                : cubit.sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              ForgotPasswordView.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: state.status ==
                                ForgotPasswordStatus.loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.mark_email_read_outlined,
                      size: 65,
                      color: ForgotPasswordView.primaryColor,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              ForgotPasswordView.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  if (state.status != ForgotPasswordStatus.success)
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: ForgotPasswordView.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
