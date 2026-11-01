
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/app_exceptions.dart';
import '../domain/product.dart';

class ProductRepository {
  ProductRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw AppException('Please sign in to manage your products.');
    }

    return user.uid;
  }

  Future<void> addProduct(Product product) async {
    try {
      final now = DateTime.now();

      final document = _products.doc();

      final newProduct = product.copyWith(
        id: document.id,
        userId: _userId,
        createdAt: now,
        updatedAt: now,
      );

      await document.set(newProduct.toMap());
    } on FirebaseException catch (error) {
      throw AppException(
        error.message ?? 'Unable to save the product.',
        code: error.code,
      );
    }
  }

  Stream<List<Product>> watchProducts() {
    return _products
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();

      products.sort(
        (a, b) => a.expiryDate.compareTo(b.expiryDate),
      );

      return products;
    });
  }

  Future<Product?> getProduct(String productId) async {
    try {
      final document = await _products.doc(productId).get();

      if (!document.exists) return null;

      final data = document.data()!;

      if (data['userId'] != _userId) return null;

      return Product.fromMap(document.id, data);
    } on FirebaseException catch (error) {
      throw AppException(
        error.message ?? 'Unable to load the product.',
        code: error.code,
      );
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final reference = _products.doc(product.id);
      final existing = await reference.get();

      if (!existing.exists || existing.data()?['userId'] != _userId) {
        throw AppException('Product not found or access denied.');
      }

      await reference.update({
        ...product.toMap(),
        'userId': _userId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (error) {
      throw AppException(
        error.message ?? 'Unable to update the product.',
        code: error.code,
      );
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final reference = _products.doc(productId);
      final existing = await reference.get();

      if (!existing.exists || existing.data()?['userId'] != _userId) {
        throw AppException('Product not found or access denied.');
      }

      await reference.delete();
    } on FirebaseException catch (error) {
      throw AppException(
        error.message ?? 'Unable to delete the product.',
        code: error.code,
      );
    }
  }
}
