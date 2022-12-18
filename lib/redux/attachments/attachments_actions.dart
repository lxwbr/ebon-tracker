import 'dart:convert';

import 'package:ebon_tracker/data/attachment.dart';
import 'package:ebon_tracker/redux/main/main_actions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:redux/redux.dart';
import 'package:meta/meta.dart';

import '../../application/database_service.dart';
import '../../data/pdf.dart';
import '../store.dart';
import 'attachments_state.dart';

import 'package:http/http.dart' as http;

@immutable
class SetAttachmentsStateAction {
  final AttachmentsState attachmentsState;

  const SetAttachmentsStateAction(this.attachmentsState);
}

Future<void> dbListAttachmentsAction() async {
  loadingAction();
  try {
    List<Attachment> attachments = await AttachmentsDb.all();

    Redux.store.dispatch(
      SetAttachmentsStateAction(
        AttachmentsState(attachments: attachments),
      ),
    );
    loadedAction();
  } catch (error) {
    loadedAction();
  }
}

Future<void> deleteAttachmentsAction(Store<AppState> store) async {
  loadingAction();
  try {
    await deleteExpensesAction();
    await deleteDiscountsAction();
    await AttachmentsDb.purge();

    store.dispatch(
      const SetAttachmentsStateAction(
        AttachmentsState(attachments: []),
      ),
    );
    loadedAction();
  } catch (error) {
    store.dispatch(
        const SetAttachmentsStateAction(AttachmentsState(attachments: [])));
    loadedAction();
  }
}

Future<void> deleteExpensesAction() async {
  loadingAction();
  await ExpensesDb.purge();
  loadedAction();
}

Future<void> deleteDiscountsAction() async {
  loadingAction();
  await DiscountsDb.purge();
  loadedAction();
}
