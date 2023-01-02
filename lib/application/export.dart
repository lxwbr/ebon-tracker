import 'dart:io';

import 'package:csv/csv.dart';
import 'package:ebon_tracker/data/category.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/expense.dart';
import '../data/product.dart';
import '../data/subsembly.dart';
import 'database_service.dart';

String _twoDigits(int n) {
  if (n >= 10) return "$n";
  return "0$n";
}

Future<void> _store(String name, List<List<String>> rows) async {
  String csv = const ListToCsvConverter().convert(rows);
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$name.csv');
  file.writeAsStringSync(csv);
  XFile xFile = XFile(file.path);
  await Share.shareXFiles([xFile]);
  file.deleteSync();
}

String _categoryString(
    Category category, String subCategories, List<Category> categories) {
  String name = ":${category.name}$subCategories";
  if (category.parentId != null) {
    Category parent =
        categories.firstWhere((element) => element.id == category.parentId);
    return _categoryString(parent, name, categories);
  } else {
    return name;
  }
}

Future<void> exportExpenses(
    DateTime from, DateTime to, List<Category> categories) async {
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
            ? "Haushalt:Lebensmittel:Deutschland:Rewe${_categoryString(expense.category!, "", categories)}"
            : "",
        flag: "None");
  });

  var rows = converted.map((e) => e.toCsv);

  await _store("subsembly", [Subsembly.headers, ...rows]);
}

Future<void> exportCategories(List<Category> categories) async {
  Iterable<List<String>> rows = categories.map((category) => category.toCsv);
  await _store("categories", [Category.headers, ...rows]);
}

Future<void> exportProducts() async {
  List<Product> products = await ProductsDb.all();
  Iterable<List<String>> rows = products.map((product) => product.toCsv);
  await _store("products", [Product.headers, ...rows]);
}
