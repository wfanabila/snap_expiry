import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app_exceptions.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> with WidgetsBindingObserver {
  AuthCubit(this._repository) : super(const AuthState()) {
    WidgetsBinding.instance.addObserver(this);

    _authSubscription = _repository.authStateChanges.listen(
      _handleAuthChange,
      onError: (_) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: AuthStatus.failure,
              isCheckingBiometricLock: false,
              errorMessage: 'Unable to verify your session.',
            ),
          );
        }
      },
    );
  }

  final AuthRepository _repository;
  final LocalAuthentication _localAuth = LocalAuthentication();

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

  bool _isAuthenticating = false;

  User? get currentUser => _repository.currentUser;

  String _preferenceKey(String uid) => 'biometric_lock_enabled_$uid';

  Future<void> _handleAuthChange(User? user) async {
    if (isClosed) return;

    if (user == null) {
      emit(
        state.copyWith(
          status: AuthStatus.initial,
          clearUser: true,
          clearError: true,
          clearInfo: true,
          isCheckingBiometricLock: false,
          isBiometricLockEnabled: false,
          isAppLocked: false,
          isBiometricAuthenticating: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        user: user,
        isCheckingBiometricLock: true,
        clearError: true,
      ),
    );

    try {
      final preferences = await SharedPreferences.getInstance();
      final enabled =
          preferences.getBool(_preferenceKey(user.uid)) ?? false;

      if (isClosed) return;

      emit(
        state.copyWith(
          status: AuthStatus.success,
          user: user,
          isCheckingBiometricLock: false,
          isBiometricLockEnabled: enabled,
          isAppLocked: enabled,
          clearError: true,
        ),
      );
    } catch (_) {
      if (isClosed) return;

      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isCheckingBiometricLock: false,
          errorMessage: 'Unable to load your app security settings.',
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (isClosed || _isAuthenticating) return;

    if (lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.paused) {
      if (state.isAuthenticated && state.isBiometricLockEnabled) {
        emit(state.copyWith(isAppLocked: true));
      }
    }
  }

  Future<bool> enableBiometricLock() async {
    final user = currentUser;

    if (user == null) return false;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;

      if (!canCheck) {
        _setBiometricError(
          'Biometric authentication is not available on this device.',
        );
        return false;
      }

      final authenticated = await _authenticateBiometrically(
        reason: 'Verify your identity to enable SnapExpiry app lock.',
      );

      if (!authenticated) {
        _setBiometricError(
          'Biometric verification was cancelled or unsuccessful.',
        );
        return false;
      }

      final preferences = await SharedPreferences.getInstance();

      await preferences.setBool(
        _preferenceKey(user.uid),
        true,
      );

      if (isClosed) return false;

      emit(
        state.copyWith(
          isBiometricLockEnabled: true,
          isAppLocked: false,
          clearError: true,
          infoMessage: 'Biometric app lock has been enabled.',
        ),
      );

      return true;
    } catch (_) {
      _setBiometricError(
        'Could not enable biometric app lock. Please try again.',
      );
      return false;
    }
  }

  Future<bool> disableBiometricLock() async {
    final user = currentUser;

    if (user == null) return false;

    try {
      final authenticated = await _authenticateBiometrically(
        reason: 'Verify your identity to disable SnapExpiry app lock.',
      );

      if (!authenticated) {
        _setBiometricError(
          'Biometric verification is required to disable app lock.',
        );
        return false;
      }

      final preferences = await SharedPreferences.getInstance();

      await preferences.setBool(
        _preferenceKey(user.uid),
        false,
      );

      if (isClosed) return false;

      emit(
        state.copyWith(
          isBiometricLockEnabled: false,
          isAppLocked: false,
          clearError: true,
          infoMessage: 'Biometric app lock has been disabled.',
        ),
      );

      return true;
    } catch (_) {
      _setBiometricError(
        'Could not disable biometric app lock. Please try again.',
      );
      return false;
    }
  }

  Future<void> authenticateToUnlock() async {
    if (!state.isAppLocked || _isAuthenticating) return;

    final authenticated = await _authenticateBiometrically(
      reason: 'Authenticate to access your SnapExpiry account.',
    );

    if (isClosed) return;

    if (authenticated) {
      emit(
        state.copyWith(
          isAppLocked: false,
          clearError: true,
          infoMessage: 'App unlocked successfully.',
        ),
      );
    } else {
      _setBiometricError(
        'Authentication was not successful. Please try again.',
      );
    }
  }

  Future<bool> _authenticateBiometrically({
    required String reason,
  }) async {
    if (_isAuthenticating) return false;

    _isAuthenticating = true;

    if (!isClosed) {
      emit(state.copyWith(isBiometricAuthenticating: true));
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    } finally {
      _isAuthenticating = false;

      if (!isClosed) {
        emit(
          state.copyWith(isBiometricAuthenticating: false),
        );
      }
    }
  }

  void _setBiometricError(String message) {
    if (isClosed) return;

    emit(
      state.copyWith(
        errorMessage: message,
        clearInfo: true,
      ),
    );
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

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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

    final valid = signupFormKey.currentState?.validate() ?? false;
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

    final valid = loginFormKey.currentState?.validate() ?? false;
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

  Future<void> signInWithGoogle() async {
    if (state.status == AuthStatus.loading) return;

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await _repository.signInWithGoogle();

      if (isClosed) return;

      emit(
        state.copyWith(
          status: AuthStatus.success,
          user: _repository.currentUser,
          clearError: true,
          infoMessage: 'You are now signed in with Google.',
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
      await _repository.sendPasswordResetEmail(email: email);

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
          isBiometricLockEnabled: false,
          isAppLocked: false,
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
    WidgetsBinding.instance.removeObserver(this);

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