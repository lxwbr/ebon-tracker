import 'package:flutter/material.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  ExportState createState() {
    return ExportState();
  }
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
                      _fromCtl.text = date.toIso8601String();
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
                      _toCtl.text = date.toIso8601String();
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
