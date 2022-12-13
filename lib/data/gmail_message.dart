import 'dart:convert';

class Attachment {
  final String id;
  final int timestamp;
  final String content;

  const Attachment({
    required this.id,
    required this.timestamp,
    required this.content,
  });

  // Convert a Breed into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {'id': id, 'timestamp': timestamp, 'content': content};
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      content: map['content'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Attachment.fromJson(String source) =>
      Attachment.fromMap(json.decode(source));

  // Implement toString to make it easier to see information about
  // each breed when using the print statement.
  @override
  String toString() => 'Attachment(id: $id, timestamp: $timestamp)';
}
