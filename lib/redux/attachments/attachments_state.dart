import 'package:ebon_tracker/data/gmail_message.dart';
import 'package:meta/meta.dart';

@immutable
class AttachmentsState {
  final List<Attachment> attachments;
  final bool loading;

  const AttachmentsState({required this.attachments, required this.loading});

  factory AttachmentsState.initial() =>
      const AttachmentsState(attachments: [], loading: false);

  AttachmentsState copyWith(
      {required List<Attachment> attachments, required bool loading}) {
    return AttachmentsState(attachments: attachments, loading: loading);
  }
}
