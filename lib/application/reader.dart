import 'dart:async';

import 'package:dartz/dartz.dart' hide Unit;
import 'package:ebon_tracker/application/helpers.dart';
import 'package:collection/collection.dart';

import '../data/attachment.dart';
import '../data/discount.dart';
import '../data/expense.dart';
import '../data/pdf.dart';
import '../data/product.dart';
import '../data/quantity.dart';
import '../data/receipt.dart';
import '../data/unit.dart';
import '../redux/attachments/attachments_actions.dart';
import '../redux/attachments/attachments_state.dart';
import '../redux/store.dart';
import 'database_service.dart';

import 'package:syncfusion_flutter_pdf/pdf.dart';

String sanitize(String string) {
  string = string.trim();
  if (string.endsWith(" *")) {
    return string.substring(0, string.length - 2);
  } else {
    return string;
  }
}

Either<Discount, NamedValue> parseEntry(String messageId, String string) {
  int numberIndex = string.substring(0, string.length - 2).lastIndexOf(" ");
  double value = double.parse(string
      .substring(numberIndex + 1, string.length - 2)
      .replaceAll(",", "."));
  String name = string.substring(0, numberIndex).trim();
  if (value < .0) {
    return Left(Discount(messageId: messageId, name: name, value: value));
  } else {
    return Right(NamedValue(name: name, value: value));
  }
}

Tuple2<double, List<Discount>> applyDiscount(
    String name, List<Discount> discounts, List<Discount> left,
    [double applied = .0]) {
  if (discounts.isEmpty) {
    return Tuple2(applied, left);
  } else {
    Discount cur = discounts.removeLast();
    if (cur.name.startsWith("Rabatt") ||
        cur.name.startsWith("Nachtr. Preiskorrekt")) {
      // Discount was applied
      return applyDiscount(name, discounts, left, applied + cur.value);
    } else {
      // Discount was not applied
      left.add(cur);
      return applyDiscount(name, discounts, left, applied);
    }
  }
}

Quantity parseQuantity(String string) {
  List<String> splitted = string.split(" x ");
  if (splitted.length == 2) {
    if (splitted.first.contains("Stk")) {
      double n = double.parse(splitted.first.split("Stk").first.trim());
      double price = double.parse(splitted.last.trim().replaceAll(",", "."));
      return Quantity(n: n, price: price, unit: Unit.none);
    } else if (splitted.first.contains("kg")) {
      double n = double.parse(
          splitted.first.split("kg").first.trim().replaceAll(",", "."));
      double price = double.parse(
          splitted.last.split("EUR/kg").first.trim().replaceAll(",", "."));
      return Quantity(n: n, price: price, unit: Unit.kg);
    } else {
      throw AssertionError(
          "Assumed a quantity of 'kg' or 'Stk' but got: ${splitted.first}");
    }
  } else {
    throw AssertionError(
        "Assumed a quantity line with 'x' separator. Got: $string");
  }
}

class NamedValue {
  final String name;
  final double value;

  const NamedValue({required this.name, required this.value});
}

Either<FailedReceipt, Receipt> consume(double total, Attachment attachment,
    List<String> lines, List<Expense> expenses, List<Discount> discounts,
    [Quantity? quantity]) {
  if (lines.isEmpty) {
    return Right(Receipt(
        attachment: attachment,
        expenses: expenses.reversed.toList(),
        discounts: discounts.reversed.toList()));
  }

  try {
    String sanitized = sanitize(lines.removeLast());
    if (sanitized.endsWith(" B") || sanitized.endsWith(" A")) {
      parseEntry(attachment.id, sanitized)
          .fold((discount) => discounts.add(discount), (namedValue) {
        Tuple2<double, List<Discount>> discounted =
            applyDiscount(namedValue.name, discounts, []);
        discounts = discounted.value2;

        expenses.add(Expense.from(
            attachment.id,
            namedValue.name,
            namedValue.value,
            discounted.value1,
            quantity ??
                Quantity(n: 1, price: namedValue.value, unit: Unit.none)));
      });
      return consume(total, attachment, lines, expenses, discounts);
    } else {
      return consume(total, attachment, lines, expenses, discounts,
          parseQuantity(sanitized));
    }
  } catch (ex) {
    return Left(FailedReceipt(attachment: attachment, error: ex.toString()));
  }
}

Either<FailedReceipt, Receipt> read(Pdf pdf) {
  PdfDocument document = PdfDocument.fromBase64String(pdf.content);
  //Create a new instance of the PdfTextExtractor.
  PdfTextExtractor extractor = PdfTextExtractor(document);

  //Extract all the text from the document.
  List<TextLine> textLines = extractor.extractTextLines();

  document.dispose();

  int first = textLines.indexWhere((element) => element.text.contains("EUR"));
  int last = textLines
      .indexWhere((element) => element.text.contains("--------------"));
  double total = double.parse(
      textLines[last + 1].text.trim().split(" ").last.replaceAll(",", "."));

  List<String> lines =
      textLines.sublist(first + 1, last).map((e) => e.text).toList();

  Attachment attachment = Attachment(
      id: pdf.id, timestamp: pdf.timestamp, content: pdf.content, total: total);

  return consume(total, attachment, lines, [], []);
}

typedef EitherReceipt = Either<FailedReceipt, Receipt>;

Future<Iterable<EitherReceipt>> insertReceipts(Iterable<Pdf> pdfs) async {
  Iterable<Either<FailedReceipt, Receipt>> readResult = pdfs.map(read);

  Iterable<Receipt> receipts = readResult.rights();

  if (receipts.isNotEmpty) {
    await AttachmentsDb.insert(receipts.map((e) => e.attachment));
    final expenses = receipts.map((e) => e.expenses).flattened;
    await ProductsDb.insert(expenses.map((e) => Product(name: e.name)));
    await ExpensesDb.insert(expenses);
    await DiscountsDb.insert(receipts.map((e) => e.discounts).flattened);
    Iterable<Attachment> unchanged =
        Redux.store.state.attachmentsState.attachments.where((element) =>
            receipts.where((r) => r.attachment.id == element.id).isEmpty);
    List<Attachment> attachments = [
      ...unchanged,
      ...receipts.map((e) => e.attachment)
    ];
    attachments.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    Redux.store.dispatch(
        SetAttachmentsStateAction(AttachmentsState(attachments: attachments)));
  }

  return readResult;
}
