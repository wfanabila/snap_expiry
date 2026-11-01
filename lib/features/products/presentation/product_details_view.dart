
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
          appBar: AppBar(
            title: const Text('Product Details'),
            actions: [
              if (product != null)
                IconButton(
                  tooltip: 'Delete product',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: state.status == ProductDetailsStatus.loading
                      ? null
                      : () => _confirmDelete(context),
                ),
            ],
          ),
          body: _buildBody(context, state, product),
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
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
            ),
            _DetailRow(
              icon: Icons.numbers,
              label: 'Quantity',
              value: product.quantity.toString(),
            ),
            _DetailRow(
              icon: Icons.event_outlined,
              label: 'Expiry date',
              value: ExpiryDateUtils.formatDate(product.expiryDate),
            ),
            _DetailRow(
              icon: Icons.qr_code,
              label: 'Barcode',
              value: product.barcode?.isNotEmpty == true
                  ? product.barcode!
                  : 'Not provided',
            ),
            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: product.notes?.isNotEmpty == true
                  ? product.notes!
                  : 'No notes',
            ),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Last updated',
              value: DateFormat('dd MMM yyyy, hh:mm a')
                  .format(product.updatedAt),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: state.status == ProductDetailsStatus.loading
                  ? null
                  : () => _showEditDialog(context, product),
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

  Future<void> _showEditDialog(
    BuildContext context,
    Product product,
  ) async {
    final nameController = TextEditingController(text: product.name);
    final quantityController = TextEditingController(
      text: product.quantity.toString(),
    );
    final barcodeController = TextEditingController(
      text: product.barcode ?? '',
    );
    final notesController = TextEditingController(
      text: product.notes ?? '',
    );

    var category = product.category;
    var expiryDate = product.expiryDate;

    final formKey = GlobalKey<FormState>();
    final cubit = context.read<ProductDetailsCubit>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a product name'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          'Food',
                          'Beverage',
                          'Medicine',
                          'Personal Care',
                          'Household',
                          'Other',
                        ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final quantity = int.tryParse(value ?? '');
                          if (quantity == null || quantity < 1) {
                            return 'Enter a quantity of at least 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: expiryDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );

                            if (selectedDate != null) {
                              setDialogState(
                                () => expiryDate = selectedDate,
                              );
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            'Expiry: ${ExpiryDateUtils.formatDate(expiryDate)}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    Navigator.pop(dialogContext);

                    await cubit.updateProduct(
                      name: nameController.text,
                      category: category,
                      quantity: int.parse(quantityController.text),
                      expiryDate: expiryDate,
                      barcode: barcodeController.text,
                      notes: notesController.text,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    quantityController.dispose();
    barcodeController.dispose();
    notesController.dispose();
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
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
