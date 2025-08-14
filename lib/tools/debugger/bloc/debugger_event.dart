import 'package:equatable/equatable.dart';

abstract class DebuggerEvent extends Equatable {
  const DebuggerEvent();
  @override
  List<Object?> get props => [];
}

class DebuggerSetInput extends DebuggerEvent {
  final String input;
  const DebuggerSetInput(this.input);
  @override
  List<Object?> get props => [input];
}

class DebuggerParse extends DebuggerEvent {
  const DebuggerParse();
}

class DebuggerSetFromQr extends DebuggerEvent {
  final String input;
  const DebuggerSetFromQr(this.input);
  @override
  List<Object?> get props => [input];
}
