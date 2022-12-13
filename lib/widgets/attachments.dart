import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:ebon_tracker/application/ebon_reader.dart';
import 'package:ebon_tracker/redux/store.dart';
import 'package:ebon_tracker/redux/user/user_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

import '../application/database_service.dart';
import '../data/gmail_message.dart';
import '../data/product.dart';
import '../redux/attachments/attachments_actions.dart';
import '../redux/attachments/attachments_state.dart';
import 'pdfviewerpage.dart';

DatabaseService _databaseService = DatabaseService();

class Attachments extends StatelessWidget {
  const Attachments({super.key, required this.account});
  final GoogleSignInAccount account;

  @override
  Widget build(BuildContext context) {
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
                          await Future.wait(
                              state.attachments.map((attachment) async {
                            List<Product> products = await _databaseService
                                .expensesByMessageId(attachment.id);
                            if (products.isEmpty) {
                              List<Either<String, Product>> prds =
                                  await readProducts(
                                      attachment.id,
                                      Uint8List.fromList(
                                          base64.decode(attachment.content)));
                              // TODO: error handling and display
                              List<Product> filtered = prds
                                  .where((element) => element.isRight())
                                  .map((e) => e.getOrElse(
                                      () => throw UnimplementedError()))
                                  .toList();
                              await Future.wait(filtered.map((expense) async {
                                await _databaseService.insertExpense(
                                    attachment.id, expense);
                              }));
                            }
                          }));
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
                      return PreferredSize(
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
                          .map((e) => DataRow(
                                  onSelectChanged: (selected) => {
                                        if (selected != null && selected)
                                          {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) => PdfViewerPage(
                                                        messageId: e.id,
                                                        content:
                                                            Uint8List.fromList(
                                                                base64.decode(e
                                                                    .content)))))
                                          }
                                      },
                                  cells: [
                                    DataCell(Text(e.id)),
                                    DataCell(Text(DateFormat('yy/MM/dd HH:mm')
                                        .format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                e.timestamp * 1000))))
                                  ]))
                          .toList())));
        });
  }
}
