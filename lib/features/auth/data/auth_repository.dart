import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/app_exceptions.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.updateDisplayName(name.trim());

      await credential.user?.reload();

      return credential;
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _messageFor(error),
        code: error.code,
      );
    } catch (_) {
      throw const AppException(
        'We could not create your account. Please try again.',
      );
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _messageFor(error),
        code: error.code,
      );
    } catch (_) {
      throw const AppException(
        'We could not sign you in. Please try again.',
      );
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _messageFor(error),
        code: error.code,
      );
    } catch (_) {
      throw const AppException(
        'We could not send the reset email. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _messageFor(error),
        code: error.code,
      );
    } catch (_) {
      throw const AppException(
        'We could not sign you out. Please try again.',
      );
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AppException(
        'Please log in before updating your profile.',
      );
    }

    try {
      await user.updateDisplayName(name.trim());
      await user.reload();
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _messageFor(error),
        code: error.code,
      );
    } catch (_) {
      throw const AppException(
        'We could not update your name. Please try again.',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      throw const AppException(
        'Please log in before changing your password.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw AppException(
        _messageFor(error),
        code: error.code,
      );
    } catch (_) {
      throw const AppException(
        'We could not change your password. Please try again.',
      );
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'email-already-in-use':
        return 'An account already exists for this email.';

      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';

      case 'user-disabled':
        return 'This account has been disabled. Contact support.';

      case 'too-many-requests':
        return 'Too many attempts. Please wait before trying again.';

      case 'network-request-failed':
        return 'Connection failed. Check your internet connection.';

      case 'requires-recent-login':
        return 'Please log in again before performing this action.';

      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled in Firebase.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}