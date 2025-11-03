import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_app/services/auth_service.dart';
import 'package:hospital_management_app/services/database_service.dart';
import 'package:hospital_management_app/models/patient.dart';
import 'package:hospital_management_app/models/doctor.dart';
import 'package:hospital_management_app/models/appointment.dart';
import 'package:hospital_management_app/models/billing.dart';
import 'package:hospital_management_app/screens/admin/billing_screen.dart';
import 'package:hospital_management_app/screens/admin/reports_screen.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  int _selectedIndex = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  // Date range for analytics
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _databaseService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildDashboard(),
      _buildUsersManagement(),
      _buildAppointmentsManagement(),
      _buildFinancialOverview(),
      _buildSettings(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money),
            label: 'Financial',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthService>().signOut();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadDashboardStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(),
              const SizedBox(height: 20),

              // Quick Stats Grid
              _buildQuickStats(),
              const SizedBox(height: 20),

              // Revenue Chart
              _buildRevenueChart(),
              const SizedBox(height: 20),

              // Department Overview
              _buildDepartmentOverview(),
              const SizedBox(height: 20),

              // Recent Activities
              _buildRecentActivities(),
              const SizedBox(height: 20),

              // Quick Actions
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple,
              Colors.deepPurple.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Admin',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hospital Management System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'System Operational',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Patients',
          _stats['totalPatients']?.toString() ?? '0',
          Icons.people,
          Colors.blue,
          '+12% from last month',
          true,
        ),
        _buildStatCard(
          'Total Doctors',
          _stats['totalDoctors']?.toString() ?? '0',
          Icons.medical_services,
          Colors.green,
          '+5% from last month',
          true,
        ),
        _buildStatCard(
          'Today\'s Appointments',
          _stats['todayAppointments']?.toString() ?? '0',
          Icons.calendar_today,
          Colors.orange,
          'Active appointments',
          false,
        ),
        _buildStatCard(
          'Pending Bills',
          _stats['pendingBills']?.toString() ?? '0',
          Icons.receipt_long,
          Colors.red,
          'Requires attention',
          false,
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
                  Icon(
                    Icons.trending_up,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
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
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: showTrend ? Colors.green : Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
                  'Revenue Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: 'This Month',
                  items: ['This Week', 'This Month', 'This Year']
                      .map((period) => DropdownMenuItem(
                    value: period,
                    child: Text(period, style: const TextStyle(fontSize: 14)),
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
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1000,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 5000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3000),
                        const FlSpot(1, 3500),
                        const FlSpot(2, 3200),
                        const FlSpot(3, 4100),
                        const FlSpot(4, 3800),
                        const FlSpot(5, 4500),
                        const FlSpot(6, 4200),
                      ],
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChartLegend('Total Revenue', '\$25,400', Colors.green),
                _buildChartLegend('Avg. Daily', '\$3,628', Colors.blue),
                _buildChartLegend('Growth', '+18%', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentOverview() {
    final departments = [
      {'name': 'Cardiology', 'patients': 45, 'doctors': 8, 'color': Colors.red},
      {'name': 'Neurology', 'patients': 32, 'doctors': 6, 'color': Colors.purple},
      {'name': 'Orthopedics', 'patients': 28, 'doctors': 5, 'color': Colors.blue},
      {'name': 'Pediatrics', 'patients': 38, 'doctors': 7, 'color': Colors.green},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: departments.map((dept) {
                    final total = departments.fold<int>(
                      0,
                          (sum, d) => sum + (d['patients'] as int),
                    );
                    final percentage = ((dept['patients'] as int) / total * 100);

                    return PieChartSectionData(
                      color: dept['color'] as Color,
                      value: (dept['patients'] as int).toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...departments.map((dept) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: dept['color'] as Color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dept['name'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${dept['patients']} patients',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${dept['doctors']} doctors',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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

  Widget _buildRecentActivities() {
    final activities = [
      {
        'type': 'appointment',
        'title': 'New appointment scheduled',
        'subtitle': 'John Doe with Dr. Smith',
        'time': '5 minutes ago',
        'icon': Icons.calendar_today,
        'color': Colors.blue,
      },
      {
        'type': 'patient',
        'title': 'New patient registered',
        'subtitle': 'Jane Wilson',
        'time': '15 minutes ago',
        'icon': Icons.person_add,
        'color': Colors.green,
      },
      {
        'type': 'payment',
        'title': 'Payment received',
        'subtitle': '\$450 from Michael Brown',
        'time': '1 hour ago',
        'icon': Icons.payment,
        'color': Colors.orange,
      },
      {
        'type': 'doctor',
        'title': 'Doctor status updated',
        'subtitle': 'Dr. Johnson is now available',
        'time': '2 hours ago',
        'icon': Icons.medical_services,
        'color': Colors.purple,
      },
    ];

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
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all activities
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...activities.map((activity) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: activity['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            activity['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      activity['time'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
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

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Add Patient',
                    Icons.person_add,
                    Colors.blue,
                        () {
                      // Navigate to add patient
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Add Doctor',
                    Icons.medical_services,
                    Colors.green,
                        () {
                      // Navigate to add doctor
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Generate Report',
                    Icons.analytics,
                    Colors.orange,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Backup Data',
                    Icons.backup,
                    Colors.purple,
                        () {
                      _showBackupDialog();
                    },
                  ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersManagement() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Patients'),
              Tab(text: 'Doctors'),
              Tab(text: 'Staff'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Implement search
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // Implement filter
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                // Add new user
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildPatientsList(),
            _buildDoctorsList(),
            _buildStaffList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsList() {
    return StreamBuilder<List<Patient>>(
      stream: _databaseService.getAllPatients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No patients found'),
          );
        }

        final patients = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    patient.firstName.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  patient.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${patient.id.substring(0, 8)}'),
                    Text('Phone: ${patient.phone}'),
                    Text(
                      'Registered: ${DateFormat('MMM d, y').format(patient.registrationDate)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
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
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'view') {
                      _showPatientDetails(patient);
                    } else if (value == 'edit') {
                      // Edit patient
                    } else if (value == 'delete') {
                      _confirmDelete('patient', patient.id);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoctorsList() {
    return StreamBuilder<List<Doctor>>(
      stream: _databaseService.getAllDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No doctors found'),
          );
        }

        final doctors = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(doctor.status).withOpacity(0.1),
                  child: Text(
                    doctor.firstName.substring(0, 1),
                    style: TextStyle(
                      color: _getStatusColor(doctor.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  'Dr. ${doctor.fullName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.specialization),
                    Text('License: ${doctor.licenseNumber}'),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(doctor.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.status,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getStatusColor(doctor.status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
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
                      value: 'schedule',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text('View Schedule'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'disable',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Disable Account',
                              style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'view') {
                      _showDoctorDetails(doctor);
                    } else if (value == 'schedule') {
                      // View schedule
                    } else if (value == 'edit') {
                      // Edit doctor
                    } else if (value == 'disable') {
                      _confirmDisable('doctor', doctor.id);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStaffList() {
    // Sample staff data
    final staff = [
      {'name': 'Sarah Johnson', 'role': 'Nurse', 'department': 'Emergency'},
      {'name': 'Mike Wilson', 'role': 'Receptionist', 'department': 'Front Desk'},
      {'name': 'Emily Brown', 'role': 'Lab Technician', 'department': 'Laboratory'},
      {'name': 'David Lee', 'role': 'Pharmacist', 'department': 'Pharmacy'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staff.length,
      itemBuilder: (context, index) {
        final member = staff[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.1),
              child: Text(
                member['name']!.substring(0, 1),
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['role']!),
                Text(
                  member['department']!,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show options
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsManagement() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // Show calendar view
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filter appointments
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Scheduled'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
              isScrollable: true,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAppointmentsList('all'),
                  _buildAppointmentsList('scheduled'),
                  _buildAppointmentsList('completed'),
                  _buildAppointmentsList('cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(String status) {
    // This would fetch appointments based on status
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAppointmentStatusColor(status).withOpacity(0.1),
              child: Icon(
                _getAppointmentIcon(status),
                color: _getAppointmentStatusColor(status),
              ),
            ),
            title: const Text(
              'John Doe - Dr. Smith',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateFormat('MMM d, y').format(DateTime.now())}'),
                const Text('Time: 10:00 AM'),
                Text(
                  'Status: ${status.toUpperCase()}',
                  style: TextStyle(
                    color: _getAppointmentStatusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Text('View Details'),
                ),
                if (status == 'scheduled')
                  const PopupMenuItem(
                    value: 'reschedule',
                    child: Text('Reschedule'),
                  ),
                if (status == 'scheduled')
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancel'),
                  ),
              ],
              onSelected: (value) {
                // Handle action
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialOverview() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Export financial report
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Print report
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildFinancialCard(
                    'Total Revenue',
                    '\$125,400',
                    Icons.attach_money,
                    Colors.green,
                    '+15%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFinancialCard(
                    'Pending Payments',
                    '\$12,300',
                    Icons.pending,
                    Colors.orange,
                    '23 bills',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialCard(
                    'Today\'s Collection',
                    '\$4,520',
                    Icons.today,
                    Colors.blue,
                    '12 transactions',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFinancialCard(
                    'Monthly Average',
                    '\$35,200',
                    Icons.analytics,
                    Colors.purple,
                    '+8%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Billing Management Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BillingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Manage Billing'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recent Transactions
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(
                      Icons.payment,
                      color: Colors.green,
                    ),
                  ),
                  title: Text('Patient ${index + 1}'),
                  subtitle: Text(
                    'Bill #${1000 + index} - ${DateFormat('MMM d, y').format(DateTime.now())}',
                  ),
                  trailing: Text(
                    '\$${(500 + index * 50).toString()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(
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
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // System Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'System Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Hospital Information'),
                  subtitle: const Text('Update hospital details'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to hospital info
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Working Hours'),
                  subtitle: const Text('Set hospital operating hours'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to working hours
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.local_hospital),
                  title: const Text('Departments'),
                  subtitle: const Text('Manage hospital departments'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to departments
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Access Control'),
                  subtitle: const Text('Manage user permissions'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to access control
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup & Restore'),
                  subtitle: const Text('Manage data backups'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showBackupDialog();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Audit Logs'),
                  subtitle: const Text('View system activity logs'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to audit logs
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notification Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive system alerts via email'),
                  value: true,
                  onChanged: (value) {
                    // Toggle email notifications
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('SMS Notifications'),
                  subtitle: const Text('Send appointment reminders via SMS'),
                  value: false,
                  onChanged: (value) {
                    // Toggle SMS notifications
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notification_important),
                  title: const Text('Alert Settings'),
                  subtitle: const Text('Configure system alerts'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to alert settings
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Patient ID', patient.id.substring(0, 8)),
              _buildDetailRow('Email', patient.email),
              _buildDetailRow('Phone', patient.phone),
              _buildDetailRow('Blood Group', patient.bloodGroup),
              _buildDetailRow('Age', '${patient.age} years'),
              _buildDetailRow('Address', patient.address),
              if (patient.allergies.isNotEmpty)
                _buildDetailRow('Allergies', patient.allergies.join(', ')),
              if (patient.chronicConditions.isNotEmpty)
                _buildDetailRow(
                  'Conditions',
                  patient.chronicConditions.join(', '),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDoctorDetails(Doctor doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dr. ${doctor.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Doctor ID', doctor.id.substring(0, 8)),
              _buildDetailRow('Email', doctor.email),
              _buildDetailRow('Phone', doctor.phone),
              _buildDetailRow('Specialization', doctor.specialization),
              _buildDetailRow('License', doctor.licenseNumber),
              _buildDetailRow('Experience', '${doctor.experienceYears} years'),
              _buildDetailRow('Consultation Fee', '\$${doctor.consultationFee}'),
              _buildDetailRow('Working Days', doctor.availableDays.join(', ')),
              _buildDetailRow('Timing', '${doctor.startTime} - ${doctor.endTime}'),
              _buildDetailRow('Status', doctor.status),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmDelete(String type, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this $type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete the record
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$type deleted successfully'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDisable(String type, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Disable'),
        content: Text('Are you sure you want to disable this $type account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Disable the account
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$type account disabled'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.backup,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text('Create a backup of all hospital data?'),
            const SizedBox(height: 8),
            Text(
              'Last backup: ${DateFormat('MMM d, y HH:mm').format(
                DateTime.now().subtract(const Duration(days: 7)),
              )}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
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
              // Simulate backup
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                      SizedBox(width: 16),
                      Text('Creating backup...'),
                    ],
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Start Backup'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getAppointmentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'all':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getAppointmentIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'all':
        return Icons.list;
      default:
        return Icons.circle;
    }
  }
}