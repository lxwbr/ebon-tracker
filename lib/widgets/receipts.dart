import 'package:ebon_tracker/redux/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../application/helpers.dart';
import '../redux/attachments/attachments_state.dart';
import 'attachment.dart';

class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({super.key, required this.account});
  final GoogleSignInAccount account;

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
                          label: Text('Date'),
                        ),
                        DataColumn(
                          label: Text('EUR'),
                        ),
                      ],
                      rows: state.attachments
                          .map((attachment) => DataRow(
                                  onSelectChanged: (selected) => {
                                        if (selected != null && selected)
                                          {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        AttachmentPage(
                                                            attachment:
                                                                attachment)))
                                          }
                                      },
                                  cells: [
                                    DataCell(Text(
                                        timestampString(attachment.timestamp))),
                                    DataCell(Text(attachment.total
                                        .fold(() => "", (a) => a.toString()))),
                                  ]))
                          .toList())));
        });
  }
}
