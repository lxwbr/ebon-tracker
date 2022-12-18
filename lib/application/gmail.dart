import 'dart:convert';

import 'package:ebon_tracker/application/reader.dart';
import 'package:ebon_tracker/redux/main/main_actions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/pdf.dart';
import 'package:http/http.dart' as http;

const String reweEmail = "ebon@mailing.rewe.de";
typedef PageProcessor = Future<Iterable<EitherReceipt>> Function(
    Iterable<Pdf> page);
typedef Headers = Map<String, String>;

Future<Iterable<EitherReceipt>> processMailbox(
    GoogleSignInAccount account, PageProcessor process, int? after) async {
  Headers headers = await account.authHeaders;

  return await _processPage(headers, account.email, process, 0, after, null);
}

Future<Iterable<EitherReceipt>> _processPage(
    Headers headers,
    String email,
    PageProcessor process,
    int processedCount,
    int? after,
    String? token) async {
  String uri = 'https://gmail.googleapis.com/gmail/v1/users/$email/messages'
      '?q=from:$reweEmail';
  if (after != null) {
    uri = '$uri%20after:${after + 60}';
  }
  if (token != null) {
    uri = '$uri&pageToken=$token';
  }
  uri = '$uri&maxResults=5';

  final http.Response response =
      await http.get(Uri.parse(uri), headers: headers);

  if (response.statusCode == 200) {
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;

    int resultSizeEstimate = data['resultSizeEstimate'];
    if (resultSizeEstimate == 0) {
      return [];
    }

    final List<dynamic> messages = data['messages'] as List<dynamic>;

    final Iterable<String> messageIds =
        messages.map((dynamic message) => message['id'] as String);

    Iterable<Pdf> pdfs = await Future.wait(
        messageIds.map((messageId) => _fetchPdf(headers, messageId, email)));

    Iterable<EitherReceipt> receipts = await process(pdfs);

    String? nextPageToken = data['nextPageToken'];
    if (nextPageToken != null) {
      return [
        ...receipts,
        ...await _processPage(
            headers, email, process, processedCount, after, nextPageToken)
      ];
    } else {
      return receipts;
    }
  } else {
    return Future.error("$response");
  }
}

Future<Pdf> _fetchPdf(Headers headers, String messageId, String email) async {
  final http.Response response = await http.get(
    Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/$email/messages/$messageId'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;

    String attachmentId =
        data['payload']['parts'][1]['body']['attachmentId'] as String;

    final http.Response attachmentsResponse = await http.get(
      Uri.parse(
          'https://gmail.googleapis.com/gmail/v1/users/$email/messages/$messageId/attachments/$attachmentId'),
      headers: headers,
    );

    if (attachmentsResponse.statusCode == 200) {
      final Map<String, dynamic> attachmentsData =
          json.decode(attachmentsResponse.body) as Map<String, dynamic>;

      String content = attachmentsData['data'];

      int internalDate = int.parse(data['internalDate']) ~/ 1000;

      return Pdf(id: messageId, timestamp: internalDate, content: content);
    } else {
      return Future.error('Could not fetch attachment');
    }
  } else {
    return Future.error('Could not fetch message');
  }
}
