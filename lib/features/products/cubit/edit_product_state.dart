import 'package:equatable/equatable.dart';

import '../domain/product.dart';

enum EditProductStatus {
  initial,
  loading,
  success,
  failure,
}

class EditProductState extends Equatable {
  final EditProductStatus status;
  final Product? product;
  final String name;
  final String category;
  final String quantity;
  final DateTime? expiryDate;
  final String barcode;
  final String notes;
  final String? errorMessage;
  final String? successMessage;

  const EditProductState({
    this.status = EditProductStatus.initial,
    this.product,
    this.name = '',
    this.category = 'Other',
    this.quantity = '1',
    this.expiryDate,
    this.barcode = '',
    this.notes = '',
    this.errorMessage,
    this.successMessage,
  });

  EditProductState copyWith({
    EditProductStatus? status,
    Product? product,
    String? name,
    String? category,
    String? quantity,
    DateTime? expiryDate,
    String? barcode,
    String? notes,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return EditProductState(
      status: status ?? this.status,
      product: product ?? this.product,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      barcode: barcode ?? this.barcode,
      notes: notes ?? this.notes,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        product,
        name,
        category,
        quantity,
        expiryDate,
        barcode,
        notes,
        errorMessage,
        successMessage,
      ];
}