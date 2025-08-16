import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/scanner/qr_scanner_page.dart';
import '../bloc/editor_bloc.dart';
import '../bloc/editor_event.dart';
import '../bloc/editor_state.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _inputCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _qrKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// --- Pix BR Code validation ---
  bool _isValidPixBrCode(String value) {
    if (value.isEmpty) return false;

    final normalized = value.trim().toUpperCase();

    return normalized.startsWith("000201") &&
        normalized.contains("BR.GOV.BCB.PIX") &&
        normalized.length > 20;
  }

  Future<void> _scanCamera() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerPage()));
    if (result != null && mounted) {
      _inputCtrl.text = result;
      context.read<EditorBloc>().add(EditorSetFromQr(result));
    }
  }

  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus();
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    final inputImage = InputImage.fromFilePath(xfile.path);
    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);

    try {
      final barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final qrValue = barcodes.first.rawValue ?? '';
        _inputCtrl.text = qrValue;
        context.read<EditorBloc>().add(EditorSetFromQr(qrValue));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No QR found in image')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Decode failed: $e')));
    } finally {
      barcodeScanner.close();
    }
  }

  Future<void> _copyOutput(String? code) async {
    FocusScope.of(context).unfocus();
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('BR code copied')));
  }

  Future<void> _shareQr() async {
    FocusScope.of(context).unfocus();
    if (_qrKey.currentContext == null) return;
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/shared_brcode_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Here is my Pix QR Code');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  /// --- Update BR Code with validation ---
  void _onUpdatePressed() {
    FocusScope.of(context).unfocus();
    final input = _inputCtrl.text.trim();

    if (_isValidPixBrCode(input)) {
      context.read<EditorBloc>().add(const EditorUpdatePressed());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Pix BR Code. Please try again.')),
      );
      if (_inputCtrl.text.isNotEmpty) {
        _inputCtrl.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocConsumer<EditorBloc, EditorState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }

          // ✅ Scroll to bottom when QR code is generated
          if (state.output != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            });
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pix BR Code Editor',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _inputCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Enter BR Code (or scan/pick)',
                  ),
                  onChanged: (v) =>
                      context.read<EditorBloc>().add(EditorSetInput(v)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'New Amount in BRL(leave blank for dynamic)',
                  ),
                  onChanged: (v) => context.read<EditorBloc>().add(
                    EditorSetAmount(v.isEmpty ? null : v),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _onUpdatePressed,
                      icon: const Icon(Icons.update),
                      label: const Text('Update BR Code'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _scanCamera,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Scan with Camera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Decode from Image'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.output != null) ...[
                  const Text('Updated BR Code:'),
                  const SizedBox(height: 6),
                  SelectableText(
                    state.output!,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _copyOutput(state.output),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy BR Code'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _shareQr,
                        icon: const Icon(Icons.share),
                        label: const Text('Share QR Code'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        child: QrImageView(
                          data: state.output!,
                          version: QrVersions.auto,
                          size: 220,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
