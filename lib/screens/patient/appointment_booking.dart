import 'package:flutter/material.dart';
import 'package:hospital_management_app/models/doctor.dart';
import 'package:hospital_management_app/models/appointment.dart';
import 'package:hospital_management_app/services/auth_service.dart';
import 'package:hospital_management_app/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AppointmentBooking extends StatefulWidget {
  const AppointmentBooking({super.key, });

  @override
  State<AppointmentBooking> createState() => _AppointmentBookingState();
}

class _AppointmentBookingState extends State<AppointmentBooking> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  String? _selectedSpecialization;
  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _selectedTimeSlot;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _specializations = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Orthopedic',
    'Pediatrician',
    'Psychiatrist',
    'Surgeon',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).primaryColor,
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  if (_currentStep < 3)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 2 ? 'Review' : 'Next'),
                    ),
                  const SizedBox(width: 8),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Select Specialization'),
              content: _buildSpecializationStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Choose Doctor'),
              content: _buildDoctorStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Select Date & Time'),
              content: _buildDateTimeStep(),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Appointment Details'),
              content: _buildDetailsStep(),
              isActive: _currentStep >= 3,
              state: _currentStep == 3 ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecializationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What type of doctor do you need?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        ...(_specializations.map((spec) {
          return Card(
            elevation: _selectedSpecialization == spec ? 2 : 0,
            color: _selectedSpecialization == spec
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null,
            child: RadioListTile<String>(
              title: Text(
                spec,
                style: TextStyle(
                  fontWeight: _selectedSpecialization == spec
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              value: spec,
              groupValue: _selectedSpecialization,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (value) {
                setState(() {
                  _selectedSpecialization = value;
                  _selectedDoctor = null;
                  _selectedTimeSlot = null;
                });
                debugPrint('✓ Specialization selected: $value');
              },
            ),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildDoctorStep() {
    if (_selectedSpecialization == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Please select a specialization first',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Doctor>>(
      stream: _databaseService.getDoctorsBySpecialization(
        _selectedSpecialization!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('❌ Error loading doctors: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          debugPrint('⚠ No doctors found for $_selectedSpecialization');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No doctors available for this specialization',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final doctors = snapshot.data!;
        debugPrint('✓ Loaded ${doctors.length} doctors');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Doctors:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...doctors.map((doctor) {
              final isSelected = _selectedDoctor?.id == doctor.id;

              // Debug doctor info
              debugPrint('Doctor: ${doctor.fullName}, ID: ${doctor.id}');

              return Card(
                elevation: isSelected ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDoctor = doctor;
                      _selectedTimeSlot = null;
                    });
                    debugPrint('✓ Doctor selected: ${doctor.fullName}, ID: ${doctor.id}');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. ${doctor.fullName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      doctor.qualification,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.work_outline,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${doctor.experienceYears} years experience',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: Colors.green[700],
                                  ),
                                  Text(
                                    'Fee: ${doctor.consultationFee}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildDateTimeStep() {
    if (_selectedDoctor == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Please select a doctor first',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 30)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDate, selectedDay)) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedTimeSlot = null;
                  });
                  debugPrint('✓ Date selected: ${DateFormat('yyyy-MM-dd').format(selectedDay)}');
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              enabledDayPredicate: (day) {
                // Don't allow past dates
                if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                  return false;
                }

                // If availableDays is empty or null, allow all future days
                if (_selectedDoctor!.availableDays.isEmpty) {
                  return true;
                }

                String dayName = DateFormat('EEEE').format(day);
                return _selectedDoctor!.availableDays.contains(dayName);
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                disabledDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selected: ${DateFormat('EEEE, MMMM d, y').format(_selectedDate)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Available Time Slots:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTimeSlots(),
      ],
    );
  }

  Widget _buildTimeSlots() {
    // Add comprehensive debug info
    debugPrint('════════════════════════════════════');
    debugPrint('DEBUGGING TIME SLOTS');
    debugPrint('Selected Doctor: ${_selectedDoctor?.fullName}');
    debugPrint('Doctor ID: ${_selectedDoctor?.id}');
    debugPrint('Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
    debugPrint('════════════════════════════════════');

    // Validate doctor is selected and has ID
    if (_selectedDoctor == null) {
      debugPrint('❌ No doctor selected');
      return _buildNoSlotsMessage('Please select a doctor first');
    }

    if (_selectedDoctor!.id.isEmpty) {
      debugPrint('❌ Doctor ID is empty for ${_selectedDoctor!.fullName}');
      return _buildNoSlotsMessage('Doctor information incomplete. Please try selecting a different doctor.');
    }

    return FutureBuilder<List<String>>(
      future: _getAvailableTimeSlots(),
      builder: (context, snapshot) {
        debugPrint('FutureBuilder State: ${snapshot.connectionState}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('❌ Error loading time slots: ${snapshot.error}');
          debugPrint('Stack trace: ${snapshot.stackTrace}');
          return _buildErrorMessage('Error loading time slots: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data == null) {
          debugPrint('⚠ No data returned from getAvailableTimeSlots');
          return _buildNoSlotsMessage('No time slots available for this date');
        }

        final timeSlots = snapshot.data!;
        debugPrint('✓ Received ${timeSlots.length} time slots: $timeSlots');

        if (timeSlots.isEmpty) {
          debugPrint('⚠ Empty time slots list');
          return _buildNoSlotsMessage('No time slots available for this date');
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((slot) {
            final isSelected = _selectedTimeSlot == slot;
            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedTimeSlot = selected ? slot : null;
                });
                debugPrint('✓ Time slot selected: $slot');
              },
            );
          }).toList(),
        );
      },
    );
  }

  // Helper method to get available time slots with better error handling
  Future<List<String>> _getAvailableTimeSlots() async {
    try {
      debugPrint('Fetching time slots for Doctor ID: ${_selectedDoctor!.id}, Date: $_selectedDate');

      final slots = await _databaseService.getAvailableTimeSlots(
        _selectedDoctor!.id,
        _selectedDate,
      );

      debugPrint('Time slots fetched successfully: $slots');
      return slots;
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in _getAvailableTimeSlots: $e');
      debugPrint('Stack trace: $stackTrace');

      // Return default time slots as fallback
      debugPrint('⚠ Using fallback time slots');
      return _getDefaultTimeSlots();
    }
  }

  // Fallback method to generate default time slots
  List<String> _getDefaultTimeSlots() {
    final now = DateTime.now();
    final isToday = isSameDay(_selectedDate, now);

    List<String> slots = [
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM',
      '04:00 PM',
      '04:30 PM',
      '05:00 PM',
    ];

    if (isToday) {
      // Filter out past time slots for today
      final currentHour = now.hour;
      final currentMinute = now.minute;

      slots = slots.where((slot) {
        final parts = slot.split(':');
        int hour = int.parse(parts[0]);
        final minuteParts = parts[1].split(' ');
        int minute = int.parse(minuteParts[0]);
        final period = minuteParts[1];

        // Convert to 24-hour format
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return hour > currentHour || (hour == currentHour && minute > currentMinute);
      }).toList();
    }

    debugPrint('✓ Generated ${slots.length} default time slots');
    return slots;
  }

  Widget _buildNoSlotsMessage(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {}); // Retry
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Summary:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            color: Colors.blue[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(
                    Icons.person,
                    'Doctor',
                    'Dr. ${_selectedDoctor?.fullName ?? ""}',
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    Icons.medical_services,
                    'Specialization',
                    _selectedSpecialization ?? "",
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    Icons.calendar_today,
                    'Date',
                    DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    Icons.access_time,
                    'Time',
                    _selectedTimeSlot ?? "",
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    Icons.attach_money,
                    'Consultation Fee',
                    '${_selectedDoctor?.consultationFee ?? 0}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Reason for visit *',
              hintText: 'Briefly describe your symptoms or reason',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.notes),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide a reason for your visit';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Additional Notes (Optional)',
              hintText: 'Any additional information for the doctor',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _bookAppointment,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Confirm Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0 && _selectedSpecialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a specialization'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentStep == 1 && _selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentStep == 2 && _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctor == null || _selectedDoctor!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to book an appointment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Booking appointment...'),
            ],
          ),
        ),
      );

      // Parse time slot
      final timeParts = _selectedTimeSlot!.split(':');
      int hour = int.parse(timeParts[0]);
      final minuteParts = timeParts[1].split(' ');
      int minute = int.parse(minuteParts[0]);
      final period = minuteParts[1];

      // Convert to 24-hour format
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      final appointment = Appointment(
        id: const Uuid().v4(),
        patientId: currentUser.uid,
        doctorId: _selectedDoctor!.id,
        appointmentDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          hour,
          minute,
        ),
        timeSlot: _selectedTimeSlot!,
        status: 'scheduled',
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      debugPrint('✓ Creating appointment: ${appointment.toMap()}');
      await _databaseService.createAppointment(appointment);
      debugPrint('✓ Appointment created successfully');

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Appointment Booked!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your appointment with Dr. ${_selectedDoctor!.fullName} has been confirmed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, y').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTimeSlot!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close success dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error booking appointment: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _bookAppointment,
          ),
        ),
      );
    }
  }
}