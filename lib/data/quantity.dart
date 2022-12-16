import 'unit.dart';

class Quantity {
  final double n;
  final Unit unit;
  // Price per unit
  final double price;

  double total() => double.parse((price * n).toStringAsFixed(2));

  const Quantity({required this.n, required this.price, required this.unit});
}
