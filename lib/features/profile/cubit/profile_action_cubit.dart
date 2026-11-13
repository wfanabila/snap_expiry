import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_action_state.dart';

class ProfileActionCubit extends Cubit<ProfileActionState> {
  ProfileActionCubit()
      : super(const ProfileActionState());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void updateName(String value) {
    emit(state.copyWith(
      name: value,
      clearMessages: true,
    ));
  }

  void updateCurrentPassword(String value) {
    emit(state.copyWith(
      currentPassword: value,
      clearMessages: true,
    ));
  }

  void updateNewPassword(String value) {
    emit(state.copyWith(
      newPassword: value,
      clearMessages: true,
    ));
  }

  void updateConfirmPassword(String value) {
    emit(state.copyWith(
      confirmPassword: value,
      clearMessages: true,
    ));
  }

  Future<void> updateProfile() async {
    final name = state.name.trim();
    final user = _auth.currentUser;

    if (user == null) {
      _failure('Please log in again.');
      return;
    }

    if (name.isEmpty) {
      _failure('Name cannot be empty.');
      return;
    }

    try {
      emit(state.copyWith(
        status: ProfileActionStatus.loading,
        clearMessages: true,
      ));

      await user.updateDisplayName(name);
      await user.reload();

      emit(state.copyWith(
        status: ProfileActionStatus.success,
        successMessage: 'Profile updated successfully.',
      ));
    } on FirebaseAuthException catch (e) {
      _failure(_authErrorMessage(e));
    } catch (_) {
      _failure('Unable to update profile. Please try again.');
    }
  }

  Future<void> changePassword() async {
    final user = _auth.currentUser;

    if (user == null) {
      _failure('Please log in again.');
      return;
    }

    if (state.currentPassword.isEmpty ||
        state.newPassword.isEmpty ||
        state.confirmPassword.isEmpty) {
      _failure('Please complete all password fields.');
      return;
    }

    if (state.newPassword.length < 6) {
      _failure('New password must contain at least 6 characters.');
      return;
    }

    if (state.newPassword != state.confirmPassword) {
      _failure('New passwords do not match.');
      return;
    }

    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    if (!hasPasswordProvider) {
      _failure(
        'This account does not use an email and password sign-in.',
      );
      return;
    }

    try {
      emit(state.copyWith(
        status: ProfileActionStatus.loading,
        clearMessages: true,
      ));

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: state.currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(state.newPassword);

      emit(state.copyWith(
        status: ProfileActionStatus.success,
        successMessage: 'Password changed successfully.',
      ));
    } on FirebaseAuthException catch (e) {
      _failure(_authErrorMessage(e));
    } catch (_) {
      _failure('Unable to change password. Please try again.');
    }
  }

  void _failure(String message) {
    emit(state.copyWith(
      status: ProfileActionStatus.failure,
      errorMessage: message,
    ));
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Your current password is incorrect.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'requires-recent-login':
        return 'Please log in again before changing your password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}