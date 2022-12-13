import 'package:intl/intl.dart';

String timestampString(int timestamp) {
  return DateFormat('yy/MM/dd HH:mm')
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
}
