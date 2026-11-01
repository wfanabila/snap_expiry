
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerView extends StatelessWidget {
  const BarcodeScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcode =
                  capture.barcodes.firstOrNull?.rawValue;

              if (barcode != null && barcode.isNotEmpty) {
                Navigator.of(context).pop(barcode);
              }
            },
          ),

          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Text(
              'Position the barcode inside the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
