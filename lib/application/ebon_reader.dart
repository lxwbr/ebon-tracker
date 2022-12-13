import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ebon_tracker/data/receipt.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:dartz/dartz.dart';

import 'package:flutter/foundation.dart';

import '../data/attachment.dart';
import '../data/product.dart';
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

Future<List<String>> read(String messageId, String content) async {
  PdfDocument document = PdfDocument.fromBase64String(content);
  //Create a new instance of the PdfTextExtractor.
  PdfTextExtractor extractor = PdfTextExtractor(document);

  //Extract all the text from the document.
  List<TextLine> textLines = extractor.extractTextLines();

  document.dispose();

  int first = textLines.indexWhere((element) => element.text.contains("EUR"));
  int last = textLines
      .indexWhere((element) => element.text.contains("--------------"));

  List<String> expenses =
      textLines.sublist(first + 1, last).map((e) => e.text).toList();

  return expenses;
}

Future<List<Either<String, Product>>> scanAttachment(
    Attachment attachment) async {
  List<String> splitted = await read(attachment.id, attachment.content);
  return consume(attachment.id, splitted, List.empty());
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
  List<Product> existing =
      await _databaseService.expensesByMessageId(attachment.id);

  if (existing.isEmpty) {
    List<Either<String, Product>> scanned = await scanAttachment(attachment);

    // Filter errors only
    List<String> errors = scanned.lefts();

    // If there are no errors scanning the PDF, proceed with inserting expenses to DB
    if (errors.isEmpty) {
      // Filter successful reads only
      List<Product> successful = scanned.rights();

      await _databaseService.insertExpenses(attachment.id, successful);

      return Right(Receipt(
          id: attachment.id,
          timestamp: attachment.timestamp,
          expenses: successful));
    } else {
      return Left(FailedReceipt(errors: errors, attachment: attachment));
    }
  } else {
    return Right(Receipt(
        id: attachment.id,
        timestamp: attachment.timestamp,
        expenses: existing));
  }
}

Future<List<Either<FailedReceipt, Receipt>>> insertReceipts(
    List<Attachment> attachments) async {
  return await Future.wait(attachments.map((attachment) async {
    return await insertReceipt(attachment);
  }));
}
