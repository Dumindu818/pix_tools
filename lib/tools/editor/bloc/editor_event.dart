import 'package:equatable/equatable.dart';

abstract class EditorEvent extends Equatable {
  const EditorEvent();
  @override
  List<Object?> get props => [];
}

class EditorSetInput extends EditorEvent {
  final String input;
  const EditorSetInput(this.input);
  @override
  List<Object?> get props => [input];
}

class EditorSetAmount extends EditorEvent {
  final String? amount;
  const EditorSetAmount(this.amount);
  @override
  List<Object?> get props => [amount];
}

class EditorUpdatePressed extends EditorEvent {
  const EditorUpdatePressed();
}

class EditorSetFromQr extends EditorEvent {
  final String value;
  const EditorSetFromQr(this.value);
  @override
  List<Object?> get props => [value];
}
