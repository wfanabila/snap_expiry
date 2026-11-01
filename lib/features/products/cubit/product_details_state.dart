
import 'package:equatable/equatable.dart';

import '../domain/product.dart';

enum ProductDetailsStatus {
  initial,
  loading,
  success,
  failure,
}

class ProductDetailsState extends Equatable {
  final ProductDetailsStatus status;
  final Product? product;
  final String? errorMessage;
  final String? successMessage;

  const ProductDetailsState({
    this.status = ProductDetailsStatus.initial,
    this.product,
    this.errorMessage,
    this.successMessage,
  });

  ProductDetailsState copyWith({
    ProductDetailsStatus? status,
    Product? product,
    String? errorMessage,
    String? successMessage,
    bool clearProduct = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProductDetailsState(
      status: status ?? this.status,
      product: clearProduct ? null : product ?? this.product,
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
        errorMessage,
        successMessage,
      ];
}
