import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_repository.dart';
import '../domain/product.dart';
import 'edit_product_state.dart';

class EditProductCubit extends Cubit<EditProductState> {
  EditProductCubit({
    required ProductRepository repository,
    required String productId,
  })  : _repository = repository,
        _productId = productId,
        super(const EditProductState());

  final ProductRepository _repository;
  final String _productId;

  static const List<String> categories = [
    'Food',
    'Beverages',
    'Dairy',
    'Personal Care',
    'Medicine',
    'Household',
    'Other',
  ];

  Future<void> loadProduct() async {
    emit(state.copyWith(
      status: EditProductStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final product = await _repository.getProduct(_productId);

      if (product == null) {
        emit(state.copyWith(
          status: EditProductStatus.failure,
          errorMessage: 'Product not found.',
        ));
        return;
      }

      emit(state.copyWith(
        status: EditProductStatus.initial,
        product: product,
        name: product.name,
        category: product.category,
        quantity: product.quantity.toString(),
        expiryDate: product.expiryDate,
        barcode: product.barcode ?? '',
        notes: product.notes ?? '',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: EditProductStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  void updateName(String value) {
    emit(state.copyWith(name: value));
  }

  void updateCategory(String value) {
    emit(state.copyWith(category: value));
  }

  void updateQuantity(String value) {
    emit(state.copyWith(quantity: value));
  }

  void updateExpiryDate(DateTime value) {
    emit(state.copyWith(expiryDate: value));
  }

  void updateBarcode(String value) {
    emit(state.copyWith(barcode: value));
  }

  void updateNotes(String value) {
    emit(state.copyWith(notes: value));
  }

  Future<void> saveProduct() async {
    final product = state.product;

    if (product == null) return;

    if (state.name.trim().isEmpty) {
      emit(state.copyWith(
        status: EditProductStatus.failure,
        errorMessage: 'Please enter a product name.',
      ));
      return;
    }

    final quantity = int.tryParse(state.quantity.trim());

    if (quantity == null || quantity < 1) {
      emit(state.copyWith(
        status: EditProductStatus.failure,
        errorMessage: 'Please enter a valid quantity of at least 1.',
      ));
      return;
    }

    if (state.expiryDate == null) {
      emit(state.copyWith(
        status: EditProductStatus.failure,
        errorMessage: 'Please select an expiration date.',
      ));
      return;
    }

    emit(state.copyWith(
      status: EditProductStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final updatedProduct = Product(
        id: product.id,
        userId: product.userId,
        name: state.name.trim(),
        category: state.category,
        quantity: quantity,
        expiryDate: state.expiryDate!,
        barcode: state.barcode.trim().isEmpty
            ? null
            : state.barcode.trim(),
        notes: state.notes.trim().isEmpty
            ? null
            : state.notes.trim(),
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
      );

      await _repository.updateProduct(updatedProduct);

      emit(state.copyWith(
        status: EditProductStatus.success,
        product: updatedProduct,
        successMessage: 'Product updated successfully.',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: EditProductStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }
}