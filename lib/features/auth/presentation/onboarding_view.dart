import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/cubit/onboarding_cubit.dart';
import '../../onboarding/cubit/onboarding_state.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.inventory_2_outlined,
      title: 'Track Your Products',
      description:
          'Keep your products and their expiry dates organized in one place.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_outlined,
      title: 'Stay Ahead of Expiry Dates',
      description:
          'Identify products that are expired or expiring soon so you can plan ahead.',
    ),
    _OnboardingPage(
      icon: Icons.checklist_rounded,
      title: 'Make Every Product Count',
      description:
          'Manage your products more easily and reduce unnecessary waste.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: const _OnboardingContent(),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final theme = Theme.of(context);

    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.hasCompleted != current.hasCompleted ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.hasCompleted) {
          context.go('/login');
        } 

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              ),
            );
        }
      },
      builder: (context, state) {
        if (state.status == OnboardingStatus.initial ||
            state.status == OnboardingStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == OnboardingStatus.failure &&
            state.errorMessage != null &&
            state.currentPage == 0) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: cubit.load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isLastPage =
            state.currentPage == OnboardingView._pages.length - 1;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: state.status == OnboardingStatus.loading
                        ? null
                        : cubit.skipOnboarding,
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: cubit.pageController,
                    itemCount: OnboardingView._pages.length,
                    onPageChanged: cubit.updatePage,
                    itemBuilder: (context, index) {
                      final page = OnboardingView._pages[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                page.icon,
                                size: 96,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          OnboardingView._pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: state.currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: state.currentPage == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              state.status == OnboardingStatus.loading
                                  ? null
                                  : cubit.nextPage,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              isLastPage ? 'Get Started' : 'Next',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
