class Product {
  final int? id;
  final String name;
  final String? barcode;
  final double purchasePrice;
  final double salePrice;
  final int quantity;
  final int minQuantity;
  final int? supplierId;
  final String? category;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    this.barcode,
    required this.purchasePrice,
    required this.salePrice,
    this.quantity = 0,
    this.minQuantity = 10,
    this.supplierId,
    this.category,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // حساب الربح المتوقع للقطعة
  double get profitPerUnit => salePrice - purchasePrice;

  // حساب الربح الإجمالي للمخزون
  double get totalProfit => profitPerUnit * quantity;

  // هل المنتج ناقص من المخزون؟
  bool get isLowStock => quantity <= minQuantity;

  // هل المنتج نفد من المخزون؟
  bool get isOutOfStock => quantity <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'supplier_id': supplierId,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      quantity: map['quantity'] as int? ?? 0,
      minQuantity: map['min_quantity'] as int? ?? 10,
      supplierId: map['supplier_id'] as int?,
      category: map['category'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    int? minQuantity,
    int? supplierId,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      supplierId: supplierId ?? this.supplierId,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
