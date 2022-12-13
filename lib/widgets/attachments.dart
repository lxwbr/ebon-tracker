import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:ebon_tracker/application/ebon_reader.dart';
import 'package:ebon_tracker/redux/store.dart';
import 'package:ebon_tracker/redux/user/user_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../application/database_service.dart';
import '../application/helpers.dart';
import '../data/attachment.dart';
import '../data/receipt.dart';
import '../redux/attachments/attachments_actions.dart';
import '../redux/attachments/attachments_state.dart';
import 'errors.dart';
import 'pdfviewerpage.dart';

DatabaseService _databaseService = DatabaseService();

class Attachments extends StatelessWidget {
  const Attachments({super.key, required this.account});
  final GoogleSignInAccount account;

  @override
  Widget build(BuildContext context, [bool mounted = true]) {
    return StoreConnector<AppState, AttachmentsState>(
        distinct: true,
        converter: (store) => store.state.attachmentsState,
        builder: (context, state) {
          List<Attachment> sorted = state.attachments.toList();
          sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return Scaffold(
              appBar: AppBar(
                  title: const Text('Attachments'),
                  actions: [
                    IconButton(
                        onPressed: () async {
                          // TODO: display errors.
                          List<Either<FailedReceipt, Receipt>> result =
                              await insertReceipts(state.attachments);
                          List<FailedReceipt> errors = result.lefts();

                          if (errors.isNotEmpty) {
                            if (!mounted) return;
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ErrorsPage(errors: errors)));
                          }
                        },
                        icon: const Icon(Icons.scanner)),
                    IconButton(
                        onPressed: () async {
                          if (sorted.isNotEmpty) {
                            fetchAttachmentsAction(
                                Redux.store, sorted.first.timestamp);
                          } else {
                            fetchAttachmentsAction(Redux.store, null);
                          }
                        },
                        icon: const Icon(Icons.refresh))
                  ],
                  bottom: (() {
                    if (state.loading) {
                      return const PreferredSize(
                          preferredSize: Size.fromHeight(6.0),
                          child: LinearProgressIndicator(
                            semanticsLabel: 'Linear progress indicator',
                          ));
                    }
                  })()),
              drawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                      ),
                      child: ListTile(
                        leading: GoogleUserCircleAvatar(
                          identity: account,
                        ),
                        title: Text(account.displayName ?? ''),
                        subtitle: Text(account.email),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Clear attachments table'),
                      onTap: () async {
                        await deleteAttachmentsAction(Redux.store);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Clear expenses table'),
                      onTap: () async {
                        await _databaseService.deleteExpenses();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Sign out'),
                      onTap: () async {
                        signOutAction(Redux.store);
                      },
                    ),
                  ],
                ),
              ),
              body: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                      showCheckboxColumn: false,
                      columns: const <DataColumn>[
                        DataColumn(
                          label: Text('Id'),
                        ),
                        DataColumn(
                          label: Text('Date'),
                        ),
                      ],
                      rows: sorted
                          .map((attachment) => DataRow(
                                  onSelectChanged: (selected) => {
                                        if (selected != null && selected)
                                          {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        PdfViewerPage(
                                                            attachment:
                                                                attachment)))
                                          }
                                      },
                                  cells: [
                                    DataCell(Text(attachment.id)),
                                    DataCell(Text(
                                        timestampString(attachment.timestamp)))
                                  ]))
                          .toList())));
        });
  }
}
