import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/widgets/common_footer.dart';
import '../../../billing/data/models/invoice_model.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime _selectedMonth = DateTime.now();
  
  List<InvoiceModel> _getFilteredInvoices() {
    final email = HiveDatabase.settingsBox.get('logged_in_user');
    if (email == null) return [];
    
    return HiveDatabase.invoiceBox.values.where((invoice) {
      return invoice.userEmail == email &&
          invoice.dateTime.year == _selectedMonth.year &&
          invoice.dateTime.month == _selectedMonth.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvoices = _getFilteredInvoices();
    
    double totalRevenue = 0;
    int totalItemsSold = 0;
    Map<String, int> productSales = {};
    
    for (var invoice in filteredInvoices) {
      totalRevenue += invoice.totalAmount;
      for (var item in invoice.items) {
        totalItemsSold += item.quantity;
        productSales[item.product.name] = (productSales[item.product.name] ?? 0) + item.quantity;
      }
    }

    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedMonth = picked);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard('Revenue', '₹${totalRevenue.toStringAsFixed(2)}', Colors.green),
                const SizedBox(width: 16),
                _buildStatCard('Orders', '${filteredInvoices.length}', Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard('Items Sold', '$totalItemsSold', Colors.orange),
            const SizedBox(height: 32),
            const Text('Product Wise Sales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (sortedProducts.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No data for this month')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedProducts.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final entry = sortedProducts[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key),
                    trailing: Text('${entry.value} units', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonFooter(),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
