import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hospital_management_app/models/billing.dart';
import 'package:hospital_management_app/models/patient.dart';
import 'package:hospital_management_app/models/appointment.dart';
import 'package:hospital_management_app/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  // Filter variables
  String _filterStatus = 'all'; // all, pending, paid, overdue
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  // Statistics
  Map<String, dynamic> _stats = {
    'totalRevenue': 0.0,
    'pendingAmount': 0.0,
    'todayCollection': 0.0,
    'overdueAmount': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBillingStats();
  }

  Future<void> _loadBillingStats() async {
    // Load billing statistics
    // This would fetch actual data from the database
    setState(() {
      _stats = {
        'totalRevenue': 125400.0,
        'pendingAmount': 23500.0,
        'todayCollection': 4520.0,
        'overdueAmount': 8300.0,
      };
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  //------------------------- Billing Management ---------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Print Summary'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'export') {
                _exportBillingReport();
              } else if (value == 'print') {
                _printBillingSummary();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Bills'),
            Tab(text: 'Payments'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildBillsTab(),
          _buildPaymentsTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewBill,
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          _buildStatisticsCards(),
          const SizedBox(height: 24),

          // Revenue Chart
          _buildRevenueChart(),
          const SizedBox(height: 24),

          // Payment Methods Distribution
          _buildPaymentMethodsChart(),
          const SizedBox(height: 24),

          // Recent Transactions
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Revenue',
                _formatCurrency(_stats['totalRevenue']),
                Icons.account_balance_wallet,
                Colors.green,
                '+15% from last month',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending Amount',
                _formatCurrency(_stats['pendingAmount']),
                Icons.pending_actions,
                Colors.orange,
                '{_calculatePendingBills()} bills',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Today\'s Collection',
                _formatCurrency(_stats['todayCollection']),
                Icons.today,
                Colors.blue,
                '${_calculateTodayTransactions()} transactions',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Overdue Amount',
                _formatCurrency(_stats['overdueAmount']),
                Icons.warning,
                Colors.red,
                'Requires attention',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color,
      String subtitle,
      ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (title == 'Total Revenue')
                  const Icon(
                    Icons.trending_up,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //------------------------- Revenue Trend -------------------------
  Widget _buildRevenueChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Revenue Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: 'This Week',
                  items: ['This Week', 'This Month', 'This Year']
                      .map((period) => DropdownMenuItem(
                    value: period,
                    child: Text(
                      period,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    // Update chart period
                  },
                  underline: const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 6000,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      //tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.toStringAsFixed(0),
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (index + 1) * 800.0,
                          color: Theme.of(context).primaryColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsChart() {
    final paymentMethods = [
      {'method': 'Cash', 'amount': 45000, 'color': Colors.green},
      {'method': 'Card', 'amount': 38000, 'color': Colors.blue},
      {'method': 'Insurance', 'amount': 32000, 'color': Colors.orange},
      {'method': 'Bank Transfer', 'amount': 10400, 'color': Colors.purple},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: paymentMethods.map((method) {
                        final total = paymentMethods.fold<int>(
                          0,
                              (sum, m) => sum + (m['amount'] as int),
                        );
                        final percentage = ((method['amount'] as int) / total * 100);

                        return PieChartSectionData(
                          color: method['color'] as Color,
                          value: (method['amount'] as int).toDouble(),
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: paymentMethods.map((method) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: method['color'] as Color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                method['method'] as String,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            Text(
                              _formatCurrency(method['amount'] as int),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //------------------------- Recent Transactions --------------------------
  Widget _buildRecentTransactions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(2);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(5, (index) {
              final isCredit = index % 2 == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCredit
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_downward : Icons.receipt,
                        color: isCredit ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isCredit ? 'Payment Received' : 'Bill Generated',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, y - HH:mm').format(
                              DateTime.now().subtract(
                                Duration(hours: index * 2),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (500 + index * 50).toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCredit ? Colors.green : Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCredit
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isCredit ? 'PAID' : 'PENDING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCredit ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  //----------------------- Billing Management -----------------------
  Widget _buildBillsTab() {
    return Column(
      children: [
        // Filter Bar
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Paid', 'paid'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Overdue', 'overdue'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Partial', 'partial'),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _showSortOptions,
              ),
            ],
          ),
        ),

        // Bills List
        Expanded(
          child: StreamBuilder<List<Billing>>(
            stream: _getFilteredBills(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bills found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createNewBill,
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Bill'),
                      ),
                    ],
                  ),
                );
              }

              final bills = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  return _buildBillCard(bill);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  //-------------------------- Bill --------------------------
  Widget _buildBillCard(Billing bill) {
    final isPaid = bill.paymentStatus == 'paid';
    final isOverdue = !isPaid &&
        bill.billDate.isBefore(DateTime.now().subtract(const Duration(days: 30)));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBillDetails(bill),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.green.withOpacity(0.1)
                              : isOverdue
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPaid
                              ? Icons.check_circle
                              : isOverdue
                              ? Icons.warning
                              : Icons.pending,
                          color: isPaid
                              ? Colors.green
                              : isOverdue
                              ? Colors.red
                              : Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bill #${bill.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, y').format(bill.billDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'print',
                        child: Row(
                          children: [
                            Icon(Icons.print),
                            SizedBox(width: 8),
                            Text('Print Invoice'),
                          ],
                        ),
                      ),
                      if (!isPaid)
                        const PopupMenuItem(
                          value: 'payment',
                          child: Row(
                            children: [
                              Icon(Icons.payment),
                              SizedBox(width: 8),
                              Text('Record Payment'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'email',
                        child: Row(
                          children: [
                            Icon(Icons.email),
                            SizedBox(width: 8),
                            Text('Send Email'),
                          ],
                        ),
                      ),
                      if (!isPaid)
                        const PopupMenuItem(
                          value: 'reminder',
                          child: Row(
                            children: [
                              Icon(Icons.notification_add),
                              SizedBox(width: 8),
                              Text('Send Reminder'),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        _showBillDetails(bill);
                      } else if (value == 'print') {
                        _printInvoice(bill);
                      } else if (value == 'payment') {
                        _recordPayment(bill);
                      } else if (value == 'email') {
                        _sendBillEmail(bill);
                      } else if (value == 'reminder') {
                        _sendPaymentReminder(bill);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Patient Info
              FutureBuilder<Patient?>(
                future: _databaseService.getPatient(bill.patientId),
                builder: (context, snapshot) {
                  final patient = snapshot.data;
                  return Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        patient?.fullName ?? 'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              // Bill Items Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildBillRow('Consultation', '\$${bill.consultationFee}'),
                    if (bill.items.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...bill.items.take(2).map((item) {
                        return _buildBillRow(
                          item.description,
                          '\$${item.total.toStringAsFixed(2)}',
                        );
                      }),
                      if (bill.items.length > 2) ...[
                        const SizedBox(height: 4),
                        Text(
                          '+ {bill.items.length - 2} more items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                    const Divider(height: 16),
                    _buildBillRow(
                      'Total Amount',
                      bill.totalAmount.toStringAsFixed(2),
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Payment Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green.withOpacity(0.1)
                          : isOverdue
                          ? Colors.red.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle
                              : isOverdue
                              ? Icons.warning
                              : Icons.pending,
                          size: 14,
                          color: isPaid
                              ? Colors.green
                              : isOverdue
                              ? Colors.red
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaid
                              ? 'PAID'
                              : isOverdue
                              ? 'OVERDUE'
                              : 'PENDING',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? Colors.green
                                : isOverdue
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPaid && bill.paymentDate != null)
                    Text(
                      'Paid on ${DateFormat('MMM d').format(bill.paymentDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  //----------------------------- Payment ---------------------------
  Widget _buildPaymentsTab() {
    return Column(
      children: [
        // Payment Statistics
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildPaymentStatCard(
                  'Today\'s Collection',
                  '4,520',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentStatCard(
                  'This Week',
                  '28,400',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentStatCard(
                  'This Month',
                  '125,400',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ),

        // Payments List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 20,
            itemBuilder: (context, index) {
              return _buildPaymentCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(int index) {
    final paymentMethods = ['Cash', 'Card', 'Insurance', 'Bank Transfer'];
    final method = paymentMethods[index % paymentMethods.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPaymentIcon(method),
            color: Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          'Payment #${1000 + index}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient ${index + 1}'),
            Text(
              DateFormat('MMM d, y - HH:mm').format(
                DateTime.now().subtract(Duration(hours: index)),
              ),
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              (500 + index * 50).toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                method,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //-------------------------- Reports -------------------------------
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Reports
          const Text(
            'Quick Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReportButton(
                  'Daily Report',
                  Icons.today,
                  Colors.blue,
                      () => _generateReport('daily'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportButton(
                  'Weekly Report',
                  Icons.date_range,
                  Colors.green,
                      () => _generateReport('weekly'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildReportButton(
                  'Monthly Report',
                  Icons.calendar_month,
                  Colors.orange,
                      () => _generateReport('monthly'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportButton(
                  'Custom Report',
                  Icons.analytics,
                  Colors.purple,
                      () => _showCustomReportDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Department-wise Collection
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Department-wise Collection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDepartmentRow('Cardiology', 45000),
                  _buildDepartmentRow('Neurology', 38000),
                  _buildDepartmentRow('Orthopedics', 32000),
                  _buildDepartmentRow('Pediatrics', 28000),
                  _buildDepartmentRow('General Medicine', 25000),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Insurance Claims
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Insurance Claims',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // View all claims
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInsuranceRow('LabAid', 12, 23000, 'approved'),
                  _buildInsuranceRow('Sondhani', 8, 18000, 'pending'),
                  _buildInsuranceRow('CityMedical', 15, 31000, 'approved'),
                  _buildInsuranceRow('Prience', 6, 14000, 'rejected'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentRow(String department, double amount) {
    final percentage = (amount / 168000 * 100); // Total of all departments

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                department,
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                '\$${_formatCurrency(amount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceRow(
      String provider,
      int claims,
      double amount,
      String status,
      ) {
    Color statusColor = status == 'approved'
        ? Colors.green
        : status == 'pending'
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$claims claims',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? value : 'all';
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  void _createNewBill() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateBillScreen(),
      ),
    );
  }

  void _showBillDetails(Billing bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BillDetailsBottomSheet(bill: bill),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Bills'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter bill ID or patient name',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Apply search
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bills'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date Range'),
              subtitle: Text(
                _startDate != null && _endDate != null
                    ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                    : 'All dates',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTimeRange? range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  setState(() {
                    _startDate = range.start;
                    _endDate = range.end;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Apply filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date (Newest First)'),
              onTap: () {
                Navigator.pop(context);
                // Sort by date
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date (Oldest First)'),
              onTap: () {
                Navigator.pop(context);
                // Sort by date
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Amount (High to Low)'),
              onTap: () {
                Navigator.pop(context);
                // Sort by amount
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Amount (Low to High)'),
              onTap: () {
                Navigator.pop(context);
                // Sort by amount
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Patient Name (A-Z)'),
              onTap: () {
                Navigator.pop(context);
                // Sort by patient name
              },
            ),
          ],
        ),
      ),
    );
  }

  void _recordPayment(Billing bill) {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(bill: bill),
    );
  }

  Future<void> _printInvoice(Billing bill) async {
    final pdf = await _generateInvoicePDF(bill);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'invoice_${bill.id}.pdf',
    );
  }

  Future<pw.Document> _generateInvoicePDF(Billing bill) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              color: PdfColors.blue50,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'HOSPITAL INVOICE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Hospital Management System'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #${bill.id.substring(0, 8)}'),
                      pw.Text(DateFormat('MMM d, y').format(bill.billDate)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Patient Details
            pw.Text(
              'BILL TO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            // Add patient details here

            pw.SizedBox(height: 20),

            // Bill Items
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Description'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Amount'),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Consultation Fee'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('\$${bill.consultationFee}'),
                    ),
                  ],
                ),
                ...bill.items.map(
                      (item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.description),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('\$${item.total}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Total
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                color: PdfColors.grey100,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${bill.subtotal}'),
                    pw.Text('Tax: ${bill.tax}'),
                    if (bill.discount > 0)
                      pw.Text('Discount: -${bill.discount}'),
                    pw.Divider(),
                    pw.Text(
                      'Total: ${bill.totalAmount}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  void _exportBillingReport() {
    // Export billing report to Excel/CSV
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting billing report...'),
      ),
    );
  }

  void _printBillingSummary() {
    // Print billing summary
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing billing summary for print...'),
      ),
    );
  }

  void _generateReport(String period) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $period report...'),
      ),
    );
  }

  void _showCustomReportDialog() {
    showDialog(
      context: context,
      builder: (context) => const CustomReportDialog(),
    );
  }

  void _sendBillEmail(Billing bill) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending bill via email...'),
      ),
    );
  }

  void _sendPaymentReminder(Billing bill) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment reminder sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Stream<List<Billing>> _getFilteredBills() {
    // This would return filtered bills based on _filterStatus
    // For now, returning empty stream
    return Stream.value([]);
  }

  String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  int _calculatePendingBills() {
    // Calculate number of pending bills
    return 23;
  }

  int _calculateTodayTransactions() {
    // Calculate today's transactions
    return 12;
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money;
      case 'Card':
        return Icons.credit_card;
      case 'Insurance':
        return Icons.health_and_safety;
      case 'Bank Transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }
}

// Additional Widgets

class CreateBillScreen extends StatelessWidget {
  const CreateBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation for creating new bill
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Bill'),
      ),
      body: const Center(
        child: Text('Create Bill Form'),
      ),
    );
  }
}

class BillDetailsBottomSheet extends StatelessWidget {
  final Billing bill;

  const BillDetailsBottomSheet({
    super.key,
    required this.bill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bill Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Add bill details here
          const Text('Bill details content...'),
        ],
      ),
    );
  }
}

class RecordPaymentDialog extends StatelessWidget {
  final Billing bill;

  const RecordPaymentDialog({
    super.key,
    required this.bill,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment form fields
          const TextField(
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Payment Method',
            ),
            items: ['Cash', 'Card', 'Insurance', 'Bank Transfer']
                .map((method) => DropdownMenuItem(
              value: method,
              child: Text(method),
            ))
                .toList(),
            onChanged: (value) {},
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Process payment
          },
          child: const Text('Record Payment'),
        ),
      ],
    );
  }
}

class CustomReportDialog extends StatelessWidget {
  const CustomReportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Custom Report'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom report configuration
          Text('Configure your custom report'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Generate custom report
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }
}