enum MovementType {
  sale, // بيع
  purchase, // شراء/توريد
  adjustment, // تعديل يدوي
  refund, // مرتجع
}

class StockMovement {
  final int? id;
  final int productId;
  final String productName;
  final MovementType type;
  final int quantity;
  final String? notes;
  final DateTime date;
  final int? invoiceId;

  StockMovement({
    this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    this.notes,
    DateTime? date,
    this.invoiceId,
  }) : date = date ?? DateTime.now();

  String get typeArabic {
    switch (type) {
      case MovementType.sale:
        return 'بيع';
      case MovementType.purchase:
        return 'توريد';
      case MovementType.adjustment:
        return 'تعديل يدوي';
      case MovementType.refund:
        return 'مرتجع';
    }
  }

  bool get isPositive =>
      type == MovementType.purchase ||
      type == MovementType.refund ||
      (type == MovementType.adjustment && quantity > 0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'type': type.name,
      'quantity': quantity,
      'notes': notes,
      'date': date.toIso8601String(),
      'invoice_id': invoiceId,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      type: MovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MovementType.adjustment,
      ),
      quantity: map['quantity'] as int,
      notes: map['notes'] as String?,
      date: DateTime.parse(map['date'] as String),
      invoiceId: map['invoice_id'] as int?,
    );
  }
}
