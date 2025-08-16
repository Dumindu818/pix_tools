import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
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

  final Color violet = const Color(0xFF5e17eb);
  final Color lightViolet = const Color(0xFFd7c4ff);

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
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocProvider(
        create: (_) => PixBloc(),
        child: BlocConsumer<PixBloc, PixState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!)));
            }

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
            return Scaffold(
              backgroundColor: Colors.white,
              body: SingleChildScrollView(
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
                            'Pix QR Generator',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: violet,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          _buildField('Name', _nameController),
                          _buildPixKeyField('Pix Key', _keyController),
                          _buildField('City', _cityController),
                          _buildField('Amount in BRL (optional)', _amountController,
                              isNumber: true),
                          _buildField('Description (optional)', _descController),
                          _buildField('Transaction ID (optional)', _txidController),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: lightViolet,
                                    foregroundColor: violet,
                                  ),
                                  onPressed: _clearAllFields,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: violet,
                                    foregroundColor: Colors.white,
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
                                    context
                                        .read<PixBloc>()
                                        .add(PixGeneratePressed(options: options));
                                  },
                                  child: const Text('Generate QR Code'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Output Section ---
                    if (state.pixCode != null)
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
                              'Pix BR Code:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: violet),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: lightViolet.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: lightViolet),
                              ),
                              child: SelectableText(state.pixCode!),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Copy'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: lightViolet,
                                      foregroundColor: violet,
                                    ),
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      Clipboard.setData(
                                          ClipboardData(text: state.pixCode!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Copied!')),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: lightViolet,
                                      foregroundColor: violet,
                                    ),
                                    onPressed: () => _shareQr(state.pixCode!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                                  key: globalKey,
                                  child: QrImageView(
                                    data: state.pixCode!,
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType:
        isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: violet),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: violet),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: lightViolet),
          ),
        ),
      ),
    );
  }

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
                labelStyle: TextStyle(color: violet),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: violet),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: lightViolet),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.paste, color: violet),
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

      await Share.shareXFiles([XFile(file.path)], text: 'Here is my Pix QR Code');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }
}
