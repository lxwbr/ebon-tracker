import 'package:ebon_tracker/redux/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../application/gmail.dart';
import '../application/helpers.dart';
import '../application/reader.dart';
import '../data/receipt.dart';
import '../redux/attachments/attachments_state.dart';
import '../redux/main/main_actions.dart';
import 'attachment.dart';
import 'errors.dart';

class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({super.key, required this.account});
  final GoogleSignInAccount account;

  @override
  Widget build(BuildContext context, [bool mounted = true]) {
    return StoreConnector<AppState, AttachmentsState>(
        distinct: true,
        converter: (store) => store.state.attachmentsState,
        builder: (context, state) {
          return LayoutBuilder(
              builder: (context, constraints) => RefreshIndicator(
                  onRefresh: () async {
                    loadingAction();
                    int? latest;
                    if (state.attachments.isNotEmpty) {
                      latest = state.attachments
                          .reduce((value, element) =>
                              element.timestamp > value.timestamp
                                  ? element
                                  : value)
                          .timestamp;
                    }

                    Iterable<EitherReceipt> result =
                        await processMailbox(account, insertReceipts, latest);

                    List<FailedReceipt> errors = result.lefts();
                    loadedAction();

                    if (errors.isNotEmpty) {
                      if (!mounted) return;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ErrorsPage(errors: errors)));
                    }
                  },
                  child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                              minWidth: double.infinity),
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
                                                if (selected != null &&
                                                    selected)
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
                                            DataCell(Text(timestampString(
                                                attachment.timestamp))),
                                            DataCell(Text(
                                                attachment.total.toString())),
                                          ]))
                                  .toList())))));
        });
  }
}
