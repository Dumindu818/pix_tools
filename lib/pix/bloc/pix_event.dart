import '../models/pix_options.dart';

abstract class PixEvent {}

class PixGeneratePressed extends PixEvent {
  final PixOptions options;
  PixGeneratePressed({required this.options});
}
