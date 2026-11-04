import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  initial,
  loading,
  success,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.infoMessage,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.isCheckingBiometricLock = true,
    this.isBiometricLockEnabled = false,
    this.isAppLocked = false,
    this.isBiometricAuthenticating = false,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? infoMessage;

  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;

  final bool isCheckingBiometricLock;
  final bool isBiometricLockEnabled;
  final bool isAppLocked;
  final bool isBiometricAuthenticating;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    bool? isCheckingBiometricLock,
    bool? isBiometricLockEnabled,
    bool? isAppLocked,
    bool? isBiometricAuthenticating,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      isPasswordVisible:
          isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      isCheckingBiometricLock:
          isCheckingBiometricLock ?? this.isCheckingBiometricLock,
      isBiometricLockEnabled:
          isBiometricLockEnabled ?? this.isBiometricLockEnabled,
      isAppLocked: isAppLocked ?? this.isAppLocked,
      isBiometricAuthenticating:
          isBiometricAuthenticating ?? this.isBiometricAuthenticating,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user?.uid,
        errorMessage,
        infoMessage,
        isPasswordVisible,
        isConfirmPasswordVisible,
        isCheckingBiometricLock,
        isBiometricLockEnabled,
        isAppLocked,
        isBiometricAuthenticating,
      ];
}