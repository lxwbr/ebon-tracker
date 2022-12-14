import 'dart:async';

import 'package:dartz/dartz.dart';

import '../data/attachment.dart';
import '../data/product.dart';
import '../redux/attachments/attachments_actions.dart';
import '../redux/attachments/attachments_state.dart';
import '../redux/store.dart';
import 'database_service.dart';

import 'package:syncfusion_flutter_pdf/pdf.dart';

String sanitize(String product) {
  product = product.trim();
  if (product.endsWith(" *")) {
    return product.substring(0, product.length - 2);
  } else {
    return product;
  }
}

Entry parseEntry(String string) {
  int numberIndex = string.substring(0, string.length - 2).lastIndexOf(" ");
  double value = double.parse(string
      .substring(numberIndex + 1, string.length - 2)
      .replaceAll(",", "."));
  String name = string.substring(0, numberIndex).trim();
  if (value < .0) {
    return Discount(name, value);
  } else {
    return Expense(name, value);
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
      return Quantity(n: n, price: price, unit: Units.none);
    } else if (splitted.first.contains("kg")) {
      double n = double.parse(
          splitted.first.split("kg").first.trim().replaceAll(",", "."));
      double price = double.parse(
          splitted.last.split("EUR/kg").first.trim().replaceAll(",", "."));
      return Quantity(n: n, price: price, unit: Units.kg);
    } else {
      throw AssertionError(
          "Assumed a quantity of 'kg' or 'Stk' but got: ${splitted.first}");
    }
  } else {
    throw AssertionError(
        "Assumed a quantity line with 'x' separator. Got: $string");
  }
}

abstract class Entry {
  String name;
  double value;
  Entry._({required this.name, required this.value});
}

class Discount extends Entry {
  Discount(name, value) : super._(name: name, value: value);

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      map['name'] ?? '',
      map['value'] ?? 0.0,
    );
  }

  @override
  String toString() {
    return "$name: $value";
  }
}

class Expense extends Entry {
  Expense(name, value) : super._(name: name, value: value);
}

Either<String, Receipt> consume(Attachment attachment, List<String> lines,
    List<Product> products, List<Discount> discounts,
    [Quantity? quantity]) {
  if (lines.isEmpty) {
    return Right(Receipt(
        attachment: attachment,
        expenses: products.reversed.toList(),
        discounts: discounts.reversed.toList()));
  }

  try {
    String sanitized = sanitize(lines.removeLast());
    if (sanitized.endsWith(" B") || sanitized.endsWith(" A")) {
      Entry entry = parseEntry(sanitized);
      if (entry is Discount) {
        discounts.add(entry);
      } else {
        Tuple2<double, List<Discount>> discounted =
            applyDiscount(entry.name, discounts, []);
        discounts = discounted.value2;

        products.add(Product.from(
            attachment.id,
            entry.name,
            entry.value,
            discounted.value1,
            quantity ?? Quantity(n: 1, price: entry.value, unit: Units.none)));
      }
      return consume(attachment, lines, products, discounts);
    } else {
      return consume(
          attachment, lines, products, discounts, parseQuantity(sanitized));
    }
  } catch (ex) {
    return Left(ex.toString());
  }
}

Future<Receipt> read(Attachment attachment) async {
  PdfDocument document = PdfDocument.fromBase64String(attachment.content);
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

  attachment = attachment.withTotal(total);

  return consume(attachment, lines, [], [])
      .fold((l) => Future.error(l), (r) => r);
}

DatabaseService _databaseService = DatabaseService();

extension ListEitherExtension<L, R> on List<Either<L, R>> {
  List<R> rights() => where((e) => e.isRight())
      .map((e) => e.getOrElse(() => throw UnimplementedError()))
      .toList();

  List<L> lefts() => where((e) => e.isLeft())
      .map((e) => e.swap().getOrElse(() => throw UnimplementedError()))
      .toList();
}

Future<Receipt> insertReceipt(Attachment attachment) async {
  // Check if there expenses for this attachment has been scanned in the past
  Attachment? existing = await _databaseService.attachment(attachment.id);

  List<Product> expenses =
      await _databaseService.expensesByMessageId(attachment.id);

  if (expenses.isEmpty || existing == null) {
    Receipt receipt = await read(attachment);

    if (existing == null) {
      await _databaseService.insertAttachment(receipt.attachment);
    } else if (existing.total.isNone()) {
      await _databaseService.updateAttachment(receipt.attachment);
    }
    await _databaseService.insertExpenses(
        receipt.attachment.id, receipt.expenses);

    if (receipt.discounts.isNotEmpty) {
      await _databaseService.insertDiscounts(
          receipt.attachment.id, receipt.discounts);
    }

    Redux.store.dispatch(SetAttachmentsStateAction(AttachmentsState(
        attachments: Redux.store.state.attachmentsState.attachments
            .map((a) => a.id == receipt.attachment.id ? receipt.attachment : a)
            .toList(),
        loading: false)));

    return receipt;
  } else {
    List<Discount> discounts = await _databaseService.discounts(existing.id);
    return Receipt(
        attachment: existing, expenses: expenses, discounts: discounts);
  }
}

Future<List<Either<FailedReceipt, Receipt>>> insertReceipts(
    List<Attachment> attachments) async {
  return await Future.wait(attachments.map((attachment) async {
    try {
      return Right(await insertReceipt(attachment));
    } catch (err) {
      return Left(FailedReceipt(attachment: attachment, error: err.toString()));
    }
  }));
}
