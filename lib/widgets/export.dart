import 'dart:io';

import 'package:ebon_tracker/application/database_service.dart';
import 'package:ebon_tracker/data/expense.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../data/subsembly.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  ExportState createState() {
    return ExportState();
  }
}

String _twoDigits(int n) {
  if (n >= 10) return "${n}";
  return "0${n}";
}

class ExportState extends State<ExportPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _fromCtl = TextEditingController();
  TextEditingController _toCtl = TextEditingController();

  String? _from;
  String? _to;

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
            icon: const Icon(Icons.save),
            onPressed: () async {
              final form = _formKey.currentState;
              if (form != null) {
                if (form.validate()) {
                  form.save();

                  if (_from != null && _to != null) {
                    Iterable<Expense> expenses = await ExpensesDb.between(
                        DateTime.parse(_from!).toUtc(),
                        DateTime.parse(_to!)
                            .toUtc()
                            .add(const Duration(days: 1)));

                    print(expenses);

                    Expense first = expenses.first;
                    Subsembly test = Subsembly(
                        id: first.messageId,
                        ownrAcctCcy: "EUR",
                        bookgDt:
                            "${_twoDigits(first.timestamp!.day)}.${_twoDigits(first.timestamp!.month)}.${first.timestamp!.year.toString().substring(2)}",
                        amt: 22.8,
                        amtCcy: "EUR",
                        cdtDbtInd: "DBIT",
                        bookgTxt: "Test",
                        bookgSts: "BOOK",
                        btchBookg: "true",
                        rmtdAcctCtry: "DE",
                        readStatus: "false",
                        flag: "None");

                    Iterable<Subsembly> converted = expenses.map((expense) {
                      String cdtDbtInd = expense.total() > .0 ? "DBIT" : "CRDT";
                      String bookgTxt = expense.name;
                      return Subsembly(
                          ownrAcctCcy: "EUR",
                          bookgDt:
                              "${_twoDigits(expense.timestamp!.day)}.${_twoDigits(expense.timestamp!.month)}.${expense.timestamp!.year.toString().substring(2)}",
                          amt: expense.total(),
                          amtCcy: "EUR",
                          cdtDbtInd: cdtDbtInd,
                          bookgTxt: bookgTxt,
                          bookgSts: "BOOK",
                          rmtdAcctCtry: "DE",
                          readStatus: "false",
                          btchBookg: "false",
                          btchId: expense.messageId,
                          category: expense.category != null
                              ? "Haushalt:Lebensmittel:Deutschland:Rewe:${expense.category!.name}"
                              : "",
                          flag: "None");
                    });

                    var rows = converted.map((e) => e.toCsv);

                    print(rows.length);

                    String csv = const ListToCsvConverter()
                        .convert([Subsembly.headers, ...rows, test.toCsv]);
                    final directory = await getTemporaryDirectory();
                    final file = File('${directory.path}/subsembly.csv');
                    file.writeAsStringSync(csv);
                    XFile xFile = XFile(file.path);
                    await Share.shareXFiles([xFile]);
                    file.deleteSync();
                  }

                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Form(
          key: _formKey,
          child: Container(
            margin: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Column(children: [
              TextFormField(
                controller: _fromCtl,
                decoration: const InputDecoration(
                    icon: Icon(Icons.calendar_today), label: Text("From")),
                onTap: () async {
                  DateTime? date = DateTime.now();
                  FocusScope.of(context).requestFocus(FocusNode());

                  //when click we have to show the datepicker
                  date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100));

                  setState(() {
                    if (date != null) {
                      _fromCtl.text = date.toIso8601String().substring(0, 10);
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter date';
                  }
                  return null;
                },
                onSaved: (val) => setState(() {
                  _from = val;
                }),
              ),
              TextFormField(
                controller: _toCtl,
                decoration: const InputDecoration(
                    icon: Icon(Icons.calendar_today), label: Text("To")),
                onTap: () async {
                  DateTime? date = DateTime.now();
                  FocusScope.of(context).requestFocus(FocusNode());

                  //when click we have to show the datepicker
                  date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100));

                  setState(() {
                    if (date != null) {
                      _toCtl.text = date.toIso8601String().substring(0, 10);
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter date';
                  }
                  return null;
                },
                onSaved: (val) => setState(() {
                  _to = val;
                }),
              ),
            ]),
          )),
    );
  }
}
