
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';
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
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F0),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFE9E9E9),
            width: 1.5,
          ),
        ),
        title: Text(
          'Hello, ${FirebaseAuth.instance.currentUser?.displayName ?? 'there'}!',
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Inter',
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
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

          final today = DateUtils.dateOnly(DateTime.now());

          final expiredCount = state.products.where((product) {
            return DateUtils.dateOnly(product.expiryDate)
                .isBefore(today);
          }).length;

          final soonCount = state.products.where((product) {
            final days = DateUtils.dateOnly(product.expiryDate)
                .difference(today)
                .inDays;

            return days >= 0 && days <= 7;
          }).length;

          return RefreshIndicator(
            onRefresh: cubit.loadProducts,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total',
                        count: state.products.length,
                        backgroundColor: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Expiring soon',
                        count: soonCount,
                        backgroundColor: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Expired',
                        count: expiredCount,
                        backgroundColor: Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Search bar
                TextField(
                  onChanged: cubit.searchProducts,
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Color(0xFFFFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide(
                        color: Color(0xFFFFFFFF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Category filter cards
                Row(
                  children: [
                    Expanded(
                      child: _CategoryCard(
                        title: 'All',
                        backgroundColor: Color(0xFFFFFFFF),
                        isSelected:
                            state.selectedFilter == ProductFilter.all,
                        onTap: () {
                          cubit.changeFilter(ProductFilter.all);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CategoryCard(
                        title: 'Expired',
                        backgroundColor: Color(0xFFFFFFFF),
                        isSelected:
                            state.selectedFilter == ProductFilter.expired,
                        onTap: () {
                          cubit.changeFilter(ProductFilter.expired);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CategoryCard(
                        title: 'Expiring Soon',
                        backgroundColor: Color(0xFFFFFFFF),
                        isSelected: state.selectedFilter ==
                            ProductFilter.expiringSoon,
                        onTap: () {
                          cubit.changeFilter(
                            ProductFilter.expiringSoon,
                          );
                        },                 
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Error message
                if (state.status == ProductsStatus.failure)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.errorMessage ??
                          'Unable to complete the operation.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),

                // Empty state or product list
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
                          _emptyTitle(state),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _emptySubtitle(state),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...products.map(
                    (product) => _SwipeToDeleteProduct(
                      key: ValueKey(product.id),
                      product: product,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  String _emptyTitle(ProductsState state) {
    if (state.searchQuery.isNotEmpty) {
      return 'No matching products';
    }

    switch (state.selectedFilter) {
      case ProductFilter.all:
        return 'No products yet';
      case ProductFilter.expired:
        return 'No expired products';
      case ProductFilter.expiringSoon:
        return 'No products expiring soon';
    }
  }

  String _emptySubtitle(ProductsState state) {
    if (state.searchQuery.isNotEmpty) {
      return 'Try a different search term.';
    }

    if (state.selectedFilter == ProductFilter.all) {
      return 'Tap Add below to get started.';
    }

    return 'Your products will appear here when they match this category.';
  }
}

// Swipe-to-delete product
class _SwipeToDeleteProduct extends StatelessWidget {
  const _SwipeToDeleteProduct({
    super.key,
    required this.product,
  });

  final Product product;

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete product?'),
          content: Text(
            'Are you sure you want to delete "${product.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context.read<ProductsCubit>().deleteProduct(product);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: ProductCard(
        product: product,
        onTap: () {
          context.push('/product/${product.id}');
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.backgroundColor, 
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      height: 35,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isSelected ? 2 : 0,
        color: isSelected ? Color(0xFF2E7D5B) : Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 9,
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Color(0xFFFFFFFF) : Color(0xFF000000),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.count,
    required this.backgroundColor,
  });

  final String title;
  final int count;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 14,
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000000),
              ),
              
            ),
          ],
        ),
      ),
    );
  }
}
