class Receipt {
  final String id;
  final int timestamp;
  final double total;

  const Receipt({
    required this.id,
    required this.timestamp,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'timestamp': timestamp, 'total': total};
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      total: map['total'] ?? .0,
    );
  }
}
