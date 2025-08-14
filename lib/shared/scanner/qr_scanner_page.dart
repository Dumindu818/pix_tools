import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});
  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _locked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_locked) return;
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final v = barcodes.first.rawValue;
            if (v != null && v.isNotEmpty) {
              _locked = true;
              Navigator.of(context).pop(v);
            }
          }
        },
      ),
    );
  }
}
