
import 'package:equatable/equatable.dart';

import '../domain/product.dart';

enum ProductsStatus {
  initial,
  loading,
  success,
  failure,
}

class ProductsState extends Equatable {
  final ProductsStatus status;
  final List<Product> products;
  final String searchQuery;
  final String? errorMessage;

  ProductsState({
    this.status = ProductsStatus.initial,
    List<Product> products = const [],
    this.searchQuery = '',
    this.errorMessage,
  }) : products = List.unmodifiable(products);

  List<Product> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return products;

    return products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        searchQuery,
        errorMessage,
      ];
}
