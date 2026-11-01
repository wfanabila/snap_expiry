
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String category;
  final int quantity;
  final DateTime expiryDate;
  final String? barcode;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.expiryDate,
    this.barcode,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    int? quantity,
    DateTime? expiryDate,
    String? barcode,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      barcode: barcode ?? this.barcode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'barcode': barcode,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Product.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Product(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      expiryDate: readDate(map['expiryDate']),
      barcode: map['barcode'] as String?,
      notes: map['notes'] as String?,
      createdAt: readDate(map['createdAt']),
      updatedAt: readDate(map['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        category,
        quantity,
        expiryDate,
        barcode,
        notes,
        createdAt,
        updatedAt,
      ];
}
