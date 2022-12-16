import 'package:ebon_tracker/widgets/attachment.dart';
import 'package:flutter/material.dart';

import '../application/helpers.dart';
import '../data/attachment.dart';

class ErrorsPage extends StatelessWidget {
  const ErrorsPage({super.key, required this.errors});
  final List<FailedReceipt> errors;

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
        body: ListView(
          padding: EdgeInsets.zero,
          children: errors
              .map((e) => ListTile(
                    title: Text(
                        "${timestampString(e.attachment.timestamp)}: ${e.error}"),
                    onTap: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AttachmentPage(attachment: e.attachment)));
                    },
                  ))
              .toList(),
        ));
  }
}
