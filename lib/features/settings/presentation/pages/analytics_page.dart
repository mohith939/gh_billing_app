import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/widgets/common_footer.dart';
import '../../../billing/data/models/invoice_model.dart';

enum AnalyticsFilter { today, weekly, monthly, custom }

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsFilter _selectedFilter = AnalyticsFilter.monthly;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _applyFilter(AnalyticsFilter.monthly);
  }

  void _applyFilter(AnalyticsFilter filter) {
    final now = DateTime.now();
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case AnalyticsFilter.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case AnalyticsFilter.weekly:
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
          _endDate = now;
          break;
        case AnalyticsFilter.monthly:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case AnalyticsFilter.custom:
          // Keep existing dates or let user pick
          break;
      }
    });
  }

  List<InvoiceModel> _getFilteredInvoices() {
    final email = HiveDatabase.settingsBox.get('logged_in_user');
    if (email == null) return [];

    return HiveDatabase.invoiceBox.values.where((invoice) {
      final isSameUser = invoice.userEmail == email;
      final isWithinDateRange = invoice.dateTime.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          invoice.dateTime.isBefore(_endDate.add(const Duration(days: 1)));
      return isSameUser && isWithinDateRange;
    }).toList();
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _selectedFilter = AnalyticsFilter.custom;
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
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
            icon: const Icon(Icons.date_range),
            onPressed: _selectCustomRange,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AnalyticsFilter>(
                  value: _selectedFilter,
                  isExpanded: true,
                  onChanged: (AnalyticsFilter? newValue) {
                    if (newValue != null) {
                      if (newValue == AnalyticsFilter.custom) {
                        _selectCustomRange();
                      } else {
                        _applyFilter(newValue);
                      }
                    }
                  },
                  items: [
                    const DropdownMenuItem(value: AnalyticsFilter.today, child: Text('Today')),
                    const DropdownMenuItem(value: AnalyticsFilter.weekly, child: Text('This Week')),
                    const DropdownMenuItem(value: AnalyticsFilter.monthly, child: Text('This Month')),
                    const DropdownMenuItem(value: AnalyticsFilter.custom, child: Text('Custom Range')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Range: ${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
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
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No sales found for this range')))
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
