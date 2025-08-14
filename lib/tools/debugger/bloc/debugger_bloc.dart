import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/emv_utils.dart';
import 'debugger_event.dart';
import 'debugger_state.dart';

class DebuggerBloc extends Bloc<DebuggerEvent, DebuggerState> {
  DebuggerBloc() : super(const DebuggerState()) {
    on<DebuggerSetInput>(
      (e, emit) => emit(state.copyWith(raw: e.input, error: null)),
    );
    on<DebuggerSetFromQr>(
      (e, emit) => emit(state.copyWith(raw: e.input, error: null)),
    );
    on<DebuggerParse>(_onParse);
  }
  void _onParse(DebuggerParse event, Emitter<DebuggerState> emit) {
    try {
      String raw = state.raw.trim();
      if (raw.isEmpty) throw Exception('Please provide a Pix BR Code.');
      // strip CRC suffix if present to avoid double parsing errors? Keep as-is for display
      final parsed = EmvUtils.parseEmv(raw);
      emit(state.copyWith(parsed: parsed, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
