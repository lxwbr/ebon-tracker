// This has back button and drawer
import 'package:dartz/dartz.dart';
import 'package:ebon_tracker/application/reader.dart';
import 'package:ebon_tracker/data/attachment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf_render/pdf_render_widgets.dart';

import '../application/database_service.dart';
import '../application/helpers.dart';
import '../data/product.dart';
import 'errors.dart';

DatabaseService _databaseService = DatabaseService();

class PdfViewerPage extends StatelessWidget {
  const PdfViewerPage({super.key, required this.attachment});
  final Attachment attachment;

  @override
  Widget build(BuildContext context, [bool mounted = true]) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              onPressed: () async {
                try {
                  Receipt receipt = await insertReceipt(attachment);
                  if (!mounted) return;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ScannedPdfViewerPage(
                              products: receipt.expenses)));
                } catch (ex) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ErrorsPage(errors: [
                                FailedReceipt(
                                    attachment: attachment,
                                    error: ex.toString())
                              ])));
                }
              },
              icon: const Icon(Icons.scanner))
        ],
      ),
      drawer: const Drawer(),
      body: PdfViewer.openData(attachment.byteArrayContent()),
    );
  }
}

void onPressed(bool? selected, String name, BuildContext context,
    [bool mounted = true]) async {
  if (selected != null && selected) {
    var expenses = await _databaseService.expensesByName(name);
    List<Tuple2<Product, Attachment>> tuple = await Future.wait(expenses.map(
        (e) async => Tuple2<Product, Attachment>(
            e, (await _databaseService.attachment(e.messageId))!)));

    if (!mounted) return;
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
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        drawer: const Drawer(),
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
                    .map((product) => DataRow(
                            onSelectChanged: ((selected) async =>
                                {onPressed(selected, product.name, context)}),
                            cells: [
                              DataCell(Text(product.toString())),
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

    sorted.sort((a, b) => b.value2.timestamp.compareTo(a.value2.timestamp));

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        drawer: const Drawer(),
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
                          DataCell(Text(e.value1.toString())),
                          DataCell(Text(timestampString(e.value2.timestamp)))
                        ]))
                    .toList())));
  }
}
