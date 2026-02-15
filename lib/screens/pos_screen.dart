import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/theme.dart';
import '../providers/product_provider.dart';
import '../providers/invoice_provider.dart';
import '../widgets/glass_card.dart';
import '../models/product.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  final _discountController = TextEditingController();
  bool _isScanning = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    setState(() => _isScanning = true);
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: AppTheme.glassBoxStrong(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'مسح الباركود',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  onDetect: (capture) async {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && mounted) {
                      final barcode = barcodes.first.rawValue;
                      if (barcode != null) {
                        Navigator.pop(context);
                        await _addProductByBarcode(barcode);
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    setState(() => _isScanning = false);
  }

  Future<void> _addProductByBarcode(String barcode) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    final product = await productProvider.getProductByBarcode(barcode);
    
    if (product != null) {
      if (product.quantity > 0) {
        invoiceProvider.addToCart(product);
        _showSnackBar('تم إضافة ${product.name}', AppTheme.successColor);
      } else {
        _showSnackBar('المنتج ${product.name} غير متوفر', AppTheme.errorColor);
      }
    } else {
      _showSnackBar('المنتج غير موجود', AppTheme.errorColor);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDiscountDialog() {
    _discountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة خصم', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'نسبة الخصم %',
                hintText: 'مثال: 10',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(_discountController.text) ?? 0;
              if (discount > 0 && discount <= 100) {
                Provider.of<InvoiceProvider>(context, listen: false)
                    .applyPercentageDiscount(discount);
                Navigator.pop(context);
              }
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSale() async {
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    if (invoiceProvider.cartItems.isEmpty) {
      _showSnackBar('السلة فارغة', AppTheme.warningColor);
      return;
    }

    setState(() => _isSaving = true);

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final success = await invoiceProvider.saveInvoice(productProvider);

    setState(() => _isSaving = false);

    if (success) {
      _showSnackBar('تم حفظ الفاتورة بنجاح', AppTheme.successColor);
    } else {
      _showSnackBar('فشل حفظ الفاتورة', AppTheme.errorColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع'),
        actions: [
          IconButton(
            onPressed: _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: Consumer<InvoiceProvider>(
                builder: (context, invoiceProvider, _) {
                  if (invoiceProvider.cartItems.isEmpty) {
                    return _buildEmptyCart();
                  }
                  return _buildCartList(invoiceProvider);
                },
              ),
            ),
            Consumer<InvoiceProvider>(
              builder: (context, invoiceProvider, _) {
                return _buildBottomBar(invoiceProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: AppTheme.glassBox(),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'بحث عن منتج...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (query) {
                  if (query.isNotEmpty) {
                    _showProductSearchResults(query);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _scanBarcode,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBox(
                gradientColors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.primaryColor.withOpacity(0.1),
                ],
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSearchResults(String query) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.searchProducts(query);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: AppTheme.glassBoxStrong(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'نتائج البحث',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.products.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد نتائج',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      final product = provider.products[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: ListTile(
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '₪${product.salePrice.toStringAsFixed(2)} - متوفر: ${product.quantity}',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          trailing: product.quantity > 0
                              ? Icon(Icons.add_circle, color: AppTheme.successColor)
                              : Icon(Icons.remove_circle, color: AppTheme.errorColor),
                          onTap: () {
                            if (product.quantity > 0) {
                              Provider.of<InvoiceProvider>(context, listen: false)
                                  .addToCart(product);
                              Navigator.pop(context);
                              _showSnackBar('تم إضافة ${product.name}', AppTheme.successColor);
                            } else {
                              _showSnackBar('المنتج غير متوفر', AppTheme.errorColor);
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: AppTheme.liquidGradient(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'السلة فارغة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة المنتجات للبيع',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(InvoiceProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.cartItems.length,
      itemBuilder: (context, index) {
        final item = provider.cartItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key('${item.product.id}_$index'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => provider.removeItem(index),
            background: Container(
              decoration: AppTheme.glassBox(
                gradientColors: [
                  AppTheme.errorColor.withOpacity(0.3),
                  AppTheme.errorColor.withOpacity(0.1),
                ],
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
            ),
            child: GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₪${item.product.salePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => provider.updateQuantity(index, item.quantity - 1),
                        icon: const Icon(Icons.remove_circle, color: AppTheme.errorColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: AppTheme.glassBox(borderRadius: 10),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => provider.updateQuantity(index, item.quantity + 1),
                        icon: const Icon(Icons.add_circle, color: AppTheme.successColor),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '₪${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(InvoiceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassBoxStrong(),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المجموع الفرعي:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                Text(
                  '₪${provider.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (provider.discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الخصم:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  Text(
                    '-₪${provider.discount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24, color: AppTheme.glassStrongColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الإجمالي:',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.liquidGradient().createShader(bounds),
                  child: Text(
                    '₪${provider.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    text: 'خصم',
                    icon: Icons.discount_rounded,
                    onPressed: _showDiscountDialog,
                    gradientColors: [
                      AppTheme.warningColor,
                      AppTheme.warningColor.withOpacity(0.8),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GlassButton(
                    text: 'إتمام البيع',
                    icon: Icons.check_circle_rounded,
                    onPressed: _completeSale,
                    isLoading: _isSaving,
                    gradientColors: [
                      AppTheme.successColor,
                      AppTheme.successColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
