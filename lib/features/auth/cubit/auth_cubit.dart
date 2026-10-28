import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/app_exceptions.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState()) {
    _authSubscription = _repository.authStateChanges.listen(
      _handleAuthChange,
      onError: (_) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: AuthStatus.failure,
              errorMessage: 'Unable to verify your session.',
            ),
          );
        }
      },
    );
  }

  final AuthRepository _repository;

  StreamSubscription<User?>? _authSubscription;

  final loginFormKey = GlobalKey<FormState>();
  final signupFormKey = GlobalKey<FormState>();

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final signupNameController = TextEditingController();
  final signupEmailController = TextEditingController();
  final signupPasswordController = TextEditingController();
  final signupConfirmPasswordController = TextEditingController();

  final forgotEmailController = TextEditingController();

  User? get currentUser => _repository.currentUser;

  void _handleAuthChange(User? user) {
    if (isClosed) return;

    if (user != null) {
      emit(
        state.copyWith(
          status: AuthStatus.success,
          user: user,
          clearError: true,
          clearInfo: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.initial,
          clearUser: true,
          clearError: true,
          clearInfo: true,
        ),
      );
    }
  }

  void togglePasswordVisibility() {
    emit(
      state.copyWith(
        isPasswordVisible: !state.isPasswordVisible,
      ),
    );
  }

  void toggleConfirmPasswordVisibility() {
    emit(
      state.copyWith(
        isConfirmPasswordVisible:
            !state.isConfirmPasswordVisible,
      ),
    );
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name.';
    }

    if (value.trim().length < 2) {
      return 'Your name must contain at least 2 characters.';
    }

    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }

    final emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }

    if (value.length < 6) {
      return 'Use at least 6 characters.';
    }

    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != signupPasswordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  Future<void> signUp() async {
    if (state.status == AuthStatus.loading) return;

    final valid =
        signupFormKey.currentState?.validate() ?? false;

    if (!valid) return;

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await _repository.signUp(
        name: signupNameController.text,
        email: signupEmailController.text,
        password: signupPasswordController.text,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          status: AuthStatus.success,
          user: _repository.currentUser,
          infoMessage: 'Your account has been created successfully.',
          clearError: true,
        ),
      );
    } catch (error) {
      _emitFailure(error);
    }
  }

  Future<void> signIn() async {
    if (state.status == AuthStatus.loading) return;

    final valid =
        loginFormKey.currentState?.validate() ?? false;

    if (!valid) return;

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await _repository.signIn(
        email: loginEmailController.text,
        password: loginPasswordController.text,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          status: AuthStatus.success,
          user: _repository.currentUser,
          clearError: true,
          infoMessage: 'You are now signed in.',
        ),
      );
    } catch (error) {
      _emitFailure(error);
    }
  }

  Future<void> sendPasswordResetEmail() async {
    if (state.status == AuthStatus.loading) return;

    final email = forgotEmailController.text.trim();
    final validation = validateEmail(email);

    if (validation != null) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: validation,
          clearInfo: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await _repository.sendPasswordResetEmail(
        email: email,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          status: AuthStatus.success,
          infoMessage:
              'If an account exists for this email, '
              'you will receive password reset instructions.',
          clearError: true,
        ),
      );
    } catch (error) {
      _emitFailure(error);
    }
  }

  Future<void> signOut() async {
    if (state.status == AuthStatus.loading) return;

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await _repository.signOut();

      if (isClosed) return;

      emit(
        state.copyWith(
          status: AuthStatus.initial,
          clearUser: true,
          clearError: true,
          infoMessage: 'You have been signed out.',
        ),
      );
    } catch (error) {
      _emitFailure(error);
    }
  }

  void _emitFailure(Object error) {
    if (isClosed) return;

    final message = error is AppException
        ? error.message
        : 'Something went wrong. Please try again.';

    emit(
      state.copyWith(
        status: AuthStatus.failure,
        errorMessage: message,
        clearInfo: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();

    loginEmailController.dispose();
    loginPasswordController.dispose();

    signupNameController.dispose();
    signupEmailController.dispose();
    signupPasswordController.dispose();
    signupConfirmPasswordController.dispose();

    forgotEmailController.dispose();

    await super.close();
  }
}