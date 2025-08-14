import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/pix_options.dart';
import 'pix_event.dart';
import 'pix_state.dart';

class PixBloc extends Bloc<PixEvent, PixState> {
  PixBloc() : super(const PixState()) {
    on<PixGeneratePressed>(_onGenerate);
  }

  void _onGenerate(PixGeneratePressed event, Emitter<PixState> emit) {
    try {
      final code = _generatePixCode(event.options);
      emit(state.copyWith(pixCode: code, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  String _formatField(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }

  String _generatePixCode(PixOptions o) {
    if (o.name.isEmpty || o.key.isEmpty || o.city.isEmpty) {
      throw Exception('Name, Pix Key, and City are required.');
    }

    String payload = '';
    payload += _formatField('00', '01');

    String merchantInfo = _formatField('00', 'BR.GOV.BCB.PIX');
    merchantInfo += _formatField('01', o.key);
    if (o.description != null && o.description!.isNotEmpty) {
      merchantInfo += _formatField('02', o.description!);
    }
    payload += _formatField('26', merchantInfo);
    payload += _formatField('52', '0000');
    payload += _formatField('53', '986');

    if (o.amount != null) {
      payload += _formatField('54', o.amount!.toStringAsFixed(2));
    }

    payload += _formatField('58', 'BR');
    payload += _formatField(
      '59',
      o.name.substring(0, o.name.length.clamp(0, 25)),
    );
    payload += _formatField(
      '60',
      o.city.substring(0, o.city.length.clamp(0, 15)),
    );

    final additional = _formatField('05', o.transactionId);
    payload += _formatField('62', additional);

    final payloadWithCrc = '${payload}6304';
    final crc = _crc16(Uint8List.fromList(payloadWithCrc.codeUnits));
    return '$payloadWithCrc$crc';
  }

  String _crc16(Uint8List data) {
    int crc = 0xFFFF;
    const int poly = 0x1021;
    for (final byte in data) {
      crc ^= byte << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ poly;
        } else {
          crc <<= 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
