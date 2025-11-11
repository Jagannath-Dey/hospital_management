import 'package:flutter/material.dart';
import 'package:hospital_management_app/services/database_service.dart';
import 'package:hospital_management_app/models/patient.dart';
import 'package:hospital_management_app/models/doctor.dart';
import 'package:hospital_management_app/models/appointment.dart';
import 'package:hospital_management_app/models/billing.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  // Date range selection
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'This Month';

  // Report data
  Map<String, dynamic> _reportData = {};
  bool _isLoading = true;

  // Filters
  String? _selectedDepartment;
  String? _selectedDoctor;
  final String _reportType = 'comprehensive';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      // Load comprehensive report data
      final stats = await _databaseService.getDashboardStats();

      setState(() {
        _reportData = {
          'patients': {
            'total': stats['totalPatients'] ?? 0,
            'new': 45,
            'active': 280,
            'inactive': 65,
          },
          'appointments': {
            'total': 1250,
            'completed': 980,
            'cancelled': 120,
            'noShow': 50,
            'upcoming': 100,
          },
          'financial': {
            'totalRevenue': 458900.0,
            'collected': 398500.0,
            'pending': 60400.0,
            'avgBillValue': 367.12,
          },
          'doctors': {
            'total': stats['totalDoctors'] ?? 0,
            'available': 28,
            'onLeave': 4,
            'avgPatientsPerDay': 12.5,
          },
          'departments': [
            {'name': 'Cardiology', 'revenue': 125000, 'patients': 320},
            {'name': 'Neurology', 'revenue': 98000, 'patients': 245},
            {'name': 'Orthopedics', 'revenue': 87000, 'patients': 198},
            {'name': 'Pediatrics', 'revenue': 76000, 'patients': 412},
            {'name': 'General Medicine', 'revenue': 72900, 'patients': 523},
          ],
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading report data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export as Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Print Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share Report'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'export_pdf':
                  _exportAsPDF();
                  break;
                case 'export_excel':
                  _exportAsExcel();
                  break;
                case 'print':
                  _printReport();
                  break;
                case 'share':
                  _shareReport();
                  break;
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Patient Analytics'),
            Tab(text: 'Financial Reports'),
            Tab(text: 'Performance'),
            Tab(text: 'Custom Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPatientAnalyticsTab(),
          _buildFinancialReportsTab(),
          _buildPerformanceTab(),
          _buildCustomReportsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Selector
          _buildDateRangeSelector(),
          const SizedBox(height: 20),

          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Key Metrics Chart
          _buildKeyMetricsChart(),
          const SizedBox(height: 24),

          // Department Performance
          _buildDepartmentPerformance(),
          const SizedBox(height: 24),

          // Trends Analysis
          _buildTrendsAnalysis(),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPeriodChip('Today', 'today'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('This Week', 'week'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('This Month', 'month'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('This Quarter', 'quarter'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('This Year', 'year'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Custom', 'custom'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedPeriod == 'custom') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(DateFormat('MMM d, y').format(_startDate)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to'),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(DateFormat('MMM d, y').format(_endDate)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == label;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = label;
            _updateDateRange(value);
          });
        }
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      switch (period) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'quarter':
          final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
          _startDate = DateTime(now.year, quarterMonth, 1);
          _endDate = now;
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
      }
    });
    _loadReportData();
  }

  Widget _buildSummaryCards() {
    final patients = _reportData['patients'] ?? {};
    final appointments = _reportData['appointments'] ?? {};
    final financial = _reportData['financial'] ?? {};
    final doctors = _reportData['doctors'] ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Patients',
          patients['total'].toString(),
          Icons.people,
          Colors.blue,
          '+${patients['new']} new',
          true,
        ),
        _buildMetricCard(
          'Appointments',
          appointments['total'].toString(),
          Icons.calendar_today,
          Colors.green,
          '${appointments['completed']} completed',
          false,
        ),
        _buildMetricCard(
          'Revenue',
          '${_formatCurrency(financial['totalRevenue'])}',
          Icons.attach_money,
          Colors.orange,
          '${((financial['collected'] / financial['totalRevenue']) * 100).toStringAsFixed(1)}% collected',
          true,
        ),
        _buildMetricCard(
          'Avg Satisfaction',
          '4.5/5.0',
          Icons.star,
          Colors.purple,
          'Based on ${doctors['total'] * 15} reviews',
          false,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title,
      String value,
      IconData icon,
      Color color,
      String subtitle,
      bool showTrend,
      ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  child: Icon(icon, color: color, size: 20),
                ),
                if (showTrend)
                  const Icon(
                    Icons.trending_up,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
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

  Widget _buildKeyMetricsChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Performance Indicators',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  radarBorderData: const BorderSide(color: Colors.grey),
                  gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
                  titleTextStyle: const TextStyle(fontSize: 12),
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  tickBorderData: const BorderSide(color: Colors.transparent),
                  getTitle: (index, angle) {
                    switch (index) {
                      case 0:
                        return const RadarChartTitle(text: 'Patient\nSatisfaction');
                      case 1:
                        return const RadarChartTitle(text: 'Bed\nOccupancy');
                      case 2:
                        return const RadarChartTitle(text: 'Staff\nEfficiency');
                      case 3:
                        return const RadarChartTitle(text: 'Revenue\nGrowth');
                      case 4:
                        return const RadarChartTitle(text: 'Wait\nTime');
                      default:
                        return const RadarChartTitle(text: '');
                    }
                  },
                  tickCount: 5,
                  ticksTextStyle: const TextStyle(fontSize: 10, color: Colors.transparent),
                  dataSets: [
                    RadarDataSet(
                      fillColor: Theme.of(context).primaryColor.withOpacity(0.3),
                      borderColor: Theme.of(context).primaryColor,
                      dataEntries: const [
                        RadarEntry(value: 85),
                        RadarEntry(value: 75),
                        RadarEntry(value: 90),
                        RadarEntry(value: 70),
                        RadarEntry(value: 80),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKPIIndicator('Excellent', Colors.green, 80),
                _buildKPIIndicator('Good', Colors.orange, 60),
                _buildKPIIndicator('Needs Improvement', Colors.red, 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIIndicator(String label, Color color, int threshold) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label (>$threshold%)',
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDepartmentPerformance() {
    final departments = _reportData['departments'] as List? ?? [];

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
                  'Department Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Show detailed department report
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 150000,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      //tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final dept = departments[group.x.toInt()];
                        return BarTooltipItem(
                          '${dept['name']}\n${_formatCurrency(rod.toY)}\n${dept['patients']} patients',
                          const TextStyle(color: Colors.white, fontSize: 10),
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
                          if (value.toInt() < departments.length) {
                            return RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                departments[value.toInt()]['name'].toString().substring(0, 4),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 30000,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(departments.length, (index) {
                    final dept = departments[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: dept['revenue'].toDouble(),
                          color: _getDepartmentColor(index),
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
            const SizedBox(height: 16),
            // Department Details Table
            ...departments.map((dept) {
              final revenue = dept['revenue'] as int;
              final patients = dept['patients'] as int;
              final avgRevenue = revenue / patients;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getDepartmentColor(departments.indexOf(dept)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dept['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${patients} patients | Avg: \$${avgRevenue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatCurrency(revenue)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trends Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
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
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 100,
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: 500,
                  lineBarsData: [
                    // Patients Line
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 320),
                        FlSpot(1, 350),
                        FlSpot(2, 380),
                        FlSpot(3, 390),
                        FlSpot(4, 420),
                        FlSpot(5, 450),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    // Appointments Line
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 280),
                        FlSpot(1, 300),
                        FlSpot(2, 320),
                        FlSpot(3, 310),
                        FlSpot(4, 340),
                        FlSpot(5, 360),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                    // Revenue Line (scaled down)
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 200),
                        FlSpot(1, 220),
                        FlSpot(2, 240),
                        FlSpot(3, 235),
                        FlSpot(4, 260),
                        FlSpot(5, 280),
                      ],
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrendLegend('Patients', Colors.blue, '+12.5%'),
                _buildTrendLegend('Appointments', Colors.green, '+8.2%'),
                _buildTrendLegend('Revenue (×100)', Colors.orange, '+15.3%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendLegend(String label, Color color, String growth) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              growth,
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Report Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                _buildActionButton(
                  'Generate\nMonthly',
                  Icons.calendar_month,
                  Colors.blue,
                      () => _generateReport('monthly'),
                ),
                _buildActionButton(
                  'Financial\nSummary',
                  Icons.attach_money,
                  Colors.green,
                      () => _generateReport('financial'),
                ),
                _buildActionButton(
                  'Patient\nReport',
                  Icons.people,
                  Colors.orange,
                      () => _generateReport('patient'),
                ),
                _buildActionButton(
                  'Doctor\nPerformance',
                  Icons.medical_services,
                  Colors.purple,
                      () => _generateReport('doctor'),
                ),
                _buildActionButton(
                  'Department\nAnalysis',
                  Icons.business,
                  Colors.teal,
                      () => _generateReport('department'),
                ),
                _buildActionButton(
                  'Custom\nReport',
                  Icons.analytics,
                  Colors.red,
                      () => _showCustomReportBuilder(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Demographics
          _buildPatientDemographics(),
          const SizedBox(height: 24),

          // Age Distribution
          _buildAgeDistribution(),
          const SizedBox(height: 24),

          // Patient Flow Analysis
          _buildPatientFlowAnalysis(),
          const SizedBox(height: 24),

          // Common Conditions
          _buildCommonConditions(),
        ],
      ),
    );
  }

  Widget _buildPatientDemographics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Demographics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Gender Distribution
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Gender Distribution',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: [
                              PieChartSectionData(
                                color: Colors.blue,
                                value: 45,
                                title: '45%',
                                radius: 40,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.pink,
                                value: 52,
                                title: '52%',
                                radius: 40,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.grey,
                                value: 3,
                                title: '3%',
                                radius: 40,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGenderLegend('Male', Colors.blue, '45%'),
                          const SizedBox(width: 12),
                          _buildGenderLegend('Female', Colors.pink, '52%'),
                          const SizedBox(width: 12),
                          _buildGenderLegend('Other', Colors.grey, '3%'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Location Distribution
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Location Distribution',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _buildLocationBar('Urban', 0.65, Colors.blue),
                      _buildLocationBar('Suburban', 0.25, Colors.green),
                      _buildLocationBar('Rural', 0.10, Colors.orange),
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

  Widget _buildGenderLegend(String label, Color color, String percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label\n$percentage',
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLocationBar(String location, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(location, style: const TextStyle(fontSize: 12)),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeDistribution() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Age Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 200,
                  barTouchData: BarTouchData(enabled: false),
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
                          const ageGroups = [
                            '0-18',
                            '19-30',
                            '31-45',
                            '46-60',
                            '60+',
                          ];
                          if (value.toInt() < ageGroups.length) {
                            return Text(
                              ageGroups[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 50,
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeBarGroup(0, 120, Colors.blue),
                    _makeBarGroup(1, 180, Colors.green),
                    _makeBarGroup(2, 150, Colors.orange),
                    _makeBarGroup(3, 140, Colors.purple),
                    _makeBarGroup(4, 110, Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 30,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientFlowAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Flow Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Heatmap representation of patient visits
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.5,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final intensity = (index % 5 + 1) * 20;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(intensity / 100),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        color: intensity > 60 ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Low', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 8),
                Container(
                  width: 100,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.2),
                        Colors.blue.withOpacity(1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('High', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonConditions() {
    final conditions = [
      {'name': 'Hypertension', 'count': 145, 'percentage': 28},
      {'name': 'Diabetes', 'count': 132, 'percentage': 25},
      {'name': 'Respiratory Issues', 'count': 98, 'percentage': 19},
      {'name': 'Heart Disease', 'count': 76, 'percentage': 15},
      {'name': 'Others', 'count': 69, 'percentage': 13},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Common Conditions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...conditions.map((condition) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          condition['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${condition['count']} patients (${condition['percentage']}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (condition['percentage'] as int) / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getConditionColor(condition['name'] as String),
                      ),
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

  Widget _buildFinancialReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRevenueAnalysis(),
          const SizedBox(height: 24),
          _buildPaymentMethodAnalysis(),
          const SizedBox(height: 24),
          _buildInsuranceAnalysis(),
          const SizedBox(height: 24),
          _buildOutstandingPayments(),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildRevenueMetric(
                  'Total Revenue',
                  '458,900',
                  Icons.trending_up,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildRevenueMetric(
                  'Avg per Patient',
                  '367',
                  Icons.person,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildRevenueMetric(
                  'Collection Rate',
                  '87%',
                  Icons.check_circle,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueMetric(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Payment method breakdown
            _buildPaymentMethodRow('Cash', 180000, 0.39),
            _buildPaymentMethodRow('Credit Card', 120000, 0.26),
            _buildPaymentMethodRow('Insurance', 98000, 0.21),
            _buildPaymentMethodRow('Bank Transfer', 60900, 0.14),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRow(String method, double amount, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getPaymentIcon(method),
                    size: 20,
                    color: _getPaymentColor(method),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    method,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                _formatCurrency(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getPaymentColor(method),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insurance Claims Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Insurance claims data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInsuranceMetric('Submitted', '234', Colors.blue),
                _buildInsuranceMetric('Approved', '198', Colors.green),
                _buildInsuranceMetric('Pending', '28', Colors.orange),
                _buildInsuranceMetric('Rejected', '8', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceMetric(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingPayments() {
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
                  'Outstanding Payments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '60,400',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Aging analysis
            _buildAgingRow('0-30 days', 23000, Colors.green),
            _buildAgingRow('31-60 days', 18000, Colors.orange),
            _buildAgingRow('61-90 days', 12000, Colors.deepOrange),
            _buildAgingRow('90+ days', 7400, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildAgingRow(String period, double amount, Color color) {
    final percentage = amount / 60400;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatCurrency(amount)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDoctorPerformance(),
          const SizedBox(height: 24),
          _buildAppointmentMetrics(),
          const SizedBox(height: 24),
          _buildPatientSatisfaction(),
          const SizedBox(height: 24),
          _buildEfficiencyMetrics(),
        ],
      ),
    );
  }

  Widget _buildDoctorPerformance() {
    final doctors = [
      {'name': 'Dr. Day', 'patients': 145, 'rating': 4.8, 'revenue': 52000},
      {'name': 'Dr. Kumar', 'patients': 132, 'rating': 4.6, 'revenue': 48000},
      {'name': 'Dr. Das', 'patients': 128, 'rating': 4.9, 'revenue': 45000},
      {'name': 'Dr. Kamal', 'patients': 115, 'rating': 4.5, 'revenue': 41000},
      {'name': 'Dr. Debasis', 'patients': 108, 'rating': 4.7, 'revenue': 38000},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...doctors.map((doctor) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        doctor['name'].toString().substring(4, 5),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Icon(Icons.people, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${doctor['patients']} patients',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${doctor['rating']}',
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
                    Text(
                      _formatCurrency(doctor['revenue'] as int),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildAppointmentMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointment Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    'Avg Wait Time',
                    '18 min',
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    'Completion Rate',
                    '92%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    'No Show Rate',
                    '4%',
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    'Reschedule Rate',
                    '8%',
                    Icons.update,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSatisfaction() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Satisfaction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Overall rating
            Center(
              child: Column(
                children: [
                  const Text(
                    '4.5',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < 4.5 ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on 1,234 reviews',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Rating breakdown
            _buildRatingBar('5 stars', 0.65, 802),
            _buildRatingBar('4 stars', 0.20, 247),
            _buildRatingBar('3 stars', 0.10, 123),
            _buildRatingBar('2 stars', 0.03, 37),
            _buildRatingBar('1 star', 0.02, 25),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(String label, double percentage, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operational Efficiency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Efficiency indicators
            _buildEfficiencyIndicator('Bed Occupancy Rate', 0.78, Colors.blue),
            _buildEfficiencyIndicator('Staff Utilization', 0.85, Colors.green),
            _buildEfficiencyIndicator('Equipment Utilization', 0.72, Colors.orange),
            _buildEfficiencyIndicator('Resource Optimization', 0.68, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyIndicator(String label, double value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Report Builder',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Report Templates
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Templates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTemplateChip('Monthly Summary'),
                      _buildTemplateChip('Department Analysis'),
                      _buildTemplateChip('Financial Statement'),
                      _buildTemplateChip('Patient Demographics'),
                      _buildTemplateChip('Performance Review'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Report Configuration
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data Sources
                  const Text(
                    'Data Sources',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildDataSourceChip('Patients', true),
                      _buildDataSourceChip('Appointments', true),
                      _buildDataSourceChip('Billing', false),
                      _buildDataSourceChip('Inventory', false),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metrics to Include
                  const Text(
                    'Metrics to Include',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Revenue Analysis'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  CheckboxListTile(
                    title: const Text('Patient Demographics'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  CheckboxListTile(
                    title: const Text('Appointment Statistics'),
                    value: false,
                    onChanged: (value) {},
                  ),
                  CheckboxListTile(
                    title: const Text('Doctor Performance'),
                    value: false,
                    onChanged: (value) {},
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Preview report
                          },
                          child: const Text('Preview'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _generateCustomReport();
                          },
                          child: const Text('Generate Report'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        // Load template
      },
    );
  }

  Widget _buildDataSourceChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        // Toggle data source
      },
    );
  }

  // Helper Methods
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Department'),
              value: _selectedDepartment,
              items: ['All', 'Cardiology', 'Neurology', 'Orthopedics']
                  .map((dept) => DropdownMenuItem(
                value: dept,
                child: Text(dept),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedDepartment = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Doctor'),
              value: _selectedDoctor,
              items: ['All', 'Dr. Das', 'Dr. Sumit', 'Dr. Dey']
                  .map((doctor) => DropdownMenuItem(
                value: doctor,
                child: Text(doctor),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedDoctor = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDepartment = null;
                _selectedDoctor = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadReportData();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCustomReportBuilder() {
    _tabController.animateTo(4);
  }

  void _generateReport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating $type report...')),
    );
  }

  void _generateCustomReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating custom report...')),
    );
  }

  Future<void> _exportAsPDF() async {
    // Generate PDF
    final pdf = pw.Document();

    // Add report content to PDF
    // ... PDF generation code ...

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'hospital_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  Future<void> _exportAsExcel() async {
    // Create Excel workbook
    // ... Excel generation code ...

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report exported as Excel')),
    );
  }

  void _printReport() {
    // Print report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing report for printing...')),
    );
  }

  void _shareReport() {
    // Share report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing report...')),
    );
  }

  String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat('#,##0');
    return formatter.format(amount);
  }

  Color _getDepartmentColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Hypertension':
        return Colors.red;
      case 'Diabetes':
        return Colors.orange;
      case 'Respiratory Issues':
        return Colors.blue;
      case 'Heart Disease':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money;
      case 'Credit Card':
        return Icons.credit_card;
      case 'Insurance':
        return Icons.health_and_safety;
      case 'Bank Transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String method) {
    switch (method) {
      case 'Cash':
        return Colors.green;
      case 'Credit Card':
        return Colors.blue;
      case 'Insurance':
        return Colors.orange;
      case 'Bank Transfer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}