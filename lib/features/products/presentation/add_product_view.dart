
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../cubit/add_product_cubit.dart';
import '../cubit/add_product_state.dart';
import '../data/product_repository.dart';
import 'barcode_scanner_view.dart';

class AddProductView extends StatelessWidget {
  const AddProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddProductCubit(
        repository: ProductRepository(),
      ),
      child: const _AddProductForm(),
    );
  }
}

class _AddProductForm extends StatelessWidget {
  const _AddProductForm();

  static const List<String> _categories = [
    'Food',
    'Beverages',
    'Dairy',
    'Personal Care',
    'Medicine',
    'Household',
    'Other',
  ];

  // ---------------------------------------------------------
  // PHOTO OPTIONS
  // ---------------------------------------------------------

  Future<void> _showPhotoOptions(
    BuildContext context,
    AddProductCubit cubit,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  cubit.pickAndReadLabel(
                    source: ImageSource.camera,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  cubit.pickAndReadLabel(
                    source: ImageSource.gallery,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // BARCODE SCANNER
  // ---------------------------------------------------------

  Future<void> _openBarcodeScanner(
    BuildContext context,
    AddProductCubit cubit,
  ) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerView(),
      ),
    );

    if (barcode != null && context.mounted) {
      await cubit.lookupBarcode(barcode);
    }
  }

  // ---------------------------------------------------------
  // BUILD UI
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddProductCubit, AddProductState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == AddProductStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.successMessage ??
                    'Product added successfully.',
              ),
            ),
          );

          context.pop();
        } else if (state.status == AddProductStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AddProductCubit>();

        final isProcessing = state.isProcessing;
        final isSaving =
            state.status == AddProductStatus.loading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Add Product'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: const Color(0xFFF4F6F0),
          ),
          body: SafeArea(
            child: Container(
              color: const Color(0xFFF4F6F0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PHOTO AND BARCODE BUTTONS

                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          title: 'Add Photo',
                          subtitle: 'Auto crops & reads label',
                          icon: Icons.add_a_photo_outlined,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          onTap: isProcessing || isSaving
                              ? null
                              : () => _showPhotoOptions(
                                    context,
                                    cubit,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          title: 'Scan Barcode',
                          subtitle: 'Auto-fill product details',
                          icon: Icons.document_scanner_outlined,
                          backgroundColor: const Color(0xFF2E7D5B),
                          foregroundColor: Colors.white,
                          onTap: isProcessing || isSaving
                              ? null
                              : () => _openBarcodeScanner(
                                    context,
                                    cubit,
                                  ),
                        ),
                      ),
                    ],
                  ),

                  // PROCESSING INDICATOR

                  if (isProcessing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      state.processingMessage ?? 'Processing...',
                      textAlign: TextAlign.center,
                    ),
                  ],

                  if (state.processingMessage != null &&
                      !isProcessing) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.processingMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],

                  // IMAGE PREVIEW

                  if (state.imagePath != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(state.imagePath!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // PRODUCT INFORMATION

                  _SectionCard(
                    backgroundColor: const Color(0xFFFFFFFF),
                    title: 'Product Information',
                    child: Column( 
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: cubit.nameController,
                          enabled: !isSaving && !isProcessing,
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
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: isSaving || isProcessing
                              ? null
                              : (value) {
                                  if (value != null) {
                                    cubit.updateCategory(value);
                                  }
                                },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          initialValue: state.quantity,
                          enabled: !isSaving && !isProcessing,
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

                        TextField(
                          controller: cubit.barcodeController,
                          enabled: !isSaving && !isProcessing,
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
                    backgroundColor: const Color(0xFFFFFFFF),
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
                          ),
                          child: Text(
                            DateFormat('dd MMMM yyyy')
                                .format(DateTime.now()),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text('Expiration Date *'),
                        const SizedBox(height: 8),

                        OutlinedButton.icon(
                          onPressed: isSaving || isProcessing
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
                                    context
                                        .read<AddProductCubit>()
                                        .updateExpiryDate(
                                          selectedDate,
                                        );
                                  }
                                },
                          icon: const Icon(
                            Icons.calendar_month_outlined, color: Colors.black
                          ),
                          label: Text(
                            style: TextStyle(
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
                              backgroundColor: const Color(0xFFF4F6F0),
                              foregroundColor: Colors.black,
                              label: '+3 Days',
                              days: 3,
                              onSelected: cubit.updateExpiryDate,
                            ),
                            _DateSuggestion(
                              backgroundColor: const Color(0xFFF4F6F0),
                              foregroundColor: Colors.black,
                              label: '+1 Week',
                              days: 7,
                              onSelected: cubit.updateExpiryDate,
                            ),
                            _DateSuggestion(
                              backgroundColor: const Color(0xFFF4F6F0),
                              foregroundColor: Colors.black,
                              label: '+2 Weeks',
                              days: 14,
                              onSelected: cubit.updateExpiryDate,
                            ),
                            _DateSuggestion(
                              backgroundColor: const Color(0xFFF4F6F0),
                              foregroundColor: Colors.black,
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
                    backgroundColor: const Color(0xFFFFFFFF),
                    title: 'Additional Notes',
                    child: TextFormField(
                      initialValue: state.notes,
                      enabled: !isSaving && !isProcessing,
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
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // SAVE PRODUCT

                  SizedBox(
                    height: 49,
                    child: FilledButton.icon(
                      onPressed: isSaving || isProcessing
                          ? null
                          : cubit.addProduct,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isSaving
                            ? 'Saving...'
                            : 'Save Product',
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
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// ACTION CARD
// ---------------------------------------------------------

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 150,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: foregroundColor,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: foregroundColor,
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

// ---------------------------------------------------------
// SECTION CARD
// ---------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.backgroundColor,
  });

  final String title;
  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
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
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor = Colors.transparent,
  });

  final String label;
  final int days;
  final ValueChanged<DateTime> onSelected;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color borderColor; 

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: foregroundColor == null
          ? null
          : TextStyle(color: foregroundColor),
      onPressed: () {
        final expiryDate = DateTime.now().add(
          Duration(days: days),
        );

        onSelected(expiryDate);
      },
    );
  }
}
