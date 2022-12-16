import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';

class Attachment {
  final String id;
  final int timestamp;
  final String content;
  final Option<double> total;

  const Attachment({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.total,
  });

  Attachment withTotal(double total) => Attachment(
      id: id, timestamp: timestamp, content: content, total: Some(total));

  // Convert a Breed into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp,
        'content': content,
        'total': total.toNullable()
      };

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
        id: map['id'] ?? '',
        timestamp: map['timestamp'] ?? 0,
        content: map['content'] ?? '',
        total: optionOf(map['total']),
      );

  Uint8List byteArrayContent() => Uint8List.fromList(base64.decode(content));

  String toJson() => json.encode(toMap());

  factory Attachment.fromJson(String source) =>
      Attachment.fromMap(json.decode(source));

  // Implement toString to make it easier to see information about
  // each breed when using the print statement.
  @override
  String toString() =>
      'Attachment(id: $id, timestamp: $timestamp, total: $total)';
}
