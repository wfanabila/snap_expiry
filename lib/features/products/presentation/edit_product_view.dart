import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../cubit/edit_product_cubit.dart';
import '../cubit/edit_product_state.dart';
import '../data/product_repository.dart';

class EditProductView extends StatelessWidget {
  const EditProductView({
    required this.productId,
    super.key,
  });

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditProductCubit(
        repository: ProductRepository(),
        productId: productId,
      )..loadProduct(),
      child: const _EditProductForm(),
    );
  }
}

class _EditProductForm extends StatelessWidget {
  const _EditProductForm();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProductCubit, EditProductState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.status == EditProductStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.successMessage ?? 'Product updated successfully.',
              ),
            ),
          );

          context.pop(true);
        } else if (state.status == EditProductStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<EditProductCubit>();
        final isSaving = state.status == EditProductStatus.loading;

        if (state.status == EditProductStatus.initial &&
            state.product == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6F0),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.product == null &&
            state.status == EditProductStatus.failure) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F0),
            appBar: AppBar(
              title: const Text('Edit Product'),
              backgroundColor: const Color(0xFFF4F6F0),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: Color(0xFF2E7D5B),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Unable to load product.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: cubit.loadProduct,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final categoryOptions = [
          ...EditProductCubit.categories,
        ];

        if (!categoryOptions.contains(state.category)) {
          categoryOptions.add(state.category);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F0),
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Edit Product',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
              onPressed: () => context.pop(),
            ),
            backgroundColor: const Color(0xFFF4F6F0),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // PRODUCT INFORMATION

                      _SectionCard(
                        title: 'Product Information',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: ValueKey('name-${state.product!.id}'),
                              initialValue: state.name,
                              enabled: !isSaving,
                              onChanged: cubit.updateName,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Product Name *',
                                hintText: 'e.g. Fresh milk',
                                prefixIcon: Icon(
                                  Icons.inventory_2_outlined,
                                ),
                                filled: true,
                                fillColor: Color(0xFFF4F6F0),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: state.category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(
                                  Icons.category_outlined,
                                ),
                                filled: true,
                                fillColor: Color(0xFFF4F6F0),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: categoryOptions.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        cubit.updateCategory(value);
                                      }
                                    },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              key: ValueKey(
                                'quantity-${state.product!.id}',
                              ),
                              initialValue: state.quantity,
                              enabled: !isSaving,
                              onChanged: cubit.updateQuantity,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity *',
                                prefixIcon: Icon(Icons.numbers),
                                filled: true,
                                fillColor: Color(0xFFF4F6F0),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              key: ValueKey(
                                'barcode-${state.product!.id}',
                              ),
                              initialValue: state.barcode,
                              enabled: !isSaving,
                              onChanged: cubit.updateBarcode,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Barcode (optional)',
                                prefixIcon: Icon(
                                  Icons.qr_code_scanner,
                                ),
                                filled: true,
                                fillColor: Color(0xFFF4F6F0),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // TIMELINE AND DATES

                      _SectionCard(
                        title: 'Timeline & Dates',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Purchase Date'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F0),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xFFE9E9E9),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                DateFormat('dd MMMM yyyy').format(
                                  state.product!.createdAt,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            const Text('Expiration Date *'),
                            const SizedBox(height: 8),

                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE9E9E9),
                                  width: 1.5,
                                ),
                                backgroundColor:
                                    const Color(0xFFF4F6F0),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final today =
                                          DateUtils.dateOnly(
                                        DateTime.now(),
                                      );

                                      final selectedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate:
                                            state.expiryDate ?? today,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );

                                      if (selectedDate != null &&
                                          context.mounted) {
                                        cubit.updateExpiryDate(
                                          selectedDate,
                                        );
                                      }
                                    },
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.black,
                              ),
                              label: Text(
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                state.expiryDate == null
                                    ? 'Select expiry date'
                                    : 'Expiry date: ${DateFormat('dd MMM yyyy').format(state.expiryDate!)}',
                              ),
                            ),

                            const SizedBox(height: 12),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _DateSuggestion(
                                  label: '+3 Days',
                                  days: 3,
                                  onSelected: cubit.updateExpiryDate,
                                ),
                                _DateSuggestion(
                                  label: '+1 Week',
                                  days: 7,
                                  onSelected: cubit.updateExpiryDate,
                                ),
                                _DateSuggestion(
                                  label: '+2 Weeks',
                                  days: 14,
                                  onSelected: cubit.updateExpiryDate,
                                ),
                                _DateSuggestion(
                                  label: '+1 Month',
                                  days: 30,
                                  onSelected: cubit.updateExpiryDate,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ADDITIONAL NOTES

                      _SectionCard(
                        title: 'Additional Notes',
                        child: TextFormField(
                          key: ValueKey(
                            'notes-${state.product!.id}',
                          ),
                          initialValue: state.notes,
                          enabled: !isSaving,
                          onChanged: cubit.updateNotes,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF4F6F0),
                            hintText:
                                'Add any useful product details...',
                            prefixIcon: Icon(Icons.notes),
                            alignLabelWithHint: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFFE9E9E9),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFFE9E9E9),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // UPDATE PRODUCT BUTTON

                      SizedBox(
                        height: 49,
                        child: FilledButton.icon(
                          onPressed: isSaving
                              ? null
                              : cubit.saveProduct,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            isSaving
                                ? 'Updating...'
                                : 'Update Product',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF2E7D5B),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                if (isSaving)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          bottomNavigationBar:
              const AppBottomNav(currentIndex: 0),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// SECTION CARD
// ---------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// EXPIRY DATE SUGGESTION
// ---------------------------------------------------------

class _DateSuggestion extends StatelessWidget {
  const _DateSuggestion({
    required this.label,
    required this.days,
    required this.onSelected,
  });

  final String label;
  final int days;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: const Color(0xFFF4F6F0),
      labelStyle: const TextStyle(color: Colors.black),
      onPressed: () {
        onSelected(
          DateTime.now().add(Duration(days: days)),
        );
      },
    );
  }
}