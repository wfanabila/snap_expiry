
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import '../data/product_repository.dart';
import 'widgets/product_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductsCubit(
        repository: ProductRepository(),
      )..loadProducts(),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapExpiry'),
      ),

      body: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          final cubit = context.read<ProductsCubit>();

          if (state.status == ProductsStatus.loading &&
              state.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == ProductsStatus.failure &&
              state.products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Unable to load products.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: cubit.loadProducts,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = state.filteredProducts;

          final expiredCount = state.products
              .where(
                (product) => product.expiryDate.isBefore(
                  DateUtils.dateOnly(DateTime.now()),
                ),
              )
              .length;

          final soonCount = state.products.where((product) {
            final days = DateUtils.dateOnly(product.expiryDate)
                .difference(DateUtils.dateOnly(DateTime.now()))
                .inDays;

            return days >= 0 && days <= 7;
          }).length;

          return RefreshIndicator(
            onRefresh: cubit.loadProducts,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Your products',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep track of expiry dates and reduce waste.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total',
                        count: state.products.length,
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Expiring soon',
                        count: soonCount,
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Expired',
                        count: expiredCount,
                        icon: Icons.error_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  onChanged: cubit.searchProducts,
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                if (state.status == ProductsStatus.failure)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.errorMessage ?? 'Unable to refresh products.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),

                if (products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.searchQuery.isEmpty
                              ? 'No products yet'
                              : 'No matching products',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.searchQuery.isEmpty
                              ? 'Tap Add below to get started.'
                              : 'Try a different search term.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...products.map(
                    (product) => ProductCard(
                      product: product,
                      onTap: () =>
                          context.push('/product/${product.id}'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/add-product');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
  });

  final String title;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 14,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
