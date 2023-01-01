import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/expense.dart';
import '../data/subsembly.dart';
import 'database_service.dart';

String _twoDigits(int n) {
  if (n >= 10) return "$n";
  return "0$n";
}

Future<void> export(DateTime from, DateTime to) async {
  Iterable<Expense> expenses = await ExpensesDb.between(from, to);
  Iterable<Subsembly> converted = expenses.map((expense) {
    String cdtDbtInd = expense.total() > .0 ? "DBIT" : "CRDT";
    return Subsembly(
        ownrAcctCcy: "EUR",
        bookgDt:
            "${_twoDigits(expense.timestamp!.day)}.${_twoDigits(expense.timestamp!.month)}.${expense.timestamp!.year.toString().substring(2)}",
        amt: expense.total(),
        amtCcy: "EUR",
        cdtDbtInd: cdtDbtInd,
        bookgSts: "BOOK",
        rmtdAcctCtry: "DE",
        readStatus: "false",
        rmtdUltmtNm: expense.name,
        category: expense.category != null
            ? "Haushalt:Lebensmittel:Deutschland:Rewe:${expense.category!.name}"
            : "",
        flag: "None");
  });

  var rows = converted.map((e) => e.toCsv);

  String csv = const ListToCsvConverter().convert([Subsembly.headers, ...rows]);
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/subsembly.csv');
  file.writeAsStringSync(csv);
  XFile xFile = XFile(file.path);
  await Share.shareXFiles([xFile]);
  file.deleteSync();
}
