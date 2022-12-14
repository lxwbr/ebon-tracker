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
  if (product.endsWith(" *")) {
    return product.substring(0, product.length - 2);
  } else {
    return product;
  }
}

double parsePrice(String string) {
  int numberIndex = string.substring(0, string.length - 2).lastIndexOf(" ");
  return double.parse(string
      .substring(numberIndex + 1, string.length - 2)
      .replaceAll(",", "."));
}

double? parseDiscount(String second) {
  if (second.trimLeft().startsWith("Rabatt") ||
      second.trimLeft().startsWith("Nachtr. Preiskorrekt") ||
      second.trimLeft().startsWith("Treuerabatt")) {
    return parsePrice(second);
  }
}

Quantity? parseQuantity(String second) {
  List<String> splitted = second.split(" x ");
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
    }
  }
}

Tuple2<String, double> parseFirst(String string) {
  String sanitized = sanitize(string);
  String name = sanitized.split("  ").first;
  double price = parsePrice(sanitized);
  return Tuple2(name, price);
}

List<Either<String, Product>> consume(String messageId, List<String> ebonLines,
    List<Either<String, Product>> products) {
  switch (ebonLines.length) {
    case 0:
      return products;
    case 1:
      try {
        Tuple2<String, double> first = parseFirst(ebonLines.first);
        return products +
            [
              Right(Product.from(
                  messageId, first.value1, first.value2, null, null))
            ];
      } catch (ex) {
        return products + [Left(ex.toString())];
      }
    default:
      try {
        Tuple2<String, double> first = parseFirst(ebonLines.first);
        String second = ebonLines[1];
        if (second.startsWith(" ")) {
          double? discount = parseDiscount(second);
          Quantity? quantity = parseQuantity(second);
          if (discount == null && quantity == null) {
            return products + [const Left("Unrecognized second line")];
          } else {
            return consume(
                messageId,
                ebonLines.sublist(2),
                products +
                    [
                      Right(Product.from(messageId, first.value1, first.value2,
                          discount, quantity)),
                    ]);
          }
        } else {
          return consume(
              messageId,
              ebonLines.sublist(1),
              products +
                  [
                    Right(Product.from(
                        messageId, first.value1, first.value2, null, null))
                  ]);
        }
      } catch (ex) {
        return products + [Left(ex.toString())];
      }
  }
}

Future<Tuple2<double, List<Either<String, Product>>>> read(
    Attachment attachment) async {
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

  List<String> expenses =
      textLines.sublist(first + 1, last).map((e) => e.text).toList();

  return Tuple2(total, consume(attachment.id, expenses, List.empty()));
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

Future<Either<FailedReceipt, Receipt>> insertReceipt(
    Attachment attachment) async {
  // Check if there expenses for this attachment has been scanned in the past
  Attachment? existing = await _databaseService.attachment(attachment.id);

  List<Product> expenses =
      await _databaseService.expensesByMessageId(attachment.id);

  if (expenses.isEmpty || existing == null || existing.total == null) {
    Tuple2<double, List<Either<String, Product>>> scanned =
        await read(attachment);

    // Filter errors only
    List<String> errors = scanned.value2.lefts();

    // If there are no errors scanning the PDF, proceed with inserting expenses to DB
    if (errors.isEmpty) {
      // Filter successful reads only
      List<Product> successful = scanned.value2.rights();

      attachment = Attachment(
          id: attachment.id,
          timestamp: attachment.timestamp,
          total: some(scanned.value1),
          content: attachment.content);

      if (existing == null) {
        await _databaseService.insertAttachment(attachment);
      } else if (existing.total.isNone()) {
        await _databaseService.updateAttachment(attachment);
      }

      await _databaseService.insertExpenses(attachment.id, successful);

      Redux.store.dispatch(SetAttachmentsStateAction(AttachmentsState(
          attachments: Redux.store.state.attachmentsState.attachments
              .map((a) => a.id == attachment.id ? attachment : a)
              .toList(),
          loading: false)));

      return Right(Receipt(attachment: attachment, expenses: successful));
    } else {
      return Left(FailedReceipt(errors: errors, attachment: attachment));
    }
  } else {
    return Right(Receipt(attachment: existing, expenses: expenses));
  }
}

Future<List<Either<FailedReceipt, Receipt>>> insertReceipts(
    List<Attachment> attachments) async {
  return await Future.wait(attachments.map((attachment) async {
    return await insertReceipt(attachment);
  }));
}
