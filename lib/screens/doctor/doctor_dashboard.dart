import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_app/services/auth_service.dart';
import 'package:hospital_management_app/services/database_service.dart';
import 'package:hospital_management_app/models/doctor.dart';
import 'package:hospital_management_app/models/appointment.dart';
import 'package:hospital_management_app/models/patient.dart';
import 'package:hospital_management_app/screens/doctor/prescription_screen.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final List<Widget> _pages = [
      _buildHome(currentUser.uid),
      _buildAppointments(currentUser.uid),
      _buildPatients(currentUser.uid),
      _buildProfile(currentUser.uid),
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
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHome(String doctorId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<Doctor?>(
        future: _databaseService.getDoctor(doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doctor = snapshot.data;
          if (doctor == null) {
            return const Center(child: Text('Doctor data not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal,
                          Colors.teal.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dr. ${doctor.fullName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          doctor.specialization,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatusChip(
                              doctor.status == 'available'
                                  ? 'Available'
                                  : doctor.status == 'busy'
                                  ? 'Busy'
                                  : 'Offline',
                              doctor.status == 'available'
                                  ? Colors.green
                                  : doctor.status == 'busy'
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: () {
                                _updateStatus(doctor);
                              },
                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Change Status',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Today's Statistics
                Text(
                  "Today's Overview",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Appointment>>(
                  stream: _databaseService.getTodayAppointments(doctorId),
                  builder: (context, snapshot) {
                    final appointments = snapshot.data ?? [];
                    final completed = appointments
                        .where((a) => a.status == 'completed')
                        .length;
                    final pending = appointments
                        .where((a) => a.status == 'scheduled')
                        .length;
                    final cancelled = appointments
                        .where((a) => a.status == 'cancelled')
                        .length;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            appointments.length.toString(),
                            Icons.calendar_today,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            completed.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            pending.toString(),
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Today's Appointments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Appointments",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedIndex = 1);
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Appointment>>(
                  stream: _databaseService.getTodayAppointments(doctorId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No appointments today',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final todayAppointments = snapshot.data!
                        .where((a) => a.status != 'cancelled')
                        .toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todayAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = todayAppointments[index];
                        return FutureBuilder<Patient?>(
                          future: _databaseService.getPatient(
                            appointment.patientId,
                          ),
                          builder: (context, patientSnapshot) {
                            final patient = patientSnapshot.data;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(
                                    appointment.status,
                                  ).withOpacity(0.1),
                                  child: Text(
                                    patient?.firstName.substring(0, 1) ?? '?',
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        appointment.status,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  patient?.fullName ?? 'Loading...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time: ${appointment.timeSlot}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Reason: ${appointment.reason}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    if (appointment.status == 'scheduled')
                                      const PopupMenuItem(
                                        value: 'start',
                                        child: Row(
                                          children: [
                                            Icon(Icons.play_arrow,
                                                color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Start Consultation'),
                                          ],
                                        ),
                                      ),
                                    if (appointment.status == 'scheduled')
                                      const PopupMenuItem(
                                        value: 'cancel',
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel,
                                                color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Cancel'),
                                          ],
                                        ),
                                      ),
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
                                  ],
                                  onSelected: (value) {
                                    if (value == 'start' && patient != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PrescriptionScreen(
                                                appointment: appointment,
                                                patient: patient,
                                              ),
                                        ),
                                      );
                                    } else if (value == 'cancel') {
                                      _cancelAppointment(appointment);
                                    } else if (value == 'view') {
                                      _viewAppointmentDetails(
                                        appointment,
                                        patient,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Weekly Stats Chart
                Text(
                  'Weekly Appointments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: _buildWeeklyChart(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    // Sample data - in production, fetch from database
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
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
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (index + 1) * 1.5,
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
    );
  }

  Widget _buildAppointments(String doctorId) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Today'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentList(doctorId, 'upcoming'),
            _buildAppointmentList(doctorId, 'today'),
            _buildAppointmentList(doctorId, 'past'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(String doctorId, String type) {
    return StreamBuilder<List<Appointment>>(
      stream: _databaseService.getDoctorAppointments(doctorId),
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
                  Icons.event_available,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No appointments found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        List<Appointment> filteredAppointments = [];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

        if (type == 'upcoming') {
          filteredAppointments = snapshot.data!
              .where((a) =>
          a.appointmentDate.isAfter(tomorrow) &&
              a.status != 'cancelled')
              .toList();
        } else if (type == 'today') {
          filteredAppointments = snapshot.data!
              .where((a) =>
          a.appointmentDate.isAfter(today) &&
              a.appointmentDate.isBefore(tomorrow) &&
              a.status != 'cancelled')
              .toList();
        } else {
          filteredAppointments = snapshot.data!
              .where((a) =>
          a.appointmentDate.isBefore(today) ||
              a.status == 'completed')
              .toList();
        }

        if (filteredAppointments.isEmpty) {
          return Center(
            child: Text(
              'No $type appointments',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final appointment = filteredAppointments[index];
            return FutureBuilder<Patient?>(
              future: _databaseService.getPatient(appointment.patientId),
              builder: (context, patientSnapshot) {
                final patient = patientSnapshot.data;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      _getStatusColor(appointment.status).withOpacity(0.1),
                      child: Text(
                        patient?.firstName.substring(0, 1) ?? '?',
                        style: TextStyle(
                          color: _getStatusColor(appointment.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      patient?.fullName ?? 'Loading...',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, y')
                                  .format(appointment.appointmentDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              appointment.timeSlot,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reason: ${appointment.reason}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: type != 'past' && patient != null
                        ? IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrescriptionScreen(
                              appointment: appointment,
                              patient: patient,
                            ),
                          ),
                        );
                      },
                    )
                        : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointment.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(appointment.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPatients(String doctorId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _databaseService.getDoctorAppointments(doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No patients found'),
            );
          }

          // Get unique patient IDs
          final patientIds = snapshot.data!
              .map((appointment) => appointment.patientId)
              .toSet()
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patientIds.length,
            itemBuilder: (context, index) {
              return FutureBuilder<Patient?>(
                future: _databaseService.getPatient(patientIds[index]),
                builder: (context, patientSnapshot) {
                  if (!patientSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final patient = patientSnapshot.data!;
                  final patientAppointments = snapshot.data!
                      .where((a) => a.patientId == patient.id)
                      .toList();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          patient.firstName.substring(0, 1),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
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
                          Text('Age: ${patient.age} | ${patient.gender}'),
                          Text(
                            'Blood Group: ${patient.bloodGroup}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Total Visits: ${patientAppointments.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPatientInfo(
                                'Phone',
                                patient.phone,
                                Icons.phone,
                              ),
                              _buildPatientInfo(
                                'Email',
                                patient.email,
                                Icons.email,
                              ),
                              _buildPatientInfo(
                                'Address',
                                patient.address,
                                Icons.location_on,
                              ),
                              if (patient.allergies.isNotEmpty)
                                _buildPatientInfo(
                                  'Allergies',
                                  patient.allergies.join(', '),
                                  Icons.warning,
                                ),
                              if (patient.chronicConditions.isNotEmpty)
                                _buildPatientInfo(
                                  'Chronic Conditions',
                                  patient.chronicConditions.join(', '),
                                  Icons.medical_services,
                                ),
                              const SizedBox(height: 16),
                              const Text(
                                'Recent Appointments:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...patientAppointments.take(3).map((apt) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MMM d, y')
                                            .format(apt.appointmentDate),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(apt.status)
                                              .withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          apt.status.toUpperCase(),
                                          style: TextStyle(
                                            color: _getStatusColor(apt.status),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPatientInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(String doctorId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit profile
            },
          ),
        ],
      ),
      body: FutureBuilder<Doctor?>(
        future: _databaseService.getDoctor(doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doctor = snapshot.data;
          if (doctor == null) {
            return const Center(child: Text('Doctor data not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor:
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    doctor.firstName.substring(0, 1),
                    style: TextStyle(
                      fontSize: 36,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dr. ${doctor.fullName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  doctor.specialization,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Professional Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfileRow('License Number', doctor.licenseNumber),
                        _buildProfileRow('Qualification', doctor.qualification),
                        _buildProfileRow(
                          'Experience',
                          '${doctor.experienceYears} years',
                        ),
                        _buildProfileRow(
                          'Consultation Fee',
                          '\$${doctor.consultationFee}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfileRow('Email', doctor.email),
                        _buildProfileRow('Phone', doctor.phone),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfileRow(
                          'Working Days',
                          doctor.availableDays.join(', '),
                        ),
                        _buildProfileRow(
                          'Working Hours',
                          '${doctor.startTime} - ${doctor.endTime}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(Doctor doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Available'),
              onTap: () {
                // Update status to available
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending, color: Colors.orange),
              title: const Text('Busy'),
              onTap: () {
                // Update status to busy
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Offline'),
              onTap: () {
                // Update status to offline
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cancelAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _databaseService.updateAppointmentStatus(
                appointment.id,
                'cancelled',
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment cancelled'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _viewAppointmentDetails(Appointment appointment, Patient? patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Patient', patient?.fullName ?? 'N/A'),
              _buildDetailRow(
                'Date',
                DateFormat('EEEE, MMMM d, y').format(
                  appointment.appointmentDate,
                ),
              ),
              _buildDetailRow('Time', appointment.timeSlot),
              _buildDetailRow('Status', appointment.status),
              _buildDetailRow('Reason', appointment.reason),
              if (appointment.notes != null)
                _buildDetailRow('Notes', appointment.notes!),
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
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'confirmed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}