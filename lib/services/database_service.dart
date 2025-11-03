import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_management_app/models/patient.dart';
import 'package:hospital_management_app/models/doctor.dart';
import 'package:hospital_management_app/models/appointment.dart';
import 'package:hospital_management_app/models/prescription.dart';
import 'package:hospital_management_app/models/billing.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to ensure dates are stored as Timestamps
  Map<String, dynamic> _convertDatesToTimestamps(Map<String, dynamic> data) {
    final Map<String, dynamic> converted = Map<String, dynamic>.from(data);

    // List of possible date field names
    final dateFields = [
      'dateOfBirth',
      'registrationDate',
      'registeredAt',
      'createdAt',
      'appointmentDate',
      'prescribedDate',
      'billDate',
      'paymentDate'
    ];

    for (String field in dateFields) {
      if (converted.containsKey(field) && converted[field] != null) {
        final value = converted[field];
        if (value is String) {
          // Convert ISO8601 string to Timestamp
          converted[field] = Timestamp.fromDate(DateTime.parse(value));
        } else if (value is DateTime) {
          // Convert DateTime to Timestamp
          converted[field] = Timestamp.fromDate(value);
        }
        // If it's already a Timestamp, leave it as is
      }
    }

    return converted;
  }

  // Patients
  Future<void> createPatient(Patient patient) async {
    final data = _convertDatesToTimestamps(patient.toMap());
    await _firestore
        .collection('patients')
        .doc(patient.id)
        .set(data);
  }

  Future<Patient?> getPatient(String patientId) async {
    try {
      // Validate patientId
      if (patientId.isEmpty) {
        print('Error: patientId is empty');
        return null;
      }

      // First try to get from patients collection
      DocumentSnapshot doc = await _firestore
          .collection('patients')
          .doc(patientId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Patient.fromMap(doc.data() as Map<String, dynamic>);
      }

      // If not found in patients, check users collection (for newly registered users)
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(patientId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['userType'] == 'patient') {
          return Patient.fromMap(userData);
        }
      }

      return null;
    } catch (e) {
      print('Error getting patient: $e');
      return null;
    }
  }

  Stream<List<Patient>> getAllPatients() {
    return _firestore
        .collection('patients')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          return Patient.fromMap(doc.data());
        } catch (e) {
          print('Error parsing patient ${doc.id}: $e');
          return null;
        }
      })
          .where((patient) => patient != null)
          .cast<Patient>()
          .toList();
    });
  }

  Future<void> updatePatient(Patient patient) async {
    final data = _convertDatesToTimestamps(patient.toMap());

    // Update in both collections
    await _firestore
        .collection('patients')
        .doc(patient.id)
        .update(data);

    // Also update in users collection if exists
    final userDoc = await _firestore
        .collection('users')
        .doc(patient.id)
        .get();

    if (userDoc.exists) {
      await _firestore
          .collection('users')
          .doc(patient.id)
          .update(data);
    }
  }

  // Migrate user data from registration to proper patient document
  Future<void> migrateUserToPatient(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;

        if (userData['userType'] == 'patient') {
          // Create patient from user data
          final patient = Patient.fromMap(userData);

          // Save to patients collection with proper format
          await createPatient(patient);
        }
      }
    } catch (e) {
      print('Error migrating user to patient: $e');
    }
  }

  // Doctors
  Future<void> createDoctor(Doctor doctor) async {
    final data = _convertDatesToTimestamps(doctor.toMap());
    await _firestore
        .collection('doctors')
        .doc(doctor.id)
        .set(data);
  }

  // FIXED: Single getDoctor method that checks both collections
  Future<Doctor?> getDoctor(String doctorId) async {
    try {
      // Validate doctorId
      if (doctorId == null || doctorId.isEmpty) {
        print('Error: doctorId is empty or null');
        return null;
      }

      // First try to get from doctors collection
      DocumentSnapshot doc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Doctor.fromMap(doc.data() as Map<String, dynamic>);
      }

      // If not found in doctors, check users collection (for newly registered doctors)
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(doctorId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['userType'] == 'doctor') {
          // Create a Doctor object from user data
          final doctor = Doctor.fromMap(userData);

          // Optionally migrate to doctors collection
          await createDoctor(doctor);

          return doctor;
        }
      }

      print('Doctor not found for ID: $doctorId');
      return null;
    } catch (e) {
      print('Error getting doctor with ID $doctorId: $e');
      return null;
    }
  }

  Stream<List<Doctor>> getAllDoctors() {
    // Check both doctors and users collections
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'doctor')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Ensure ID is included
          return Doctor.fromMap(data);
        } catch (e) {
          print('Error parsing doctor ${doc.id}: $e');
          return null;
        }
      })
          .where((doctor) => doctor != null)
          .cast<Doctor>()
          .toList();
    });
  }

  Stream<List<Doctor>> getDoctorsBySpecialization(String specialization) {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'doctor')
        .where('specialization', isEqualTo: specialization)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Ensure ID is included
          return Doctor.fromMap(data);
        } catch (e) {
          print('Error parsing doctor ${doc.id}: $e');
          return null;
        }
      })
          .where((doctor) => doctor != null)
          .cast<Doctor>()
          .toList();
    });
  }

  // Appointments
  Future<void> createAppointment(Appointment appointment) async {
    // Validate required fields
    if (appointment.doctorId == null || appointment.doctorId.isEmpty) {
      throw Exception('Doctor ID is required for appointment');
    }
    if (appointment.patientId == null || appointment.patientId.isEmpty) {
      throw Exception('Patient ID is required for appointment');
    }

    final data = _convertDatesToTimestamps(appointment.toMap());
    await _firestore
        .collection('appointments')
        .doc(appointment.id)
        .set(data);
  }

  Stream<List<Appointment>> getPatientAppointments(String patientId) {
    if (patientId == null || patientId.isEmpty) {
      print('Warning: patientId is empty in getPatientAppointments');
      return Stream.value([]);
    }

    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Ensure ID is included
          return Appointment.fromMap(data);
        } catch (e) {
          print('Error parsing appointment ${doc.id}: $e');
          return null;
        }
      })
          .where((appointment) => appointment != null)
          .cast<Appointment>()
          .toList();
    });
  }

  Stream<List<Appointment>> getDoctorAppointments(String doctorId) {
    if (doctorId == null || doctorId.isEmpty) {
      print('Warning: doctorId is empty in getDoctorAppointments');
      return Stream.value([]);
    }

    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Ensure ID is included
          return Appointment.fromMap(data);
        } catch (e) {
          print('Error parsing appointment ${doc.id}: $e');
          return null;
        }
      })
          .where((appointment) => appointment != null)
          .cast<Appointment>()
          .toList();
    });
  }

  Stream<List<Appointment>> getTodayAppointments(String doctorId) {
    if (doctorId == null || doctorId.isEmpty) {
      print('Warning: doctorId is empty in getTodayAppointments');
      return Stream.value([]);
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('appointmentDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('appointmentDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Ensure ID is included
          return Appointment.fromMap(data);
        } catch (e) {
          print('Error parsing appointment ${doc.id}: $e');
          return null;
        }
      })
          .where((appointment) => appointment != null)
          .cast<Appointment>()
          .toList();
    });
  }

  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get available time slots for a doctor on a specific date
  Future<List<String>> getAvailableTimeSlots(
      String doctorId, DateTime date) async {
    // Validate doctorId
    if (doctorId == null || doctorId.isEmpty) {
      print('Error: doctorId is empty in getAvailableTimeSlots');
      return [];
    }

    // Get doctor's working hours
    Doctor? doctor = await getDoctor(doctorId);
    if (doctor == null) {
      print('Doctor not found for available time slots');
      return [];
    }

    // Generate time slots based on doctor's schedule
    List<String> allSlots = _generateTimeSlots(
      doctor.startTime ?? '09:00',
      doctor.endTime ?? '17:00',
    );

    // Get booked appointments for the date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    QuerySnapshot snapshot = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('appointmentDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: ['scheduled', 'confirmed'])
        .get();

    List<String> bookedSlots = snapshot.docs.map((doc) {
      return doc.get('timeSlot') as String;
    }).toList();

    // Return available slots
    return allSlots.where((slot) => !bookedSlots.contains(slot)).toList();
  }

  List<String> _generateTimeSlots(String startTime, String endTime) {
    List<String> slots = [];
    int startHour = int.parse(startTime.split(':')[0]);
    int endHour = int.parse(endTime.split(':')[0]);

    for (int hour = startHour; hour < endHour; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      slots.add('${hour.toString().padLeft(2, '0')}:30');
    }

    return slots;
  }

  // Prescriptions
  Future<void> createPrescription(Prescription prescription) async {
    final data = _convertDatesToTimestamps(prescription.toMap());
    await _firestore
        .collection('prescriptions')
        .doc(prescription.id)
        .set(data);

    // Update appointment with prescription ID
    await _firestore
        .collection('appointments')
        .doc(prescription.appointmentId)
        .update({
      'prescriptionId': prescription.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Prescription?> getPrescription(String prescriptionId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('prescriptions')
          .doc(prescriptionId)
          .get();
      if (doc.exists && doc.data() != null) {
        return Prescription.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting prescription: $e');
      return null;
    }
  }

  Stream<List<Prescription>> getPatientPrescriptions(String patientId) {
    return _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .orderBy('prescribedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          return Prescription.fromMap(doc.data());
        } catch (e) {
          print('Error parsing prescription ${doc.id}: $e');
          return null;
        }
      })
          .where((prescription) => prescription != null)
          .cast<Prescription>()
          .toList();
    });
  }

  // Billing
  Future<void> createBill(Billing bill) async {
    final data = _convertDatesToTimestamps(bill.toMap());
    await _firestore.collection('bills').doc(bill.id).set(data);
  }

  Future<Billing?> getBill(String billId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('bills')
          .doc(billId)
          .get();
      if (doc.exists && doc.data() != null) {
        return Billing.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting bill: $e');
      return null;
    }
  }

  Stream<List<Billing>> getPatientBills(String patientId) {
    return _firestore
        .collection('bills')
        .where('patientId', isEqualTo: patientId)
        .orderBy('billDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          return Billing.fromMap(doc.data());
        } catch (e) {
          print('Error parsing bill ${doc.id}: $e');
          return null;
        }
      })
          .where((bill) => bill != null)
          .cast<Billing>()
          .toList();
    });
  }

  Future<void> updateBillPayment(
      String billId, String paymentStatus, String paymentMethod) async {
    await _firestore.collection('bills').doc(billId).update({
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Statistics for dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      // Get counts
      QuerySnapshot patientsSnapshot = await _firestore
          .collection('patients')
          .get();
      QuerySnapshot doctorsSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'doctor')
          .get();

      QuerySnapshot todayAppointments = await _firestore
          .collection('appointments')
          .where('appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      QuerySnapshot pendingBills = await _firestore
          .collection('bills')
          .where('paymentStatus', isEqualTo: 'pending')
          .get();

      return {
        'totalPatients': patientsSnapshot.docs.length,
        'totalDoctors': doctorsSnapshot.docs.length,
        'todayAppointments': todayAppointments.docs.length,
        'pendingBills': pendingBills.docs.length,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'totalPatients': 0,
        'totalDoctors': 0,
        'todayAppointments': 0,
        'pendingBills': 0,
      };
    }
  }
}