
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exceptions.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit({
    required ProductRepository repository,
  })  : _repository = repository,
        super(ProductsState());

  final ProductRepository _repository;
  StreamSubscription? _productsSubscription;

  Future<void> loadProducts() async {
    emit(
      state.copyWith(
        status: ProductsStatus.loading,
        clearError: true,
      ),
    );

    await _productsSubscription?.cancel();
    _productsSubscription = null;

    try {
      _productsSubscription = _repository.watchProducts().listen(
        (products) {
          emit(
            state.copyWith(
              status: ProductsStatus.success,
              products: products,
              clearError: true,
            ),
          );
        },
        onError: (Object error) {
          if (isClosed) return;

          emit(
            state.copyWith(
              status: ProductsStatus.failure,
              errorMessage: _errorMessage(error),
            ),
          );
        },
      );
    } catch (error) {
      if (isClosed) return;

      emit(
        state.copyWith(
          status: ProductsStatus.failure,
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  void searchProducts(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        clearError: true,
      ),
    );
  }

  void changeFilter(ProductFilter filter) {
    emit(
      state.copyWith(
        selectedFilter: filter,
        clearError: true,
      ),
    );
  }

  Future<void> deleteProduct(Product product) async {
    final originalProducts = state.products;

    try {
      await _repository.deleteProduct(product.id);

      if (isClosed) return;

      // Update the UI immediately after successful deletion.
      final updatedProducts = originalProducts
          .where((item) => item.id != product.id)
          .toList(growable: false);

      emit(
        state.copyWith(
          status: ProductsStatus.success,
          products: updatedProducts,
          clearError: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;

      // Restore the product if deletion fails.
      emit(
        state.copyWith(
          status: ProductsStatus.failure,
          products: originalProducts,
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  String _errorMessage(Object error) {
    if (error is AppException) return error.message;

    return 'Unable to manage products. Please try again.';
  }

  @override
  Future<void> close() async {
    await _productsSubscription?.cancel();
    return super.close();
  }
}
