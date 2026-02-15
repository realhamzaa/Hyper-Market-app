import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/stock_movement.dart';
import '../database/database_helper.dart';
import 'product_provider.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.salePrice * quantity;
}

class InvoiceProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<CartItem> _cartItems = [];
  double _discountPercentage = 0;
  double _discountAmount = 0;
  List<Invoice> _invoices = [];
  bool _isLoading = false;

  List<CartItem> get cartItems => _cartItems;
  double get discountPercentage => _discountPercentage;
  double get discountAmount => _discountAmount;
  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;

  // حساب الإجمالي الفرعي
  double get subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.total);
  }

  // حساب الخصم
  double get discount {
    if (_discountPercentage > 0) {
      return subtotal * (_discountPercentage / 100);
    }
    return _discountAmount;
  }

  // الإجمالي النهائي
  double get total {
    return subtotal - discount;
  }

  // عدد العناصر
  int get itemCount => _cartItems.length;

  // إضافة منتج للسلة
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }
    
    notifyListeners();
  }

  // تحديث الكمية
  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index].quantity = quantity;
    }
    notifyListeners();
  }

  // حذف عنصر
  void removeItem(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  // تطبيق خصم نسبة مئوية
  void applyPercentageDiscount(double percentage) {
    _discountPercentage = percentage;
    _discountAmount = 0;
    notifyListeners();
  }

  // تطبيق خصم مبلغ ثابت
  void applyAmountDiscount(double amount) {
    _discountAmount = amount;
    _discountPercentage = 0;
    notifyListeners();
  }

  // إلغاء الخصم
  void clearDiscount() {
    _discountPercentage = 0;
    _discountAmount = 0;
    notifyListeners();
  }

  // حفظ الفاتورة
  Future<bool> saveInvoice(ProductProvider productProvider) async {
    if (_cartItems.isEmpty) return false;

    try {
      // إنشاء رقم فاتورة
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      
      // إنشاء الفاتورة
      final invoice = Invoice(
        invoiceNumber: invoiceNumber,
        date: DateTime.now(),
        subtotal: subtotal,
        discount: discount,
        total: total,
      );

      final invoiceId = await _db.insertInvoice(invoice);

      // إضافة العناصر
      for (var item in _cartItems) {
        final invoiceItem = InvoiceItem(
          invoiceId: invoiceId,
          productId: item.product.id!,
          productName: item.product.name,
          price: item.product.salePrice,
          quantity: item.quantity,
          total: item.total,
        );
        
        await _db.insertInvoiceItem(invoiceItem);

        // تحديث المخزون
        final newQuantity = item.product.quantity - item.quantity;
        await _db.updateProductQuantity(item.product.id!, newQuantity);

        // تسجيل حركة المخزون
        final movement = StockMovement(
          productId: item.product.id!,
          productName: item.product.name,
          type: MovementType.sale,
          quantity: -item.quantity,
          invoiceId: invoiceId,
        );
        await _db.insertStockMovement(movement);
      }

      // تحديث المنتجات
      await productProvider.loadProducts();

      // تفريغ السلة
      clearCart();

      // تحديث الفواتير
      await loadInvoices();

      return true;
    } catch (e) {
      debugPrint('Error saving invoice: $e');
      return false;
    }
  }

  // تفريغ السلة
  void clearCart() {
    _cartItems.clear();
    clearDiscount();
    notifyListeners();
  }

  // تحميل الفواتير
  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _invoices = await _db.getAllInvoices();
    } catch (e) {
      debugPrint('Error loading invoices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // الحصول على فاتورة بالتفاصيل
  Future<Invoice?> getInvoiceDetails(int id) async {
    try {
      return await _db.getInvoiceById(id);
    } catch (e) {
      debugPrint('Error getting invoice details: $e');
      return null;
    }
  }

  // مرتجع فاتورة
  Future<bool> refundInvoice(int invoiceId, ProductProvider productProvider) async {
    try {
      final invoice = await _db.getInvoiceById(invoiceId);
      if (invoice == null || invoice.isRefunded) return false;

      // تحديث حالة الفاتورة
      await _db.refundInvoice(invoiceId);

      // إرجاع الكميات للمخزون
      for (var item in invoice.items) {
        final product = await _db.getProductById(item.productId);
        if (product != null) {
          final newQuantity = product.quantity + item.quantity;
          await _db.updateProductQuantity(product.id!, newQuantity);

          // تسجيل حركة المخزون
          final movement = StockMovement(
            productId: product.id!,
            productName: product.name,
            type: MovementType.refund,
            quantity: item.quantity,
            invoiceId: invoiceId,
            notes: 'مرتجع فاتورة ${invoice.invoiceNumber}',
          );
          await _db.insertStockMovement(movement);
        }
      }

      // تحديث المنتجات والفواتير
      await productProvider.loadProducts();
      await loadInvoices();

      return true;
    } catch (e) {
      debugPrint('Error refunding invoice: $e');
      return false;
    }
  }

  // إحصائيات
  Future<double> getTotalSalesToday() async {
    try {
      return await _db.getTotalSalesToday();
    } catch (e) {
      debugPrint('Error getting total sales today: $e');
      return 0.0;
    }
  }

  Future<double> getTotalSalesMonth() async {
    try {
      return await _db.getTotalSalesMonth();
    } catch (e) {
      debugPrint('Error getting total sales month: $e');
      return 0.0;
    }
  }

  Future<int> getTotalInvoicesToday() async {
    try {
      return await _db.getTotalInvoicesToday();
    } catch (e) {
      debugPrint('Error getting total invoices today: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getTopSellingProducts() async {
    try {
      return await _db.getTopSellingProducts();
    } catch (e) {
      debugPrint('Error getting top selling products: $e');
      return {'products': []};
    }
  }
}
