class Discount {
  final String messageId;
  final String name;
  final double value;

  const Discount({
    required this.messageId,
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {'messageId': messageId, 'name': name, 'value': value};
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      messageId: map['messageId'] ?? '',
      name: map['name'] ?? '',
      value: map['value'] ?? .0,
    );
  }
}
