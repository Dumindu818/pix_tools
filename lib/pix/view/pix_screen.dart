import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import '../bloc/pix_bloc.dart';
import '../bloc/pix_event.dart';
import '../bloc/pix_state.dart';
import '../models/pix_options.dart';

class PixScreen extends StatefulWidget {
  const PixScreen({Key? key}) : super(key: key);

  @override
  _PixScreenState createState() => _PixScreenState();
}

class _PixScreenState extends State<PixScreen> {
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  final _cityController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _txidController = TextEditingController();

  final GlobalKey globalKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _keyController.dispose();
    _cityController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _txidController.dispose();
    super.dispose();
  }

  void _clearAllFields() {
    _nameController.clear();
    _keyController.clear();
    _cityController.clear();
    _amountController.clear();
    _descController.clear();
    _txidController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: BlocProvider(
        create: (_) => PixBloc(),
        child: BlocConsumer<PixBloc, PixState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
            }

            // Scroll to bottom when QR code is generated
            if (state.pixCode != null) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pix QR Generator',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildField('Name', _nameController),
                  _buildPixKeyField('Pix Key', _keyController),
                  _buildField('City', _cityController),
                  _buildField(
                    'Amount in BRL (optional)',
                    _amountController,
                    isNumber: true,
                  ),
                  _buildField('Description (optional)', _descController),
                  _buildField('Transaction ID (optional)', _txidController),
                  const SizedBox(height: 16),

                  // Clear Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.clear),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _clearAllFields,
                    label: const Text('Clear All Fields'),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimary, // swapped
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.primary, // swapped
                    ),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      final options = PixOptions(
                        name: _nameController.text.trim(),
                        key: _keyController.text.trim(),
                        city: _cityController.text.trim(),
                        amount: _amountController.text.isEmpty
                            ? null
                            : double.tryParse(_amountController.text),
                        description: _descController.text.isEmpty
                            ? null
                            : _descController.text.trim(),
                        transactionId: _txidController.text.isEmpty
                            ? '***'
                            : _txidController.text.trim(),
                      );
                      context.read<PixBloc>().add(
                        PixGeneratePressed(options: options),
                      );
                    },
                    child: const Text('Generate QR Code'),
                  ),
                  const SizedBox(height: 16),
                  if (state.pixCode != null) ...[
                    const Text(
                      'Pix BR Code:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(state.pixCode!),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            Clipboard.setData(
                              ClipboardData(text: state.pixCode!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied!')),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Share QR Code'),
                          onPressed: () => _shareQr(state.pixCode!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: RepaintBoundary(
                        key: globalKey,
                        child: QrImageView(
                          data: state.pixCode!,
                          version: QrVersions.auto,
                          size: 200,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  /// Special Field for Pix Key with Paste option
  Widget _buildPixKeyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.paste),
            tooltip: "Paste",
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null && data.text != null) {
                setState(() {
                  controller.text = data.text!;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _shareQr(String pixCode) async {
    FocusScope.of(context).unfocus();
    try {
      final qrPainter = QrPainter(
        data: pixCode,
        version: QrVersions.auto,
        gapless: true,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final image = await qrPainter.toImage(400);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/shared_pix_qr_${DateTime.now().millisecondsSinceEpoch}.png',
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
}
