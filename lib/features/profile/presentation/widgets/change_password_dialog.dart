import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/profile_action_cubit.dart';
import '../../cubit/profile_action_state.dart';

class ChangePasswordDialog extends StatelessWidget {
  const ChangePasswordDialog({super.key});

  static const Color primaryColor = Color(0xFF4B7655);

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF4F6F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileActionCubit(),
      child: BlocConsumer<ProfileActionCubit, ProfileActionState>(
        listener: (context, state) {
          if (state.status == ProfileActionStatus.success) {
            Navigator.pop(context, true);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.successMessage ?? 'Password changed.',
                ),
                backgroundColor: primaryColor,
              ),
            );
          }

          if (state.status == ProfileActionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Update failed.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<ProfileActionCubit>();
          final isLoading =
              state.status == ProfileActionStatus.loading;

          return AlertDialog(
            title: const Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    enabled: !isLoading,
                    obscureText: true,
                    onChanged: cubit.updateCurrentPassword,
                    decoration: _decoration('Current Password'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    enabled: !isLoading,
                    obscureText: true,
                    onChanged: cubit.updateNewPassword,
                    decoration: _decoration('New Password'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    enabled: !isLoading,
                    obscureText: true,
                    onChanged: cubit.updateConfirmPassword,
                    decoration: _decoration('Confirm New Password'),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password must contain at least 6 characters.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                onPressed: isLoading ? null : cubit.changePassword,
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }
}