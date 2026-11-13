import 'package:equatable/equatable.dart';

enum ProfileActionStatus {
  initial,
  loading,
  success,
  failure,
}

class ProfileActionState extends Equatable {
  final ProfileActionStatus status;
  final String name;
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final String? errorMessage;
  final String? successMessage;

  const ProfileActionState({
    this.status = ProfileActionStatus.initial,
    this.name = '',
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.errorMessage,
    this.successMessage,
  });

  ProfileActionState copyWith({
    ProfileActionStatus? status,
    String? name,
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProfileActionState(
      status: status ?? this.status,
      name: name ?? this.name,
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      errorMessage:
          clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearMessages ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        name,
        currentPassword,
        newPassword,
        confirmPassword,
        errorMessage,
        successMessage,
      ];
}