import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';

String timestampString(int timestamp) {
  return DateFormat('yy/MM/dd HH:mm')
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
}

extension IterableEitherExtension<L, R> on Iterable<Either<L, R>> {
  List<R> rights() => where((e) => e.isRight())
      .map((e) => e.getOrElse(() => throw UnimplementedError()))
      .toList();

  List<L> lefts() => where((e) => e.isLeft())
      .map((e) => e.swap().getOrElse(() => throw UnimplementedError()))
      .toList();
}
