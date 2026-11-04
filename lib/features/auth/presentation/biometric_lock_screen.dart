import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class BiometricLockScreen extends StatelessWidget {
  const BiometricLockScreen({super.key});

  static const Color backgroundColor = Color(0xFFF4F6EF);
  static const Color primaryColor = Color(0xFF4B7655);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 65,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'SnapExpiry is Locked',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Verify your identity to access your saved products.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 35),
                    Icon(
                      Icons.fingerprint,
                      size: 90,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 25),
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: state.isBiometricAuthenticating
                            ? null
                            : () => context
                                .read<AuthCubit>()
                                .authenticateToUnlock(),
                        icon: const Icon(Icons.fingerprint),
                        label: Text(
                          state.isBiometricAuthenticating
                              ? 'Verifying...'
                              : 'Unlock SnapExpiry',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}