import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/profile_action_cubit.dart';
import '../../cubit/profile_action_state.dart';

class EditProfileDialog extends StatelessWidget {
  const EditProfileDialog({
    super.key,
    required this.currentName,
  });

  final String currentName;

  static const Color primaryColor = Color(0xFF4B7655);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileActionCubit()..updateName(currentName),
      child: BlocConsumer<ProfileActionCubit, ProfileActionState>(
        listener: (context, state) {
          if (state.status == ProfileActionStatus.success) {
            Navigator.pop(context, true);
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
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: TextFormField(
              initialValue: currentName,
              enabled: !isLoading,
              onChanged: cubit.updateName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: const Color(0xFFF4F6F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
                onPressed: isLoading ? null : cubit.updateProfile,
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}