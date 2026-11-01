
import 'package:equatable/equatable.dart';

enum AddProductStatus {
  initial,
  loading,
  success,
  failure,
}

class AddProductState extends Equatable {
  final AddProductStatus status;
  final String name;
  final String category;
  final String quantity;
  final DateTime? expiryDate;
  final String barcode;
  final String notes;
  final String? errorMessage;
  final String? successMessage;

  // Photo recognition state
  final String? imagePath;
  final bool isProcessing;
  final String? processingMessage;

  const AddProductState({
    this.status = AddProductStatus.initial,
    this.name = '',
    this.category = 'Food',
    this.quantity = '1',
    this.expiryDate,
    this.barcode = '',
    this.notes = '',
    this.errorMessage,
    this.successMessage,
    this.imagePath,
    this.isProcessing = false,
    this.processingMessage,
  });

  AddProductState copyWith({
    AddProductStatus? status,
    String? name,
    String? category,
    String? quantity,
    DateTime? expiryDate,
    String? barcode,
    String? notes,
    String? errorMessage,
    String? successMessage,
    String? imagePath,
    bool? isProcessing,
    String? processingMessage,
    bool clearExpiryDate = false,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearImage = false,
    bool clearProcessingMessage = false,
  }) {
    return AddProductState(
      status: status ?? this.status,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expiryDate:
          clearExpiryDate ? null : expiryDate ?? this.expiryDate,
      barcode: barcode ?? this.barcode,
      notes: notes ?? this.notes,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      isProcessing: isProcessing ?? this.isProcessing,
      processingMessage: clearProcessingMessage
          ? null
          : processingMessage ?? this.processingMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        name,
        category,
        quantity,
        expiryDate,
        barcode,
        notes,
        errorMessage,
        successMessage,
        imagePath,
        isProcessing,
        processingMessage,
      ];
}
