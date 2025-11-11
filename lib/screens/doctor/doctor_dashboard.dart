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

import '../../utils/constants.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Debug on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        _debugDoctorData(currentUser.uid);
      }
    });
  }

  Future<void> _debugDoctorData(String doctorId) async {
    // print('=== DEBUG: Doctor Data ===');
    // print('Doctor ID: $doctorId');

    // The debug logic is handled in DatabaseService now
    final doctor = await _databaseService.getDoctor(doctorId);
    if (doctor != null) {
      // print('Doctor loaded successfully: ${doctor.fullName}');
    } else {
      // print('Failed to load doctor data');
    }
    // print('=== END DEBUG ===');
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final List<Widget> pages = [
      _buildHome(currentUser.uid),
      _buildAppointments(currentUser.uid),
      _buildPatients(currentUser.uid),
      _buildProfile(currentUser.uid),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
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

  //-------------------------- Dashboard ----------------------------------
  Widget _buildHome(String doctorId) {
    print('Building home for doctor: $doctorId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: Colors.green,
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
          print('Doctor FutureBuilder state: ${snapshot.connectionState}');
          print('Has data: ${snapshot.hasData}');
          print('Has error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final doctor = snapshot.data;
          if (doctor == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Doctor data not found'),
                  const SizedBox(height: 8),
                  Text('Doctor ID: $doctorId',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          print('Doctor loaded: ${doctor.fullName}');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(doctor),
                const SizedBox(height: 24),
                Text(
                  "Today's Overview",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildTodayStats(doctorId),
                const SizedBox(height: 24),
                _buildTodayAppointmentsSection(doctorId),
                const SizedBox(height: 24),
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

  Widget _buildWelcomeCard(Doctor doctor) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.teal,
              Colors.teal.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
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
                color: Colors.white.withValues(alpha: 0.9),
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
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
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
    );
  }

  Widget _buildTodayStats(String doctorId) {
    return StreamBuilder<List<Appointment>>(
      stream: _databaseService.getTodayAppointments(doctorId),
      builder: (context, snapshot) {
        print('Today appointments stream state: ${snapshot.connectionState}');
        print('Today appointments count: ${snapshot.data?.length ?? 0}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data ?? [];
        final completed =
            appointments.where((a) => a.status == 'completed').length;
        final pending =
            appointments.where((a) => a.status == 'scheduled').length;

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
            const SizedBox(width: 10),
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
    );
  }

  Widget _buildTodayAppointmentsSection(String doctorId) {
    return Column(
      children: [
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

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

            if (todayAppointments.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No active appointments today',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayAppointments.length,
              itemBuilder: (context, index) {
                final appointment = todayAppointments[index];
                return _buildAppointmentCard(appointment);
              },
            );
          },
        ),
      ],
    );
  }
  void _viewAppointmentDetails(Appointment appointment, Patient? patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Appointment Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${appointment.id.substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: Colors.grey[200], height: 1),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _getStatusColor(appointment.status),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(appointment.status),
                                  color: _getStatusColor(appointment.status),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getStatusText(appointment.status),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(appointment.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Patient Information
                        _buildSectionHeader('Patient Information', Icons.person),
                        const SizedBox(height: 12),
                        _buildDetailCard([
                          _buildDetailRow(
                            'Name',
                            patient?.fullName ?? 'Loading...',
                            Icons.badge,
                          ),
                          _buildDetailRow(
                            'Age',
                            patient != null ? '${patient.age} years' : '-',
                            Icons.cake,
                          ),
                          _buildDetailRow(
                            'Gender',
                            patient?.gender ?? '-',
                            Icons.person_outline,
                          ),
                          _buildDetailRow(
                            'Blood Group',
                            patient?.bloodGroup ?? '-',
                            Icons.bloodtype,
                          ),
                          _buildDetailRow(
                            'Phone',
                            patient?.phone ?? '-',
                            Icons.phone,
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Appointment Information
                        _buildSectionHeader('Appointment Information', Icons.calendar_today),
                        const SizedBox(height: 12),
                        _buildDetailCard([
                          _buildDetailRow(
                            'Date',
                            DateFormat('EEEE, MMMM d, yyyy').format(appointment.appointmentDate),
                            Icons.event,
                          ),
                          _buildDetailRow(
                            'Time',
                            appointment.timeSlot,
                            Icons.access_time,
                          ),
                          _buildDetailRow(
                            'Status',
                            _getStatusText(appointment.status),
                            Icons.info_outline,
                            valueColor: _getStatusColor(appointment.status),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Medical Information
                        _buildSectionHeader('Medical Information', Icons.medical_information),
                        const SizedBox(height: 12),
                        _buildInfoBox(
                          'Reason for Visit',
                          appointment.reason,
                          Icons.medical_services_outlined,
                          Colors.blue,
                        ),

                        if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoBox(
                            'Additional Notes',
                            appointment.notes!,
                            Icons.note_outlined,
                            Colors.orange,
                          ),
                        ],

                        if (patient != null) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader('Medical History', Icons.history),
                          const SizedBox(height: 12),
                          if (patient.allergies.isNotEmpty)
                            _buildChipSection(
                              'Allergies',
                              patient.allergies,
                              Colors.red,
                            ),
                          if (patient.chronicConditions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildChipSection(
                              'Chronic Conditions',
                              patient.chronicConditions,
                              Colors.orange,
                            ),
                          ],
                        ],

                        const SizedBox(height: 32),

                        // Actions
                        if (appointment.status == 'scheduled') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: patient != null
                                  ? () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrescriptionScreen(
                                      appointment: appointment,
                                      patient: patient,
                                    ),
                                  ),
                                );
                              }
                                  : null,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Consultation'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showRescheduleDialog(appointment);
                                  },
                                  icon: const Icon(Icons.edit_calendar),
                                  label: const Text('Reschedule'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _cancelAppointment(appointment);
                                  },
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Cancel'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildAppointmentCard(Appointment appointment) {
    return FutureBuilder<Patient?>(
      future: _databaseService.getPatient(appointment.patientId),
      builder: (context, patientSnapshot) {
        final patient = patientSnapshot.data;
        final statusColor = _getStatusColor(appointment.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _viewAppointmentDetails(appointment, patient),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withValues(alpha: 0.8),
                              statusColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            patient?.firstName.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Patient Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient?.fullName ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.timeSlot,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Status Badge & Menu
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusText(appointment.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          PopupMenuButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => [
                              if (appointment.status == 'scheduled')
                                PopupMenuItem(
                                  value: 'start',
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Start Consultation'),
                                    ],
                                  ),
                                ),
                              if (appointment.status == 'scheduled')
                                const PopupMenuItem(
                                  value: 'cancel',
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel_outlined, color: Colors.red),
                                      SizedBox(width: 12),
                                      Text('Cancel'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility_outlined, color: AppColors.primaryBlue),
                                    SizedBox(width: 12),
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
                                    builder: (context) => PrescriptionScreen(
                                      appointment: appointment,
                                      patient: patient,
                                    ),
                                  ),
                                );
                              } else if (value == 'cancel') {
                                _cancelAppointment(appointment);
                              } else if (value == 'view') {
                                _viewAppointmentDetails(appointment, patient);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Divider
                  Divider(color: Colors.grey[300], height: 1),

                  const SizedBox(height: 12),

                  // Reason
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason for Visit',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appointment.reason,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Quick Actions (if scheduled)
                  if (appointment.status == 'scheduled') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _viewAppointmentDetails(appointment, patient),
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: const Text('Details'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: patient != null
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrescriptionScreen(
                                    appointment: appointment,
                                    patient: patient,
                                  ),
                                ),
                              );
                            }
                                : null,
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Helper method to get status text
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'confirmed':
        return 'Confirmed';
      default:
        return status.toUpperCase();
    }
  }

// Helper Widgets for Bottom Sheet

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, color: Colors.grey[200]),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value,
      IconData icon, {
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textDark,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

// Helper method to get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'confirmed':
        return Icons.verified;
      default:
        return Icons.info;
    }
  }

// Reschedule dialog
  void _showRescheduleDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: const Text(
          'Contact the patient to reschedule this appointment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
                if (value.toInt() >= 0 && value.toInt() < days.length) {
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
              reservedSize: 28,
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

  //-------------------------- Appointments ------------------------------
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
          a.appointmentDate.isAfter(today.subtract(const Duration(seconds: 1))) &&
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
                      _getStatusColor(appointment.status).withValues(alpha: 0.1),
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

                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4,),
                            Text(
                              appointment.timeSlot,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),

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
                            .withValues(alpha: 0.1),
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

  //--------------------------- Patients --------------------------------
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
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                                              .withValues(alpha: 0.1),
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

  //----------------------------- Profile ----------------------------------
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
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                          '\৳${doctor.consultationFee.toStringAsFixed(2)}',
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
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
        color: Colors.white.withValues(alpha: 0.2),
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
              onTap: () async {
                await _databaseService.updateDoctorStatus(doctor.id, 'available');
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated to Available')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending, color: Colors.orange),
              title: const Text('Busy'),
              onTap: () async {
                await _databaseService.updateDoctorStatus(doctor.id, 'busy');
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated to Busy')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Offline'),
              onTap: () async {
                await _databaseService.updateDoctorStatus(doctor.id, 'offline');
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated to Offline')),
                  );
                }
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
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment cancelled'),
                  ),
                );
              }
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