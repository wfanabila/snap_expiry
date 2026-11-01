
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/app_exceptions.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';
import 'add_product_state.dart';

class AddProductCubit extends Cubit<AddProductState> {
  AddProductCubit({
    required ProductRepository repository,
  })  : _repository = repository,
        super(const AddProductState());

  final ProductRepository _repository;

  final ImagePicker _imagePicker = ImagePicker();

  // Controllers keep automatically detected values visible in the form.
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController barcodeController =
      TextEditingController();

  // ---------------------------------------------------------
  // MANUAL FORM UPDATES
  // ---------------------------------------------------------

  void updateName(String value) {
    emit(state.copyWith(
      name: value,
      clearError: true,
    ));
  }

  void updateCategory(String value) {
    emit(state.copyWith(
      category: value,
      clearError: true,
    ));
  }

  void updateQuantity(String value) {
    emit(state.copyWith(
      quantity: value,
      clearError: true,
    ));
  }

  void updateExpiryDate(DateTime value) {
    emit(state.copyWith(
      expiryDate: value,
      clearError: true,
    ));
  }

  void updateBarcode(String value) {
    emit(state.copyWith(
      barcode: value,
      clearError: true,
    ));
  }

  void updateNotes(String value) {
    emit(state.copyWith(
      notes: value,
      clearError: true,
    ));
  }

  void _setDetectedName(String value) {
    nameController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(
        offset: value.length,
      ),
    );

