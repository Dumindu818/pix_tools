class PixState {
  final String? pixCode;
  final String? error;

  const PixState({this.pixCode, this.error});

  PixState copyWith({String? pixCode, String? error}) {
    return PixState(
      pixCode: pixCode ?? this.pixCode,
      error: error ?? this.error,
    );
  }
}
