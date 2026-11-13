
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/utils/date_utils.dart';
import '../cubit/product_details_cubit.dart';
import '../cubit/product_details_state.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';

class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({
    required this.productId,
    super.key,
  });

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailsCubit(
        repository: ProductRepository(),
      )..loadProduct(productId),
      child: _ProductDetailsContent(productId: productId),
    );
  }
}

class _ProductDetailsContent extends StatelessWidget {
  const _ProductDetailsContent({
    required this.productId,
  });

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailsCubit, ProductDetailsState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );

          if (state.product == null &&
              state.successMessage == 'Product deleted successfully.') {
            context.pop();
          }
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final product = state.product;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F0),
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.go('/home'),
            ),
            backgroundColor: const Color(0xFFF4F6F0),
            actions: [
              if (product != null)
                IconButton(
                  tooltip: 'Delete product',
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 28,
                  color: Colors.black,
                  onPressed: state.status == ProductDetailsStatus.loading
                      ? null
                      : () => _confirmDelete(context),
                ),
            ],
          ),
          body: _buildBody(context, state, product),
          bottomNavigationBar: const AppBottomNav(currentIndex: 0),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductDetailsState state,
    Product? product,
  ) {
    if (state.status == ProductDetailsStatus.initial ||
        (state.status == ProductDetailsStatus.loading &&
            product == null)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (product == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Product not found.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  context.pop();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final expiryStatus = ExpiryDateUtils.statusFor(product.expiryDate);

    final statusLabel = switch (expiryStatus) {
      ExpiryStatus.expired => 'Expired',
      ExpiryStatus.expiringSoon => 'Expiring soon',
      ExpiryStatus.safe => 'Safe',
    };

    final statusColor = switch (expiryStatus) {
      ExpiryStatus.expired => Colors.red,
      ExpiryStatus.expiringSoon => Colors.orange,
      ExpiryStatus.safe => Colors.green,
    };

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 52,
                  color: const Color(0xFF2E7D5B),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Chip(
                label: Text(statusLabel),
                backgroundColor: statusColor.withValues(alpha: 0.12),
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: product.category,
              color: const Color(0xFF2E7D5B),
            ),
            _DetailRow(
              icon: Icons.numbers,
              label: 'Quantity',
              value: product.quantity.toString(),
              color: const Color(0xFF2E7D5B),
            ),
            _DetailRow(
              icon: Icons.event_outlined,
              label: 'Expiry date',
              value: ExpiryDateUtils.formatDate(product.expiryDate),
              color: const Color(0xFF2E7D5B),
            ),
            _DetailRow(
              icon: Icons.qr_code,
              label: 'Barcode',
              value: product.barcode?.isNotEmpty == true
                  ? product.barcode!
                  : 'Not provided',
              color: const Color(0xFF2E7D5B),
            ),
            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: product.notes?.isNotEmpty == true
                  ? product.notes!
                  : 'No notes',
              color: const Color(0xFF2E7D5B),
            ),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Last updated',
              value: DateFormat('dd MMM yyyy, hh:mm a')
                  .format(product.updatedAt),
              color: const Color(0xFF2E7D5B),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D5B),
              ),
              onPressed: state.status == ProductDetailsStatus.loading
                  ? null
                  : () async {
                    final updated = await context.push<bool>(
                      '/edit-product/${product.id}',
                    );
                    
                    if (updated == true && context.mounted) {
                      await context
                      .read<ProductDetailsCubit>()
                      .loadProduct(productId);
                    }
                  },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Product'),
            ),
          ],
        ),
        if (state.status == ProductDetailsStatus.loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text(
          'This product will be permanently removed from your list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ProductDetailsCubit>().deleteProduct();
    }
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D5B),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value, 
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF2E7D5B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
