import 'attachment.dart';
import 'discount.dart';
import 'expense.dart';

class Receipt {
  final Attachment attachment;
  final List<Expense> expenses;
  final List<Discount> discounts;

  const Receipt(
      {required this.attachment,
      required this.expenses,
      required this.discounts});
}

class FailedReceipt {
  final Attachment attachment;
  final String error;

  const FailedReceipt({
    required this.attachment,
    required this.error,
  });
}