    emit(state.copyWith(
      name: value,
      clearError: true,
    ));
  }

  void _setDetectedBarcode(String value) {
    barcodeController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(
        offset: value.length,
      ),
    );

    emit(state.copyWith(
      barcode: value,
      clearError: true,
    ));
  }

  // ---------------------------------------------------------
  // ADD PHOTO: IMAGE PICKING, CROPPING AND OCR
  // ---------------------------------------------------------

  Future<void> pickAndReadLabel({
    ImageSource source = ImageSource.camera,
  }) async {
    if (state.isProcessing) return;

    emit(state.copyWith(
      isProcessing: true,
      processingMessage: 'Selecting product image...',
      clearError: true,
      clearProcessingMessage: true,
    ));

    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (selectedImage == null) {
        emit(state.copyWith(
          isProcessing: false,
          clearProcessingMessage: true,
        ));
        return;
      }

      emit(state.copyWith(
        imagePath: selectedImage.path,
        processingMessage: 'Preparing image...',
      ));

      final CroppedFile? croppedImage =
          await ImageCropper().cropImage(
        sourcePath: selectedImage.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop product label',
            toolbarColor: const Color(0xFF287D5B),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop product label',
          ),
        ],
      );

      if (croppedImage == null) {
        emit(state.copyWith(
          isProcessing: false,
          clearProcessingMessage: true,
        ));
        return;
      }

      emit(state.copyWith(
        imagePath: croppedImage.path,
        processingMessage: 'Reading product label...',
      ));

      final inputImage = InputImage.fromFilePath(
        croppedImage.path,
      );

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      try {
        final recognizedText =
            await textRecognizer.processImage(inputImage);

        final extractedName = _extractProductName(
          recognizedText.text,
        );

        final extractedExpiryDate = _extractExpiryDate(
          recognizedText.text,
        );

        if (extractedName != null) {
          _setDetectedName(extractedName);
        }

        emit(state.copyWith(
          expiryDate: extractedExpiryDate,
          isProcessing: false,
          processingMessage: extractedName != null ||
                  extractedExpiryDate != null
              ? 'Label recognised. Please verify the details.'
              : 'Text was read, but product details were not detected.',
          clearError: true,
          clearProcessingMessage: extractedName == null &&
              extractedExpiryDate == null,
        ));
      } finally {
        await textRecognizer.close();
      }
    } catch (error) {
      emit(state.copyWith(
        isProcessing: false,
        errorMessage: 'Unable to read the image. Please try again.',
        clearProcessingMessage: true,
      ));
    }
  }

  // Extract a possible product name from recognised text.
  String? _extractProductName(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length >= 3)
        .toList();

    for (final line in lines) {
      final upper = line.toUpperCase();

      if (upper.contains('EXP') ||
          upper.contains('BEST BEFORE') ||
          upper.contains('USE BY') ||
          upper.contains('MFG') ||
          upper.contains('MANUFACTURED') ||
          upper.contains('INGREDIENT')) {
        continue;
      }

      return line;
    }

    return null;
  }

  // Detect dates near expiry-related labels first.
  DateTime? _extractExpiryDate(String text) {
    final lines = text.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase();

      final isExpiryLine = upper.contains('EXP') ||
          upper.contains('BEST BEFORE') ||
          upper.contains('USE BY');

      if (isExpiryLine) {
        final dateOnSameLine = _findDate(lines[i]);

        if (dateOnSameLine != null) {
          return dateOnSameLine;
        }

        // Sometimes OCR puts the label and date on separate lines.
        if (i + 1 < lines.length) {
          final nextLineDate = _findDate(lines[i + 1]);

          if (nextLineDate != null) {
            return nextLineDate;
          }
        }
      }
    }

    return null;
  }

  DateTime? _findDate(String text) {
    // YYYY-MM-DD or YYYY/MM/DD
    final yearFirst = RegExp(
      r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b',
    );

    // DD/MM/YYYY or DD-MM-YYYY (Malaysian date convention)
    final dayFirst = RegExp(
      r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{4})\b',
    );

    // 25 May 2027
    final monthName = RegExp(
      r'\b(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})\b',
    );

    var match = yearFirst.firstMatch(text);

    if (match != null) {
      return _validDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }

    match = dayFirst.firstMatch(text);

    if (match != null) {
      return _validDate(
        int.parse(match.group(3)!),
        int.parse(match.group(2)!),
        int.parse(match.group(1)!),
      );
    }

    match = monthName.firstMatch(text);

    if (match != null) {
      final month = _monthNumber(match.group(2)!);

      if (month != null) {
        return _validDate(
          int.parse(match.group(3)!),
          month,
          int.parse(match.group(1)!),
        );
      }
    }

    return null;
  }

  int? _monthNumber(String month) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    return months[month.toLowerCase().substring(0, 3)];
  }

  DateTime? _validDate(int year, int month, int day) {
    if (year < 2000 || year > 2100) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final date = DateTime(year, month, day);

    if (date.year != year ||
        date.month != month ||
        date.day != day) {
      return null;
    }

    return date;
  }

  // ---------------------------------------------------------
  // SCAN BARCODE: OPEN FOOD FACTS LOOKUP
  // ---------------------------------------------------------

  Future<void> lookupBarcode(String barcode) async {
    final cleanedBarcode = barcode.trim();

    if (cleanedBarcode.isEmpty || state.isProcessing) return;

    _setDetectedBarcode(cleanedBarcode);

    emit(state.copyWith(
      isProcessing: true,
      processingMessage: 'Searching product database...',
      clearError: true,
      clearProcessingMessage: true,
    ));

    try {
      final uri = Uri.https(
        'world.openfoodfacts.org',
        '/api/v2/product/$cleanedBarcode',
        {
          'fields': 'product_name,brands,categories',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'SnapExpiry/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Product database unavailable.');
      }

      final data = jsonDecode(response.body)
          as Map<String, dynamic>;

      if (data['status'] != 1 || data['product'] == null) {
        emit(state.copyWith(
          isProcessing: false,
          processingMessage:
              'Product not found. Please enter details manually.',
          clearError: true,
        ));
        return;
      }

      final product = data['product'] as Map<String, dynamic>;

      final productName =
          product['product_name']?.toString().trim() ?? '';

      final category = _mapCategory(
        product['categories']?.toString() ?? '',
      );

      if (productName.isNotEmpty) {
        _setDetectedName(productName);
      }

      emit(state.copyWith(
        category: category ?? state.category,
        barcode: cleanedBarcode,
        isProcessing: false,
        processingMessage: productName.isNotEmpty
            ? 'Product found. Please verify the details.'
            : 'Barcode found, but product name is unavailable.',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        isProcessing: false,
        errorMessage:
            'Unable to retrieve product information. Please enter it manually.',
        clearProcessingMessage: true,
      ));
    }
  }

  String? _mapCategory(String categories) {
    final value = categories.toLowerCase();

    if (value.contains('dairy')) return 'Dairy';

    if (value.contains('beverage') ||
        value.contains('drink')) {
      return 'Beverages';
    }

    if (value.contains('food')) return 'Food';

    return null;
  }

  // ---------------------------------------------------------
  // SAVE PRODUCT TO FIRESTORE
  // ---------------------------------------------------------

  Future<void> addProduct() async {
    if (state.status == AddProductStatus.loading ||
        state.isProcessing) {
      return;
    }

    final name = state.name.trim();
    final quantity = int.tryParse(state.quantity.trim());
    final expiryDate = state.expiryDate;

    if (name.isEmpty) {
      _fail('Please enter a product name.');
      return;
    }

    if (quantity == null || quantity < 1) {
      _fail(
        'Quantity must be a whole number greater than zero.',
      );
      return;
    }

    if (expiryDate == null) {
      _fail('Please select an expiry date.');
      return;
    }

    emit(state.copyWith(
      status: AddProductStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final now = DateTime.now();

      final product = Product(
        id: '',
        userId: '',
        name: name,
        category: state.category,
        quantity: quantity,
        expiryDate: DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
        ),
        barcode: _optionalValue(state.barcode),
        notes: _optionalValue(state.notes),
        createdAt: now,
        updatedAt: now,
      );

      await _repository.addProduct(product);

      emit(state.copyWith(
        status: AddProductStatus.success,
        successMessage: 'Product added successfully.',
        clearError: true,
      ));
    } catch (error) {
      final message = error is AppException
          ? error.message
          : 'Unable to save the product. Please try again.';

      emit(state.copyWith(
        status: AddProductStatus.failure,
        errorMessage: message,
        clearSuccess: true,
      ));
    }
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _fail(String message) {
    emit(state.copyWith(
      status: AddProductStatus.failure,
      errorMessage: message,
      clearSuccess: true,
    ));
  }

  void reset() {
    nameController.clear();
    barcodeController.clear();
    emit(const AddProductState());
  }

  @override
  Future<void> close() {
    nameController.dispose();
    barcodeController.dispose();
    return super.close();
  }
}
