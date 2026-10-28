
import 'package:equatable/equatable.dart';

enum OnboardingStatus {
  initial,
  loading,
  success,
  failure,
}

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final int currentPage;
  final bool hasCompleted;
  final String? errorMessage;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.currentPage = 0,
    this.hasCompleted = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    OnboardingStatus? status,
    int? currentPage,
    bool? hasCompleted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      hasCompleted: hasCompleted ?? this.hasCompleted,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentPage,
        hasCompleted,
        errorMessage,
      ];
}
