import 'package:ebon_tracker/data/attachment.dart';
import 'package:meta/meta.dart';

@immutable
class AttachmentsState {
  final List<Attachment> attachments;

  const AttachmentsState({required this.attachments});

  factory AttachmentsState.initial() => const AttachmentsState(attachments: []);

  AttachmentsState copyWith({required List<Attachment> attachments}) {
    return AttachmentsState(attachments: attachments);
  }
}
