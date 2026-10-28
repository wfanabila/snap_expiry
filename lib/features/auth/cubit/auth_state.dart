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
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? infoMessage;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;

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
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage:
          clearInfo ? null : (infoMessage ?? this.infoMessage),
      isPasswordVisible:
          isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
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
      ];
}