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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PixBloc(),
      child: BlocConsumer<PixBloc, PixState>(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField('Name', _nameController),
                _buildField('Pix Key', _keyController),
                _buildField('City', _cityController),
                _buildField(
                  'Amount (optional)',
                  _amountController,
                  isNumber: true,
                ),
                _buildField('Description (optional)', _descController),
                _buildField('Transaction ID (optional)', _txidController),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
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
                        label: const Text('Share / Download'),
                        onPressed: () async {
                          try {
                            final boundary =
                                globalKey.currentContext!.findRenderObject()
                                    as RenderRepaintBoundary?;
                            if (boundary != null) {
                              final image = await boundary.toImage(
                                pixelRatio: 3,
                              );
                              final byteData = await image.toByteData(
                                format: ui.ImageByteFormat.png,
                              );
                              final bytes = byteData!.buffer.asUint8List();
                              final dir = await getTemporaryDirectory();
                              final file = File('${dir.path}/pix_qr.png');
                              await file.writeAsBytes(bytes);
                              await Share.shareXFiles([XFile(file.path)]);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
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
}
