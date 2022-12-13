import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:dartz/dartz.dart';

import 'package:flutter/foundation.dart';

import '../data/product.dart';

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
      return Quantity(n: n, price: price, unit: Unit.none);
    } else if (splitted.first.contains("kg")) {
      double n = double.parse(
          splitted.first.split("kg").first.trim().replaceAll(",", "."));
      double price = double.parse(
          splitted.last.split("EUR/kg").first.trim().replaceAll(",", "."));
      return Quantity(n: n, price: price, unit: Unit.kg);
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

Future<List<String>> read(String messageId, Uint8List pdfContent) async {
  File file;
  try {
    String tempDirPath = (await getTemporaryDirectory()).path;

    String filePath = join(tempDirPath, "rewe_ebon_$messageId.pdf");

    file = File(filePath);
    file.createSync(recursive: true);
    file.writeAsBytesSync(pdfContent);
  } on Exception catch (e) {
    return Future.error(e);
  }
  PDFDoc doc = await PDFDoc.fromFile(file);
  String text = await doc.text;
  file.deleteSync();

  int first = text.indexOf("EUR");
  int last = text.indexOf("--------------");
  List<String> splitted =
      new LineSplitter().convert(text.substring(first + 3, last).trim());

  return splitted;
}

Future<List<Either<String, Product>>> readProducts(
    String messageId, Uint8List pdfContent) async {
  List<String> splitted = await read(messageId, pdfContent);
  return consume(messageId, splitted, List.empty());
}
