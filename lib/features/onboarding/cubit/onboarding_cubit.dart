
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState()) {
    load();
  }

  static const String _completedKey = 'snap_expiry_onboarding_completed';

  final PageController pageController = PageController();

  static const int totalPages = 3;

  Future<void> load() async {
    emit(state.copyWith(
      status: OnboardingStatus.loading,
      clearError: true,
    ));

    try {
      final preferences = await SharedPreferences.getInstance();
      final completed = preferences.getBool(_completedKey) ?? false;

      emit(state.copyWith(
        status: OnboardingStatus.success,
        hasCompleted: completed,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: 'Unable to load onboarding settings.',
      ));
    }
  }

  void updatePage(int page) {
    if (page < 0 || page >= totalPages) return;

    emit(state.copyWith(
      currentPage: page,
      clearError: true,
    ));
  }

  Future<void> nextPage() async {
    if (state.currentPage < totalPages - 1) {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await completeOnboarding();
    }
  }

  Future<void> skipOnboarding() async {
    await completeOnboarding();
  }

  Future<void> completeOnboarding() async {
    emit(state.copyWith(
      status: OnboardingStatus.loading,
      clearError: true,
    ));

    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(_completedKey, true);

      if (!saved) {
        throw Exception('Unable to save onboarding preference.');
      }

      emit(state.copyWith(
        status: OnboardingStatus.success,
        hasCompleted: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: 'Unable to save your onboarding progress. Please try again.',
      ));
    }
  }

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}
