import 'dart:convert';
import 'dart:typed_data';

class Pdf {
  final String id;
  final int timestamp;
  final String content;

  const Pdf({
    required this.id,
    required this.timestamp,
    required this.content,
  });

  Uint8List byteArrayContent() => Uint8List.fromList(base64.decode(content));

  // Implement toString to make it easier to see information about
  // each breed when using the print statement.
  @override
  String toString() => 'PDF(id: $id, timestamp: $timestamp)';
}
