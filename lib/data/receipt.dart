import 'package:ebon_tracker/data/product.dart';
import 'package:ebon_tracker/data/attachment.dart';

class Receipt {
  final String id;
  final int timestamp;
  final List<Product> expenses;

  const Receipt({
    required this.id,
    required this.timestamp,
    required this.expenses,
  });
}

class FailedReceipt {
  final Attachment attachment;
  final List<String> errors;

  const FailedReceipt({
    required this.attachment,
    required this.errors,
  });
}
