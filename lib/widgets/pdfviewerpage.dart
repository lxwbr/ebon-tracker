// This has back button and drawer
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:ebon_tracker/application/ebon_reader.dart';
import 'package:ebon_tracker/data/gmail_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:tuple/tuple.dart';

import '../application/database_service.dart';
import '../data/product.dart';

DatabaseService _databaseService = DatabaseService();

class PdfViewerPage extends StatelessWidget {
  const PdfViewerPage(
      {super.key, required this.content, required this.messageId});
  final Uint8List content;
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              onPressed: () async {
                List<Product> products =
                    await _databaseService.expensesByMessageId(messageId);
                if (products.isEmpty) {
                  List<Either<String, Product>> scanned =
                      await readProducts(messageId, content);

                  List<String> errors = scanned
                      .where((element) => element.isLeft())
                      .map((e) =>
                          e.swap().getOrElse(() => throw UnimplementedError()))
                      .toList();
                  if (errors.isEmpty) {
                    List<Product> expenses = scanned
                        .map((e) =>
                            e.getOrElse(() => throw UnimplementedError()))
                        .toList();
                    await Future.wait(expenses.map((expense) async {
                      await _databaseService.insertExpense(messageId, expense);
                    }));

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                new ScannedPdfViewerPage(products: products)));
                  } else {
                    // TODO: display errors!
                  }
                }
              },
              icon: const Icon(Icons.scanner))
        ],
      ),
      drawer: Drawer(),
      body: PdfViewer.openData(content),
    );
  }
}

void onPressed(bool? selected, String name, BuildContext context) async {
  if (selected != null && selected) {
    var expenses = await _databaseService.expensesByName(name);
    List<Tuple2<Product, Attachment>> tuple = await Future.wait(expenses.map(
        (e) async => Tuple2<Product, Attachment>(
            e, await _databaseService.attachment(e.messageId))));

    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ExpensePage(products: tuple)));
  }
}

class ScannedPdfViewerPage extends StatelessWidget {
  const ScannedPdfViewerPage({super.key, required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        drawer: Drawer(),
        body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
                showCheckboxColumn: false,
                columns: const <DataColumn>[
                  DataColumn(
                    label: Text('Expense'),
                  ),
                ],
                rows: products
                    .map((e) => DataRow(
                            onSelectChanged: ((selected) async =>
                                {onPressed(selected, e.name, context)}),
                            cells: [
                              DataCell(Text(e.toString())),
                            ]))
                    .toList())));
  }
}

class ExpensePage extends StatelessWidget {
  const ExpensePage({super.key, required this.products});
  final List<Tuple2<Product, Attachment>> products;

  @override
  Widget build(BuildContext context) {
    List<Tuple2<Product, Attachment>> sorted = products.toList();

    sorted.sort((a, b) => b.item2.timestamp.compareTo(a.item2.timestamp));

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        drawer: Drawer(),
        body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
                showCheckboxColumn: false,
                columns: const <DataColumn>[
                  DataColumn(
                    label: Text('Expense'),
                  ),
                  DataColumn(
                    label: Text('Date'),
                  ),
                ],
                rows: sorted
                    .map((e) => DataRow(cells: [
                          DataCell(Text(e.item1.toString())),
                          DataCell(Text(DateFormat('yy/MM/dd HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  e.item2.timestamp * 1000))))
                        ]))
                    .toList())));
  }
}
