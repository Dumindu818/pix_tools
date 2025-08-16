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

class DebuggerScreen extends StatefulWidget {
  const DebuggerScreen({super.key});
  @override
  State<DebuggerScreen> createState() => _DebuggerScreenState();
}

class _DebuggerScreenState extends State<DebuggerScreen> {
  final _inputCtrl = TextEditingController();

  Future<void> _scanCamera() async {
    FocusScope.of(context).unfocus(); // Hide keyboard before opening scanner
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerPage()));
    if (result != null && mounted) {
      _inputCtrl.text = result;
      context.read<DebuggerBloc>().add(DebuggerSetFromQr(result));
    }
  }

  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus(); // Hide keyboard before picking image
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    try {
      final content = await QrCodeToolsPlugin.decodeFrom(xfile.path);
      if (content != null) {
        _inputCtrl.text = content;
        context.read<DebuggerBloc>().add(DebuggerSetFromQr(content));
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide keyboard on background tap
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
                TextField(
                  controller: _inputCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Enter Pix BR Code',
                    hintText: 'Paste code or scan',
                  ),
                  onChanged: (v) =>
                      context.read<DebuggerBloc>().add(DebuggerSetInput(v)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // Hide keyboard
                        context.read<DebuggerBloc>().add(const DebuggerParse());
                      },
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
