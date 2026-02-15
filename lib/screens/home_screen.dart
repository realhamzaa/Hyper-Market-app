import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../providers/product_provider.dart';
import '../providers/invoice_provider.dart';
import '../widgets/glass_card.dart';
import 'products_screen.dart';
import 'pos_screen.dart';
import 'invoices_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _todaySales = 0;
  double _monthSales = 0;
  int _todayInvoices = 0;
  int _lowStockCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);

    await productProvider.loadProducts();
    await invoiceProvider.loadInvoices();

    final todaySales = await invoiceProvider.getTotalSalesToday();
    final monthSales = await invoiceProvider.getTotalSalesMonth();
    final todayInvoices = await invoiceProvider.getTotalInvoicesToday();
    final lowStockCount = productProvider.getLowStockCount();

    setState(() {
      _todaySales = todaySales;
      _monthSales = monthSales;
      _todayInvoices = todayInvoices;
      _lowStockCount = lowStockCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildStatCards(),
                  const SizedBox(height: 30),
                  _buildQuickActions(),
                  const SizedBox(height: 30),
                  _buildFeatureCards(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassBox(borderRadius: 15),
          child: ShaderMask(
            shaderCallback: (bounds) => AppTheme.liquidGradient().createShader(bounds),
            child: const Icon(
              Icons.shopping_cart_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.liquidGradient().createShader(bounds),
                child: const Text(
                  'هايبر',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassBox(borderRadius: 15),
          child: const Icon(Icons.notifications_rounded, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'المبيعات اليوم',
            '₪${_todaySales.toStringAsFixed(2)}',
            Icons.monetization_on_rounded,
            [AppTheme.successColor, AppTheme.successColor.withOpacity(0.6)],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            'فواتير اليوم',
            '$_todayInvoices',
            Icons.receipt_long_rounded,
            [AppTheme.infoColor, AppTheme.infoColor.withOpacity(0.6)],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, List<Color> colors) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'نقطة البيع',
                Icons.point_of_sale_rounded,
                [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.6)],
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildQuickActionCard(
                'المنتجات',
                Icons.inventory_2_rounded,
                [AppTheme.secondaryColor, AppTheme.secondaryColor.withOpacity(0.6)],
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, List<Color> colors, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassBox(
          gradientColors: colors.map((c) => c.withOpacity(0.2)).toList(),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المزيد',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        _buildFeatureCard(
          'الفواتير',
          'عرض وإدارة جميع الفواتير',
          Icons.receipt_rounded,
          AppTheme.accentColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen())),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'التقارير',
          'تقارير المبيعات والأرباح',
          Icons.analytics_rounded,
          AppTheme.warningColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
        ),
        if (_lowStockCount > 0) ...[
          const SizedBox(height: 12),
          _buildFeatureCard(
            'تنبيه المخزون',
            '$_lowStockCount منتج منخفض المخزون',
            Icons.warning_rounded,
            AppTheme.errorColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen())),
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
