
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../domain/product.dart';

enum ProductsStatus {
  initial,
  loading,
  success,
  failure,
}

enum ProductFilter {
  all,
  expired,
  expiringSoon,
}

class ProductsState extends Equatable {
  final ProductsStatus status;
  final List<Product> products;
  final String searchQuery;
  final String? errorMessage;
  final ProductFilter selectedFilter;

  ProductsState({
    this.status = ProductsStatus.initial,
    List<Product> products = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.selectedFilter = ProductFilter.all,
  }) : products = List.unmodifiable(products);

  List<Product> get filteredProducts {
    final today = DateUtils.dateOnly(DateTime.now());
    final query = searchQuery.trim().toLowerCase();

    return products.where((product) {
      // Search filter
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);

      if (!matchesSearch) return false;

      // Category filter
      final expiryDate = DateUtils.dateOnly(product.expiryDate);
      final daysUntilExpiry = expiryDate.difference(today).inDays;

      switch (selectedFilter) {
        case ProductFilter.all:
          return true;

        case ProductFilter.expired:
          return daysUntilExpiry < 0;

        case ProductFilter.expiringSoon:
          return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
      }
    }).toList(growable: false);
  }

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    String? searchQuery,
    String? errorMessage,
    ProductFilter? selectedFilter,
    bool clearError = false,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        searchQuery,
        errorMessage,
        selectedFilter,
      ];
}
