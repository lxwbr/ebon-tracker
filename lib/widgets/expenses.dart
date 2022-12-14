import 'dart:convert';

import 'package:dartz/dartz.dart' hide State;
import 'package:ebon_tracker/application/reader.dart';
import 'package:ebon_tracker/redux/store.dart';
import 'package:ebon_tracker/redux/user/user_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../application/database_service.dart';
import '../application/helpers.dart';
import '../data/attachment.dart';
import '../data/product.dart';
import '../redux/attachments/attachments_actions.dart';
import '../redux/attachments/attachments_state.dart';
import 'errors.dart';
import 'pdfviewerpage.dart';

DatabaseService _databaseService = DatabaseService();

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  List<Product> _expenses = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _databaseService.expenses().then((expenses) => setState(() {
            _expenses = expenses;
          }));
    });
  }

  @override
  Widget build(BuildContext context, [bool mounted = true]) {
    return StoreConnector<AppState, AttachmentsState>(
        distinct: true,
        converter: (store) => store.state.attachmentsState,
        builder: (context, state) {
          return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                  width: double.infinity,
                  child: DataTable(
                      showCheckboxColumn: false,
                      columns: const <DataColumn>[
                        DataColumn(
                          label: Text('Name'),
                        ),
                        DataColumn(
                          label: Text('EUR'),
                        ),
                      ],
                      rows: _expenses
                          .map((expense) => DataRow(
                                  onSelectChanged: (selected) => {
                                        if (selected != null && selected)
                                          {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) => PdfViewerPage(
                                                        attachment: state
                                                            .attachments
                                                            .firstWhere((element) =>
                                                                element.id ==
                                                                expense
                                                                    .messageId))))
                                          }
                                      },
                                  cells: [
                                    DataCell(Text(expense.name)),
                                    DataCell(Text(expense.price.toString())),
                                  ]))
                          .toList())));
        });
  }
}
