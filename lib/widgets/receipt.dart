// This has back button and drawer
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../application/database_service.dart';
import '../data/attachment.dart';
import '../data/product.dart';
import 'expense.dart';

DatabaseService _databaseService = DatabaseService();

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key, required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context, [mounted = true]) {
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
                            onSelectChanged: ((selected) async {
                              if (selected != null && selected) {
                                var expenses = await _databaseService
                                    .expensesByName(product.name);
                                List<Tuple2<Product, Attachment>> tuple =
                                    await Future.wait(expenses.map((e) async =>
                                        Tuple2<Product, Attachment>(
                                            e,
                                            (await _databaseService
                                                .attachment(e.messageId))!)));

                                if (!mounted) return;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ExpensePage(products: tuple)));
                              }
                            }),
                            cells: [
                              DataCell(Text(product.toString())),
                            ]))
                    .toList())));
  }
}
