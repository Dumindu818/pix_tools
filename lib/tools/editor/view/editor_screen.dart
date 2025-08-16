import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart'; // ✅ for sharing
import '../../../shared/scanner/qr_scanner_page.dart';
import '../bloc/editor_bloc.dart';
import '../bloc/editor_event.dart';
import '../bloc/editor_state.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _inputCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _qrKey = GlobalKey();

  Future<void> _scanCamera() async {
    FocusScope.of(context).unfocus(); // hide keyboard
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerPage()));
    if (result != null && mounted) {
      _inputCtrl.text = result;
      context.read<EditorBloc>().add(EditorSetFromQr(result));
    }
  }

  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus(); // hide keyboard
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    try {
      final content = await QrCodeToolsPlugin.decodeFrom(xfile.path);
      if (content != null) {
        _inputCtrl.text = content;
        context.read<EditorBloc>().add(EditorSetFromQr(content));
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
    }
  }

  Future<void> _copyOutput(String? code) async {
    FocusScope.of(context).unfocus(); // hide keyboard
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('BR code copied')));
  }

  /// ✅ New: Share QR code instead of download
  Future<void> _shareQr() async {
    FocusScope.of(context).unfocus(); // hide keyboard
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

      /// ✅ Share the QR code image
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // hide keyboard on background tap
      },
      child: BlocConsumer<EditorBloc, EditorState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
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
                    labelText: 'New Amount (leave blank for dynamic)',
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
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // hide keyboard
                        context.read<EditorBloc>().add(
                          const EditorUpdatePressed(),
                        );
                      },
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
                  Text('Updated BR Code:'),
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

                      /// ✅ Changed Download → Share
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
                        color: Colors.white, // ✅ white bg for sharing
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
