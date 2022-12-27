// This has back button and drawer
import 'package:dartz/dartz.dart' hide State;
import 'package:ebon_tracker/data/category.dart';
import 'package:ebon_tracker/data/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

import '../application/database_service.dart';
import '../data/attachment.dart';
import '../data/expense.dart';
import 'category_select.dart';
import 'expense.dart';

class ReceiptPage extends StatefulWidget {
  ReceiptPage({super.key, required this.expenses, required this.categories});
  List<Expense> expenses;
  final List<Category> categories;

  @override
  ReceiptPageState createState() {
    return ReceiptPageState();
  }
}

class ReceiptPageState extends State<ReceiptPage> {
  List<Expense> _expenses = [];
  @override
  void initState() {
    super.initState();
    setState(() {
      _expenses = widget.expenses;
    });
  }

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
                  DataColumn(
                    label: Text('Category'),
                  ),
                ],
                rows: _expenses
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
                              DataCell(Text(expense.category?.name ?? ''),
                                  onTap: () {
                                showModalBottomSheet<void>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Container(
                                        height: double.infinity,
                                        // color: Colors.amber,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: widget.categories
                                              .map((e) => ListTile(
                                                  title: Text(e.name),
                                                  onTap: () async {
                                                    await ProductsDb.update(
                                                        Product(
                                                            name: expense.name,
                                                            category: e.id));

                                                    setState(() {
                                                      _expenses
                                                          .firstWhere(
                                                              (element) =>
                                                                  element
                                                                      .name ==
                                                                  expense.name)
                                                          .category = e;
                                                    });

                                                    if (mounted) {
                                                      Navigator.pop(context);
                                                    }
                                                  }))
                                              .toList(),
                                        ),
                                      );
                                    });
                              }),
                              // onTap: () => Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //         builder: (_) => CategorySelectPage(
                              //             name: expense.name,
                              //             categories: [],
                              //             category: expense.category)))),
                            ]))
                    .toList())));
  }
}
