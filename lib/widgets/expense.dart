// This has back button and drawer
import 'package:dartz/dartz.dart';
import 'package:ebon_tracker/data/attachment.dart';
import 'package:flutter/material.dart';
import '../application/helpers.dart';
import '../data/expense.dart';

class ExpensePage extends StatelessWidget {
  const ExpensePage({super.key, required this.expenses});
  final List<Tuple2<Expense, Attachment>> expenses;

  @override
  Widget build(BuildContext context) {
    List<Tuple2<Expense, Attachment>> sorted = expenses.toList();

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
