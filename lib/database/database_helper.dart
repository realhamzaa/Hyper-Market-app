import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../models/stock_movement.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hyper_market.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول المنتجات
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        purchase_price REAL NOT NULL,
        sale_price REAL NOT NULL,
        quantity INTEGER DEFAULT 0,
        min_quantity INTEGER DEFAULT 10,
        supplier_id INTEGER,
        category TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0,
        total REAL NOT NULL,
        payment_method TEXT DEFAULT 'نقدي',
        is_refunded INTEGER DEFAULT 0,
        refunded_at TEXT
      )
    ''');

    // جدول عناصر الفاتورة
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // جدول الموردين
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // جدول حركة المخزون
    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        notes TEXT,
        date TEXT NOT NULL,
        invoice_id INTEGER,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // فهارس للبحث السريع
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_invoices_date ON invoices(date)');
    await db.execute('CREATE INDEX idx_stock_movements_product ON stock_movements(product_id)');
    await db.execute('CREATE INDEX idx_stock_movements_date ON stock_movements(date)');
  }

  // ==================== المنتجات ====================
  
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final result = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT * FROM products WHERE quantity <= min_quantity ORDER BY quantity ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateProductQuantity(int productId, int quantity) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE products SET quantity = ?, updated_at = ? WHERE id = ?',
      [quantity, DateTime.now().toIso8601String(), productId],
    );
  }

  // ==================== الفواتير ====================
  
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    return await db.insert('invoices', invoice.toMap());
  }

  Future<int> insertInvoiceItem(InvoiceItem item) async {
    final db = await database;
    return await db.insert('invoice_items', item.toMap());
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final result = await db.query('invoices', orderBy: 'date DESC');
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final db = await database;
    final result = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    
    final invoice = Invoice.fromMap(result.first);
    final items = await getInvoiceItems(id);
    return invoice.copyWith(items: items);
  }

  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final db = await database;
    final result = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return result.map((map) => InvoiceItem.fromMap(map)).toList();
  }

  Future<List<Invoice>> getInvoicesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'invoices',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<int> refundInvoice(int invoiceId) async {
    final db = await database;
    return await db.update(
      'invoices',
      {
        'is_refunded': 1,
        'refunded_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // ==================== الموردين ====================
  
  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    return await db.insert('suppliers', supplier.toMap());
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final result = await db.query('suppliers', orderBy: 'name ASC');
    return result.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== حركة المخزون ====================
  
  Future<int> insertStockMovement(StockMovement movement) async {
    final db = await database;
    return await db.insert('stock_movements', movement.toMap());
  }

  Future<List<StockMovement>> getStockMovements({int? productId, int limit = 100}) async {
    final db = await database;
    final result = await db.query(
      'stock_movements',
      where: productId != null ? 'product_id = ?' : null,
      whereArgs: productId != null ? [productId] : null,
      orderBy: 'date DESC',
      limit: limit,
    );
    return result.map((map) => StockMovement.fromMap(map)).toList();
  }

  // ==================== إحصائيات ====================
  
  Future<double> getTotalSalesToday() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM invoices WHERE date >= ? AND date < ? AND is_refunded = 0',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalSalesMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM invoices WHERE date >= ? AND date < ? AND is_refunded = 0',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getTotalInvoicesToday() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices WHERE date >= ? AND date < ? AND is_refunded = 0',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>> getTopSellingProducts({int limit = 10}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        ii.product_id,
        ii.product_name,
        SUM(ii.quantity) as total_quantity,
        SUM(ii.total) as total_revenue
      FROM invoice_items ii
      INNER JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.is_refunded = 0
      GROUP BY ii.product_id, ii.product_name
      ORDER BY total_quantity DESC
      LIMIT ?
    ''', [limit]);
    
    return {'products': result};
  }

  // ==================== النسخ الاحتياطي ====================
  
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    
    final products = await db.query('products');
    final invoices = await db.query('invoices');
    final invoiceItems = await db.query('invoice_items');
    final suppliers = await db.query('suppliers');
    final stockMovements = await db.query('stock_movements');
    
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'products': products,
      'invoices': invoices,
      'invoice_items': invoiceItems,
      'suppliers': suppliers,
      'stock_movements': stockMovements,
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // حذف البيانات الحالية
      await txn.delete('invoice_items');
      await txn.delete('invoices');
      await txn.delete('stock_movements');
      await txn.delete('products');
      await txn.delete('suppliers');
      
      // استيراد البيانات الجديدة
      for (var item in data['suppliers'] ?? []) {
        await txn.insert('suppliers', item);
      }
      
      for (var item in data['products'] ?? []) {
        await txn.insert('products', item);
      }
      
      for (var item in data['invoices'] ?? []) {
        await txn.insert('invoices', item);
      }
      
      for (var item in data['invoice_items'] ?? []) {
        await txn.insert('invoice_items', item);
      }
      
      for (var item in data['stock_movements'] ?? []) {
        await txn.insert('stock_movements', item);
      }
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
