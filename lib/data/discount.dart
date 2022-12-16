class Discount {
  final String messageId;
  final String name;
  final double value;

  const Discount({
    required this.messageId,
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toMap() =>
      {'messageId': messageId, 'name': name, 'value': value};

  factory Discount.fromMap(Map<String, dynamic> map) => Discount(
        messageId: map['messageId'] ?? '',
        name: map['name'] ?? '',
        value: map['value'] ?? .0,
      );
}
