import 'package:equatable/equatable.dart';

class EditorState extends Equatable {
  final String input;
  final String? amount;
  final String? output;
  final String? error;
  const EditorState({this.input = '', this.amount, this.output, this.error});
  EditorState copyWith({
    String? input,
    String? amount,
    String? output,
    String? error,
  }) => EditorState(
    input: input ?? this.input,
    amount: amount ?? this.amount,
    output: output,
    error: error,
  );
  @override
  List<Object?> get props => [input, amount, output, error];
}
