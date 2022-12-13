class Product {
  final String name;
  final double pricePerUnit;
  final double quantity;
  final Units unit;
  final double discount;
  final double total;
  final String messageId;

  const Product({
    required this.name,
    required this.pricePerUnit,
    required this.discount,
    required this.quantity,
    required this.unit,
    required this.total,
    required this.messageId,
  });

  factory Product.from(String messageId, String name, double price,
      double? discount, Quantity? quantity) {
    var p;
    var n = 1.0;
    var d = .0;
    var u = Units.none;
    var t = price;
    if (quantity != null) {
      p = quantity.price;
      n = quantity.n;
      u = quantity.unit;
    } else {
      if (discount != null) {
        p = price;
        t = double.parse((price + discount).toStringAsFixed(2));
        d = discount;
      } else {
        p = price;
      }
    }

    return Product(
        messageId: messageId,
        name: name,
        pricePerUnit: p,
        discount: d,
        quantity: n,
        unit: u,
        total: t);
  }

  @override
  String toString() {
    return "$name: $pricePerUnit x $quantity${discount.abs() > 0 ? " - ${discount.abs()}" : ""} = $total";
  }

  Map<String, dynamic> toMap(String messageId) {
    return {
      'messageId': messageId,
      'name': name,
      'quantity': quantity,
      'price': pricePerUnit,
      'total': total,
      'discount': discount,
      'unit': unit.toString()
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    late Units u;
    switch (map['unit']) {
      case "Units.none":
        u = Units.none;
        break;
      case "Units.kg":
        u = Units.kg;
        break;
      default:
        throw UnimplementedError();
    }
    return Product(
      messageId: map['messageId'] ?? '',
      name: map['name'] ?? '',
      pricePerUnit: map['price'] ?? 0.0,
      discount: map['discount'] ?? 0.0,
      quantity: map['quantity'] ?? 0.0,
      total: map['total'] ?? 0.0,
      unit: u,
    );
  }
}

enum Units {
  none,
  kg,
}

class Quantity {
  final double n;
  final Units unit;
  final double price;

  const Quantity({required this.n, required this.price, required this.unit});
}
