import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../providers/product_provider.dart';
import '../widgets/glass_card.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ProductProvider>(context, listen: false).loadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        actions: [
          IconButton(
            onPressed: () => _showAddProductDialog(),
            icon: const Icon(Icons.add_circle_rounded),
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
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.products.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: provider.loadProducts,
                    color: AppTheme.primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final product = provider.products[index];
                        return _buildProductCard(product, provider);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppTheme.glassBox(),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'بحث بالاسم أو الباركود...',
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onChanged: (query) {
            Provider.of<ProductProvider>(context, listen: false)
                .searchProducts(query);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.inventory_2_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد منتجات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة منتجات جديدة',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            text: 'إضافة منتج',
            icon: Icons.add_rounded,
            onPressed: () => _showAddProductDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('product_${product.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('تأكيد الحذف', style: TextStyle(color: AppTheme.textPrimary)),
              content: Text(
                'هل تريد حذف ${product.name}؟',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                  child: const Text('حذف'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) async {
          await provider.deleteProduct(product.id!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم حذف المنتج'),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        background: Container(
          decoration: AppTheme.glassBox(
            gradientColors: [
              AppTheme.errorColor.withOpacity(0.3),
              AppTheme.errorColor.withOpacity(0.1),
            ],
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.delete_rounded, color: AppTheme.errorColor, size: 28),
        ),
        child: GlassCard(
          child: InkWell(
            onTap: () => _showEditProductDialog(product, provider),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: product.isOutOfStock
                          ? LinearGradient(colors: [
                              AppTheme.errorColor.withOpacity(0.3),
                              AppTheme.errorColor.withOpacity(0.1),
                            ])
                          : product.isLowStock
                              ? LinearGradient(colors: [
                                  AppTheme.warningColor.withOpacity(0.3),
                                  AppTheme.warningColor.withOpacity(0.1),
                                ])
                              : AppTheme.liquidGradient(),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (product.barcode != null) ...[
                              Icon(Icons.qr_code_2, size: 14, color: AppTheme.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                product.barcode!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Icon(Icons.shopping_bag, size: 14, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${product.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: product.isOutOfStock
                                    ? AppTheme.errorColor
                                    : product.isLowStock
                                        ? AppTheme.warningColor
                                        : AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₪${product.salePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ربح: ₪${product.profitPerUnit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  void _showEditProductDialog(Product product, ProductProvider provider) {
    _showProductDialog(product: product, provider: provider);
  }

  void _showProductDialog({Product? product, ProductProvider? provider}) {
    final isEdit = product != null;
    
    final nameController = TextEditingController(text: product?.name);
    final barcodeController = TextEditingController(text: product?.barcode);
    final purchasePriceController =
        TextEditingController(text: product?.purchasePrice.toString());
    final salePriceController =
        TextEditingController(text: product?.salePrice.toString());
    final quantityController =
        TextEditingController(text: product?.quantity.toString() ?? '0');
    final minQuantityController =
        TextEditingController(text: product?.minQuantity.toString() ?? '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'تعديل منتج' : 'إضافة منتج',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'اسم المنتج', Icons.inventory_2),
              const SizedBox(height: 12),
              _buildTextField(barcodeController, 'الباركود (اختياري)', Icons.qr_code_2),
              const SizedBox(height: 12),
              _buildTextField(purchasePriceController, 'سعر الشراء', Icons.attach_money,
                  isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(salePriceController, 'سعر البيع', Icons.sell, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(quantityController, 'الكمية', Icons.production_quantity_limits,
                  isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(
                  minQuantityController, 'الحد الأدنى', Icons.warning_amber_rounded,
                  isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  purchasePriceController.text.isEmpty ||
                  salePriceController.text.isEmpty) {
                return;
              }

              final newProduct = Product(
                id: product?.id,
                name: nameController.text,
                barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
                purchasePrice: double.parse(purchasePriceController.text),
                salePrice: double.parse(salePriceController.text),
                quantity: int.parse(quantityController.text),
                minQuantity: int.parse(minQuantityController.text),
              );

              final productProvider =
                  Provider.of<ProductProvider>(context, listen: false);

              bool success;
              if (isEdit) {
                success = await productProvider.updateProduct(newProduct);
              } else {
                success = await productProvider.addProduct(newProduct);
              }

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? (isEdit ? 'تم تحديث المنتج' : 'تم إضافة المنتج')
                        : 'فشلت العملية'),
                    backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text(isEdit ? 'تحديث' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
      ),
    );
  }
}
