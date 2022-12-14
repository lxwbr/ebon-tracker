import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:ebon_tracker/data/attachment.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:redux/redux.dart';
import 'package:meta/meta.dart';

import '../../application/database_service.dart';
import '../store.dart';
import 'attachments_state.dart';

import 'package:http/http.dart' as http;

DatabaseService _databaseService = DatabaseService();

@immutable
class SetAttachmentsStateAction {
  final AttachmentsState attachmentsState;

  const SetAttachmentsStateAction(this.attachmentsState);
}

Future<List<String>> fetchAllMessageIds(
    GoogleSignInAccount account, int? after, String? nextToken) async {
  String uri =
      'https://gmail.googleapis.com/gmail/v1/users/${account.email}/messages'
      '?q=from:ebon@mailing.rewe.de';
  if (after != null) {
    uri = '$uri%20after:${after + 1}';
  }
  if (nextToken != null) {
    uri = '$uri&pageToken=$nextToken';
  }

  final http.Response response = await http.get(
    Uri.parse(uri),
    headers: await account.authHeaders,
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;

    int resultSizeEstimate = data['resultSizeEstimate'];
    if (resultSizeEstimate == 0) {
      return [];
    }
    final List<dynamic> messages = data['messages'] as List<dynamic>;
    final List<String> ids =
        messages.map((dynamic message) => message['id'] as String).toList();

    String? nextPageToken = data['nextPageToken'];

    if (nextPageToken == null || nextPageToken.isEmpty) {
      return ids;
    } else {
      return ids + await fetchAllMessageIds(account, after, nextPageToken);
    }
  } else {
    return Future.error("$response");
  }
}

Future<void> fetchAttachmentsAction(Store<AppState> store, int? after) async {
  if (store.state.userState.account != null) {
    store.dispatch(SetAttachmentsStateAction(AttachmentsState(
        attachments: store.state.attachmentsState.attachments, loading: true)));

    GoogleSignInAccount account = store.state.userState.account!;

    final List<String> ids = await fetchAllMessageIds(account, after, null);

    List<Attachment> fetched = await Future.wait(ids.map((id) async {
      final http.Response response = await http.get(
        Uri.parse(
            'https://gmail.googleapis.com/gmail/v1/users/${account.email}/messages/$id'),
        headers: await store.state.userState.account!.authHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;

        String attachmentId =
            data['payload']['parts'][1]['body']['attachmentId'] as String;

        final http.Response attachmentsResponse = await http.get(
          Uri.parse(
              'https://gmail.googleapis.com/gmail/v1/users/${account.email}/messages/${id}/attachments/$attachmentId'),
          headers: await store.state.userState.account!.authHeaders,
        );

        if (attachmentsResponse.statusCode == 200) {
          final Map<String, dynamic> attachmentsData =
              json.decode(attachmentsResponse.body) as Map<String, dynamic>;

          String content = attachmentsData['data'];

          int internalDate = int.parse(data['internalDate']) ~/ 1000;

          return Attachment(
              id: id, timestamp: internalDate, content: content, total: none());
        } else {
          return Future.error('Could not fetch attachment');
        }
      } else {
        return Future.error('Could not fetch message');
      }
    }));

    List<Attachment> filtered = fetched
        .where((attachment) =>
            store.state.attachmentsState.attachments
                .indexWhere((element) => element.id == attachment.id) ==
            -1)
        .toList();

    filtered.forEach((attachment) async {
      await _databaseService.insertAttachment(attachment);
    });

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    store.dispatch(SetAttachmentsStateAction(AttachmentsState(
        attachments: [...filtered, ...store.state.attachmentsState.attachments],
        loading: false)));
  }
}

Future<void> dbListAttachmentsAction(Store<AppState> store) async {
  //store.dispatch(SetAttachmentsStateAction(AttachmentsState(
  //    attachments: store.state.attachmentsState.attachments, loading: true)));

  try {
    List<Attachment> attachments = await _databaseService.attachments();

    store.dispatch(
      SetAttachmentsStateAction(
        AttachmentsState(attachments: attachments, loading: false),
      ),
    );
  } catch (error) {
    //store.dispatch(const SetAttachmentsStateAction(
    //    AttachmentsState(attachments: [], loading: false)));
  }
}

Future<void> deleteAttachmentsAction(Store<AppState> store) async {
  store.dispatch(SetAttachmentsStateAction(AttachmentsState(
      attachments: store.state.attachmentsState.attachments, loading: true)));

  try {
    await _databaseService.deleteAttachments();

    store.dispatch(
      const SetAttachmentsStateAction(
        AttachmentsState(attachments: [], loading: false),
      ),
    );
  } catch (error) {
    store.dispatch(const SetAttachmentsStateAction(
        AttachmentsState(attachments: [], loading: false)));
  }
}

Future<void> deleteExpensesAction(Store<AppState> store) async {
  try {
    await _databaseService.deleteExpenses();
  } catch (error) {}
}
