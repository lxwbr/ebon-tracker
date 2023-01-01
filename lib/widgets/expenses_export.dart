import 'package:ebon_tracker/application/export.dart';
import 'package:flutter/material.dart';

class ExportExpensesPage extends StatefulWidget {
  const ExportExpensesPage({super.key});

  @override
  ExportState createState() {
    return ExportState();
  }
}

class ExportState extends State<ExportExpensesPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fromCtl = TextEditingController();
  final TextEditingController _toCtl = TextEditingController();

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
                    await exportExpenses(
                        DateTime.parse(_from!).toUtc(),
                        DateTime.parse(_to!)
                            .toUtc()
                            .add(const Duration(days: 1)));
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
