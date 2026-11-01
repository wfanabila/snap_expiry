
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exceptions.dart';
import '../data/product_repository.dart';
import 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit({
    required ProductRepository repository,
  })  : _repository = repository,
        super(const ProductDetailsState());

  final ProductRepository _repository;

  Future<void> loadProduct(String productId) async {
    emit(
      state.copyWith(
        status: ProductDetailsStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final product = await _repository.getProduct(productId);

      if (product == null) {
        emit(
          state.copyWith(
            status: ProductDetailsStatus.failure,
            errorMessage: 'Product not found.',
            clearProduct: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: ProductDetailsStatus.success,
          product: product,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProductDetailsStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  
Future<void> loadProductFromRetry(String productId) {
  return loadProduct(productId);
}


  Future<void> updateProduct({
    required String name,
    required String category,
    required int quantity,
    required DateTime expiryDate,
    String? barcode,
    String? notes,
  }) async {
    final existing = state.product;

    if (existing == null ||
        state.status == ProductDetailsStatus.loading) {
      return;
    }

    if (name.trim().isEmpty) {
      _fail('Please enter a product name.');
      return;
    }

    if (quantity < 1) {
      _fail('Quantity must be at least 1.');
      return;
    }

    emit(
      state.copyWith(
        status: ProductDetailsStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final updated = existing.copyWith(
        name: name.trim(),
        category: category.trim().isEmpty ? 'Other' : category.trim(),
        quantity: quantity,
        expiryDate: DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
        ),
        barcode: _optionalValue(barcode),
        notes: _optionalValue(notes),
        updatedAt: DateTime.now(),
      );

      await _repository.updateProduct(updated);

      emit(
        state.copyWith(
          status: ProductDetailsStatus.success,
          product: updated,
          successMessage: 'Product updated successfully.',
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProductDetailsStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<void> deleteProduct() async {
    final product = state.product;

    if (product == null ||
        state.status == ProductDetailsStatus.loading) {
      return;
    }

    emit(
      state.copyWith(
        status: ProductDetailsStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await _repository.deleteProduct(product.id);

      emit(
        state.copyWith(
          status: ProductDetailsStatus.success,
          clearProduct: true,
          successMessage: 'Product deleted successfully.',
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProductDetailsStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  String? _optionalValue(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _message(Object error) {
    if (error is AppException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  void _fail(String message) {
    emit(
      state.copyWith(
        status: ProductDetailsStatus.failure,
        errorMessage: message,
        clearSuccess: true,
      ),
    );
  }
}

