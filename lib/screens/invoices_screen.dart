import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../providers/invoice_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/glass_card.dart';
import '../models/invoice.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<InvoiceProvider>(context, listen: false).loadInvoices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
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
        child: Consumer<InvoiceProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.invoices.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: provider.loadInvoices,
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.invoices.length,
                itemBuilder: (context, index) {
                  final invoice = provider.invoices[index];
                  return _buildInvoiceCard(invoice, provider);
                },
              ),
            );
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
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد فواتير',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice, InvoiceProvider provider) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: InkWell(
          onTap: () => _showInvoiceDetails(invoice, provider),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: invoice.isRefunded
                            ? LinearGradient(colors: [
                                AppTheme.errorColor.withOpacity(0.3),
                                AppTheme.errorColor.withOpacity(0.1),
                              ])
                            : AppTheme.liquidGradient(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        invoice.isRefunded
                            ? Icons.cancel_rounded
                            : Icons.receipt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(invoice.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₪${invoice.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: invoice.isRefunded
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor,
                          ),
                        ),
                        if (invoice.isRefunded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'مرتجع',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showInvoiceDetails(Invoice invoice, InvoiceProvider provider) async {
    final fullInvoice = await provider.getInvoiceDetails(invoice.id!);
    if (fullInvoice == null || !mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: AppTheme.glassBoxStrong(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تفاصيل الفاتورة',
                  style: TextStyle(
                    fontSize: 24,
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
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  _buildDetailRow('رقم الفاتورة:', fullInvoice.invoiceNumber),
                  const Divider(color: AppTheme.glassColor),
                  _buildDetailRow('التاريخ:',
                      DateFormat('dd/MM/yyyy HH:mm').format(fullInvoice.date)),
                  const Divider(color: AppTheme.glassColor),
                  _buildDetailRow('الحالة:', fullInvoice.isRefunded ? 'مرتجع' : 'مكتمل'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'العناصر',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: fullInvoice.items.length,
                itemBuilder: (context, index) {
                  final item = fullInvoice.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '₪${item.price.toStringAsFixed(2)} × ${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₪${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  _buildDetailRow('المجموع الفرعي:',
                      '₪${fullInvoice.subtotal.toStringAsFixed(2)}'),
                  if (fullInvoice.discount > 0) ...[
                    const Divider(color: AppTheme.glassColor),
                    _buildDetailRow('الخصم:',
                        '-₪${fullInvoice.discount.toStringAsFixed(2)}',
                        valueColor: AppTheme.errorColor),
                  ],
                  const Divider(color: AppTheme.glassColor),
                  _buildDetailRow('الإجمالي:',
                      '₪${fullInvoice.total.toStringAsFixed(2)}',
                      isTotal: true),
                ],
              ),
            ),
            if (!fullInvoice.isRefunded) ...[
              const SizedBox(height: 16),
              GlassButton(
                text: 'مرتجع',
                icon: Icons.undo_rounded,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.surfaceColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('تأكيد المرتجع',
                          style: TextStyle(color: AppTheme.textPrimary)),
                      content: const Text(
                        'هل تريد إرجاع هذه الفاتورة؟\nسيتم إرجاع الكميات للمخزون',
                        style: TextStyle(color: AppTheme.textSecondary),
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
                          child: const Text('تأكيد'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    final productProvider = Provider.of<ProductProvider>(
                        context,
                        listen: false);
                    final success = await provider.refundInvoice(
                        fullInvoice.id!, productProvider);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'تم إرجاع الفاتورة بنجاح'
                              : 'فشل إرجاع الفاتورة'),
                          backgroundColor: success
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
                gradientColors: [
                  AppTheme.errorColor,
                  AppTheme.errorColor.withOpacity(0.8),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: valueColor ??
                  (isTotal ? AppTheme.primaryColor : AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
