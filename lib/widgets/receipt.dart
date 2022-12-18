// This has back button and drawer
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../application/database_service.dart';
import '../data/attachment.dart';
import '../data/expense.dart';
import 'expense.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key, required this.expenses});
  final List<Expense> expenses;

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
                rows: expenses
                    .map((expense) => DataRow(
                            onSelectChanged: ((selected) async {
                              if (selected != null && selected) {
                                var expenses =
                                    await ExpensesDb.getByName(expense.name);
                                List<Tuple2<Expense, Attachment>> tuple =
                                    await Future.wait(expenses.map((e) async =>
                                        Tuple2<Expense, Attachment>(
                                            e,
                                            (await AttachmentsDb.get(
                                                e.messageId))!)));

                                if (!mounted) return;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ExpensePage(expenses: tuple)));
                              }
                            }),
                            cells: [
                              DataCell(Text(expense.toString())),
                            ]))
                    .toList())));
  }
}
