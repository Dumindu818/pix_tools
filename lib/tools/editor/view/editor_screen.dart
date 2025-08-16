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

  final Color violet = const Color(0xFF5e17eb);
  final Color lightViolet = const Color(0xFFd7c4ff);

  @override
  void dispose() {
    _scrollController.dispose();
    _inputCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool _isValidPixBrCode(String value) {
    if (value.isEmpty) return false;
    final normalized = value.trim().toUpperCase();
    return normalized.startsWith("000201") &&
        normalized.contains("BR.GOV.BCB.PIX") &&
        normalized.length > 20;
  }

  Future<void> _scanCamera() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const QrScannerPage()));
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
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No QR found in image')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Decode failed: $e')));
      }
    } finally {
      barcodeScanner.close();
    }
  }

  Future<void> _copyOutput(String? code) async {
    FocusScope.of(context).unfocus();
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('BR code copied')));
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

      await Share.shareXFiles([XFile(file.path)], text: 'Here is my Pix QR Code');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  void _onUpdatePressed() {
    FocusScope.of(context).unfocus();
    final input = _inputCtrl.text.trim();

    if (_isValidPixBrCode(input)) {
      context.read<EditorBloc>().add(const EditorUpdatePressed());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Pix BR Code. Please try again.')),
      );
      if (_inputCtrl.text.isNotEmpty) _inputCtrl.clear();
    }
  }

  Future<void> _onPastePressed() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() => _inputCtrl.text = data.text!);
      context.read<EditorBloc>().add(EditorSetInput(data.text!));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
    }
  }

  void _onClearPressed() {
    setState(() => _inputCtrl.clear());
    context.read<EditorBloc>().add(const EditorSetInput(''));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white, // ✅ Set screen background to white
        body: BlocConsumer<EditorBloc, EditorState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!)));
            }

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
                  // --- Input Section ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightViolet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lightViolet),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pix BR Code Editor',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: violet,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // BR Code Input + Paste/Clear
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Enter BR Code (or scan/pick)',
                                  labelStyle: TextStyle(color: violet),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: violet),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: lightViolet),
                                  ),
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                ),
                                onChanged: (v) =>
                                    context.read<EditorBloc>().add(EditorSetInput(v)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  tooltip: "Paste",
                                  icon: Icon(Icons.paste, color: violet),
                                  onPressed: _onPastePressed,
                                ),
                                const SizedBox(height: 8),
                                IconButton(
                                  tooltip: "Clear",
                                  icon: Icon(Icons.clear, color: violet),
                                  onPressed: _onClearPressed,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 🔹 Scan & Decode buttons (same row, below BR input, above amount)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: violet,
                                  side: BorderSide(color: lightViolet, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // less horizontal padding
                                ),
                                onPressed: _scanCamera,
                                icon: const Icon(Icons.photo_camera),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Scan with Camera'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: violet,
                                  side: BorderSide(color: lightViolet, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                ),
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Decode from Image'),
                                ),
                              ),
                            ),
                          ],
                        ),


                        const SizedBox(height: 12),

                        // Amount input
                        TextField(
                          controller: _amountCtrl,
                          keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'New Amount in BRL (leave blank for dynamic)',
                            labelStyle: TextStyle(color: violet),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: violet),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: lightViolet),
                            ),
                          ),
                          onChanged: (v) => context
                              .read<EditorBloc>()
                              .add(EditorSetAmount(v.isEmpty ? null : v)),
                        ),

                        const SizedBox(height: 12),

                        // Update button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: violet,
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                          onPressed: _onUpdatePressed,
                          icon: const Icon(Icons.update),
                          label: const Text('Update BR Code'),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 16),

                  // --- Output Section ---
                  if (state.output != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightViolet.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: lightViolet),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Updated BR Code:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: violet),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: lightViolet.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: lightViolet),
                            ),
                            child: SelectableText(
                              state.output!,
                              maxLines: 4,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _copyOutput(state.output),
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy BR Code'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: lightViolet,
                                    foregroundColor: violet,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _shareQr,
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share QR Code'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: lightViolet,
                                    foregroundColor: violet,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: RepaintBoundary(
                                key: _qrKey,
                                child: QrImageView(
                                  data: state.output!,
                                  version: QrVersions.auto,
                                  size: 220,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
