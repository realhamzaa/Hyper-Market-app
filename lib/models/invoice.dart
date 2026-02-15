class Invoice {
  final int? id;
  final String invoiceNumber;
  final DateTime date;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final bool isRefunded;
  final DateTime? refundedAt;
  final List<InvoiceItem> items;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.date,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    this.paymentMethod = 'نقدي',
    this.isRefunded = false,
    this.refundedAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'is_refunded': isRefunded ? 1 : 0,
      'refunded_at': refundedAt?.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      date: DateTime.parse(map['date'] as String),
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String? ?? 'نقدي',
      isRefunded: (map['is_refunded'] as int) == 1,
      refundedAt: map['refunded_at'] != null
          ? DateTime.parse(map['refunded_at'] as String)
          : null,
    );
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? date,
    double? subtotal,
    double? discount,
    double? total,
    String? paymentMethod,
    bool? isRefunded,
    DateTime? refundedAt,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRefunded: isRefunded ?? this.isRefunded,
      refundedAt: refundedAt ?? this.refundedAt,
      items: items ?? this.items,
    );
  }
}

class InvoiceItem {
  final int? id;
  final int invoiceId;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      total: (map['total'] as num).toDouble(),
    );
  }
}
