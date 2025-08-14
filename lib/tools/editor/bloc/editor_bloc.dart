import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/emv_utils.dart';
import 'editor_event.dart';
import 'editor_state.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  EditorBloc() : super(const EditorState()) {
    on<EditorSetInput>(
      (e, emit) => emit(state.copyWith(input: e.input, error: null)),
    );
    on<EditorSetAmount>(
      (e, emit) => emit(state.copyWith(amount: e.amount, error: null)),
    );
    on<EditorSetFromQr>(
      (e, emit) => emit(state.copyWith(input: e.value, error: null)),
    );
    on<EditorUpdatePressed>(_onUpdate);
  }

  void _onUpdate(EditorUpdatePressed event, Emitter<EditorState> emit) {
    try {
      var br = state.input.trim();
      if (br.isEmpty) throw Exception('Please enter a BR code.');
      // remove CRC if present
      final idx = br.indexOf('6304');
      if (idx != -1) {
        br = br.substring(0, idx);
      }
      final fields = EmvUtils.parseToMap(br);
      final newAmount = state.amount?.trim();
      if (newAmount != null && newAmount.isNotEmpty) {
        fields['54'] = newAmount;
      } else {
        fields.remove('54'); // dynamic
      }
      // add CRC placeholder 63 04 0000
      fields['63'] = '0000';
      final base = EmvUtils.buildFromMap(fields);
      final checksum = EmvUtils.crc16(base);
      final updated = base.substring(0, base.length - 4) + checksum;
      emit(state.copyWith(output: updated, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
