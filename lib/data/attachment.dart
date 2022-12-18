import 'dart:convert';
import 'dart:typed_data';

class Attachment {
  final String id;
  final int timestamp;
  final String content;
  final double total;

  const Attachment({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.total,
  });

  // Convert a Breed into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() =>
      {'id': id, 'timestamp': timestamp, 'content': content, 'total': total};

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
        id: map['id'] ?? '',
        timestamp: map['timestamp'] ?? 0,
        content: map['content'] ?? '',
        total: map['total'],
      );

  Uint8List byteArrayContent() => Uint8List.fromList(base64.decode(content));

  // Implement toString to make it easier to see information about
  // each breed when using the print statement.
  @override
  String toString() =>
      'Attachment(id: $id, timestamp: $timestamp, total: $total)';
}
