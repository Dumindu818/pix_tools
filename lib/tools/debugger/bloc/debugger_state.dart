import 'package:equatable/equatable.dart';

class DebuggerState extends Equatable {
  final String raw;
  final List<Map<String, dynamic>> parsed;
  final String? error;
  const DebuggerState({this.raw = '', this.parsed = const [], this.error});
  DebuggerState copyWith({
    String? raw,
    List<Map<String, dynamic>>? parsed,
    String? error,
  }) => DebuggerState(
    raw: raw ?? this.raw,
    parsed: parsed ?? this.parsed,
    error: error,
  );
  @override
  List<Object?> get props => [raw, parsed, error];
}
