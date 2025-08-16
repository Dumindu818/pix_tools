import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import '../../../shared/scanner/qr_scanner_page.dart';
import '../bloc/debugger_bloc.dart';
import '../bloc/debugger_event.dart';
import '../bloc/debugger_state.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class DebuggerScreen extends StatefulWidget {
  const DebuggerScreen({super.key});
  @override
  State<DebuggerScreen> createState() => _DebuggerScreenState();
}

class _DebuggerScreenState extends State<DebuggerScreen> {
  final _inputCtrl = TextEditingController();

  /// --- Pix BR Code validation ---
  bool _isValidPixBrCode(String value) {
    if (value.isEmpty) return false;

    final normalized = value.trim().toUpperCase();

    return normalized.startsWith("000201") &&
        normalized.contains("BR.GOV.BCB.PIX") &&
        normalized.length > 20; // crude min length
  }

  Future<void> _scanCamera() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerPage()));
    if (result != null && mounted) {
      _inputCtrl.text = result;
      context.read<DebuggerBloc>().add(DebuggerSetFromQr(result));
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
        context.read<DebuggerBloc>().add(DebuggerSetFromQr(qrValue));
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

  void _onParsePressed() {
    FocusScope.of(context).unfocus();
    final input = _inputCtrl.text.trim();

    if (_isValidPixBrCode(input)) {
      context.read<DebuggerBloc>().add(const DebuggerParse());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Pix BR Code. Please try again.')),
      );
      if (_inputCtrl.text.isNotEmpty) {
        _inputCtrl.clear();
      }
    }
  }

  Future<void> _onPastePressed() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _inputCtrl.text = data.text!;
      });
      context.read<DebuggerBloc>().add(DebuggerSetInput(data.text!));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
    }
  }

  void _onClearPressed() {
    setState(() {
      _inputCtrl.clear();
    });
    context.read<DebuggerBloc>().add(const DebuggerSetInput(''));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: BlocConsumer<DebuggerBloc, DebuggerState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pix BR Code Debugger',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Enter Pix BR Code',
                          hintText: 'Paste code or scan',
                        ),
                        onChanged: (v) => context.read<DebuggerBloc>().add(
                          DebuggerSetInput(v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: "Paste",
                      icon: const Icon(Icons.paste),
                      onPressed: _onPastePressed,
                    ),
                    IconButton(
                      tooltip: "Clear",
                      icon: const Icon(Icons.clear),
                      onPressed: _onClearPressed,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _onParsePressed,
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text('Parse BR Code'),
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
                Expanded(
                  child: state.parsed.isEmpty
                      ? const Center(
                          child: Text('Parsed fields will appear here'),
                        )
                      : _ParsedTable(rows: state.parsed),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ParsedTable extends StatelessWidget {
  const _ParsedTable({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('EMV Name')),
              DataColumn(label: Text('Size')),
              DataColumn(label: Text('Data')),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  cells: [
                    DataCell(Text(r['id'].toString())),
                    DataCell(Text((r['emvName'] ?? '') as String)),
                    DataCell(Text(r['size'].toString())),
                    DataCell(
                      GestureDetector(
                        onDoubleTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: (r['value'] ?? '').toString()),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Data copied')),
                            );
                          }
                        },
                        child: SelectableText(
                          (r['value'] ?? '').toString(),
                          maxLines: 3,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
