import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../../../shared/scanner/qr_scanner_page.dart';
import '../bloc/debugger_bloc.dart';
import '../bloc/debugger_event.dart';
import '../bloc/debugger_state.dart';

class DebuggerScreen extends StatefulWidget {
  const DebuggerScreen({super.key});

  @override
  State<DebuggerScreen> createState() => _DebuggerScreenState();
}

class _DebuggerScreenState extends State<DebuggerScreen> {
  final _inputCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Color violet = const Color(0xFF5e17eb);
  final Color lightViolet = const Color(0xFFd7c4ff);

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
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No QR found in image')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Decode failed: $e')));
      }
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
        const SnackBar(content: Text('Invalid PIX BR Code. Please try again.')),
      );
      if (_inputCtrl.text.isNotEmpty) _inputCtrl.clear();
    }
  }

  Future<void> _onPastePressed() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() => _inputCtrl.text = data.text!);
      context.read<DebuggerBloc>().add(DebuggerSetInput(data.text!));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
    }
  }

  void _onClearPressed() {
    setState(() => _inputCtrl.clear());
    context.read<DebuggerBloc>().add(const DebuggerSetInput(''));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocConsumer<DebuggerBloc, DebuggerState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
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
                          'PIX BR Code Decoder',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: violet,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TextField
                            Expanded(
                              child: TextField(
                                controller: _inputCtrl,
                                maxLines: 3,
                                style: TextStyle(color: violet), // 👈 input text will be violet
                                decoration: InputDecoration(
                                  labelText: 'Enter BR Code (or scan/pick)',
                                  labelStyle: TextStyle(color: violet),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: violet),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: lightViolet),
                                  ),
                                  hintText: 'Paste code or scan',
                                  hintStyle: TextStyle(color: violet.withOpacity(0.6)), // optional
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                ),
                                onChanged: (v) =>
                                    context.read<DebuggerBloc>().add(DebuggerSetInput(v)),
                              ),
                            ),

                            const SizedBox(width: 8),
                            // Paste + Clear buttons stacked vertically
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
                        const SizedBox(height: 16),

                        // Camera + Decode buttons in SAME horizontal line
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: violet,
                                  side: BorderSide(
                                    color: lightViolet,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                ),
                                onPressed: _scanCamera,
                                icon: const Icon(Icons.photo_camera),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Scan with Camera',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: violet,
                                  side: BorderSide(
                                    color: lightViolet,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                ),
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Decode from Image',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Parse button BELOW those 2
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: violet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          onPressed: _onParsePressed,
                          icon: const Icon(Icons.playlist_add_check),
                          label: const Text('Parse BR Code'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Output Section ---
                  Expanded(
                    child: state.parsed.isEmpty
                        ? Center(
                      child: Text(
                        'Parsed fields will appear here',
                        style: TextStyle(color: violet),
                      ),
                    )
                        : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightViolet.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: lightViolet),
                      ),
                      child: _ParsedTable(rows: state.parsed, violet: violet),
                    ),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ParsedTable extends StatelessWidget {
  const _ParsedTable({required this.rows, required this.violet});
  final List<Map<String, dynamic>> rows;
  final Color violet;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dividerThickness: 1.2,
            headingRowColor: WidgetStateProperty.all(violet.withOpacity(0.1)),
            dataRowColor: WidgetStateProperty.all(Colors.white),
            border: TableBorder(
              horizontalInside: BorderSide(color: violet, width: 0.8),
              verticalInside: BorderSide(color: violet, width: 0.8),
              top: BorderSide(color: violet, width: 1),
              bottom: BorderSide(color: violet, width: 1),
              left: BorderSide(color: violet, width: 1),
              right: BorderSide(color: violet, width: 1),
            ),
            columns: [
              DataColumn(
                label: Text(
                  'ID',
                  style: TextStyle(fontWeight: FontWeight.bold, color: violet),
                ),
              ),
              DataColumn(
                label: Text(
                  'EMV Name',
                  style: TextStyle(fontWeight: FontWeight.bold, color: violet),
                ),
              ),
              DataColumn(
                label: Text(
                  'Size',
                  style: TextStyle(fontWeight: FontWeight.bold, color: violet),
                ),
              ),
              DataColumn(
                label: Text(
                  'Data',
                  style: TextStyle(fontWeight: FontWeight.bold, color: violet),
                ),
              ),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        r['id'].toString(),
                        style: TextStyle(color: violet),
                      ),
                    ),
                    DataCell(
                      Text(
                        (r['emvName'] ?? '') as String,
                        style: TextStyle(color: violet),
                      ),
                    ),
                    DataCell(
                      Text(
                        r['size'].toString(),
                        style: TextStyle(color: violet),
                      ),
                    ),
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
                          style: TextStyle(color: violet),
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

