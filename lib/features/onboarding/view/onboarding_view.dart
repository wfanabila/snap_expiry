import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/cubit/onboarding_cubit.dart';
import '../../onboarding/cubit/onboarding_state.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Track Your Products',
      description:
          'Keep all your products organised in one place and '
          'easily manage their expiry dates.',
      image: 'assets/images/onboarding_products.png',
    ),
    _OnboardingPageData(
      title: 'Never Miss an Expiry Date',
      description:
          'Stay aware of upcoming expiry dates and know which '
          'products need your attention.',
      image: 'assets/images/onboarding_expiry.png',
    ),
    _OnboardingPageData(
      title: 'Stay Organised',
      description:
          'Manage your products more conveniently with SnapExpiry.',
      image: 'assets/images/onboarding_organized.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: const _OnboardingContent(pages: _pages),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({required this.pages});

  final List<_OnboardingPageData> pages;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state.hasCompleted) {
          context.go('/login');
        }

        if (state.status == OnboardingStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();

        if (state.status == OnboardingStatus.loading &&
            state.currentPage == 0 &&
            !state.hasCompleted) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: state.status == OnboardingStatus.loading
                        ? null
                        : () => cubit.skipOnboarding(),
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: cubit.pageController,
                    itemCount: pages.length,
                    onPageChanged: cubit.updatePage,
                    itemBuilder: (context, index) {
                      final page = pages[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Image.asset(
                                page.image,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.inventory_2_outlined,
                                    size: 120,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: state.currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: state.currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          state.status == OnboardingStatus.loading
                              ? null
                              : () => cubit.nextPage(),
                      child: Text(
                        state.currentPage == pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
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

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.image,
  });

  final String title;
  final String description;
  final String image;
}
