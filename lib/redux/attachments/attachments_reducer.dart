import 'attachments_state.dart';
import 'attachments_actions.dart';

attachmentsReducer(
    AttachmentsState prevState, SetAttachmentsStateAction action) {
  final payload = action.attachmentsState;
  return prevState.copyWith(attachments: payload.attachments);
}
