import 'package:flutter/material.dart';
import '../models/product.dart';
import '../database/database_helper.dart';

class ProductProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // تحميل المنتجات
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _db.getAllProducts();
      _filteredProducts = _products;
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // بحث سريع
  void searchProducts(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products.where((product) {
        final nameLower = product.name.toLowerCase();
        final barcodeLower = product.barcode?.toLowerCase() ?? '';
        final queryLower = query.toLowerCase();
        
        return nameLower.contains(queryLower) || 
               barcodeLower.contains(queryLower);
      }).toList();
    }
    
    notifyListeners();
  }

  // إضافة منتج
  Future<bool> addProduct(Product product) async {
    try {
      final id = await _db.insertProduct(product);
      if (id > 0) {
        await loadProducts();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }

  // تحديث منتج
  Future<bool> updateProduct(Product product) async {
    try {
      final result = await _db.updateProduct(product);
      if (result > 0) {
        await loadProducts();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  // حذف منتج
  Future<bool> deleteProduct(int id) async {
    try {
      final result = await _db.deleteProduct(id);
      if (result > 0) {
        await loadProducts();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  // تحديث كمية المنتج
  Future<void> updateProductQuantity(int productId, int newQuantity) async {
    try {
      await _db.updateProductQuantity(productId, newQuantity);
      await loadProducts();
    } catch (e) {
      debugPrint('Error updating product quantity: $e');
    }
  }

  // الحصول على منتج بالباركود
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      return await _db.getProductByBarcode(barcode);
    } catch (e) {
      debugPrint('Error getting product by barcode: $e');
      return null;
    }
  }

  // المنتجات منخفضة المخزون
  Future<List<Product>> getLowStockProducts() async {
    try {
      return await _db.getLowStockProducts();
    } catch (e) {
      debugPrint('Error getting low stock products: $e');
      return [];
    }
  }

  // عدد المنتجات منخفضة المخزون
  int getLowStockCount() {
    return _products.where((p) => p.isLowStock).length;
  }

  // عدد المنتجات النافدة
  int getOutOfStockCount() {
    return _products.where((p) => p.isOutOfStock).length;
  }
}
