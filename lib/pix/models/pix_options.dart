class PixOptions {
  final String name;
  final String key;
  final String city;
  final double? amount;
  final String? description;
  final String transactionId;

  PixOptions({
    required this.name,
    required this.key,
    required this.city,
    this.amount,
    this.description,
    this.transactionId = "***",
  });
}
