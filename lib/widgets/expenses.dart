import 'package:ebon_tracker/redux/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../application/database_service.dart';
import '../data/expense.dart';
import '../redux/attachments/attachments_state.dart';
import 'attachment.dart';

DatabaseService _databaseService = DatabaseService();

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<Expense> _expenses = [];
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
              child: SizedBox(
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
                                                    builder: (_) => AttachmentPage(
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
