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

  // ========================= PATIENTS =========================
  Future<void> createPatient(Patient patient) async {
    final data = _convertDatesToTimestamps(patient.toMap());
    await _firestore.collection('patients').doc(patient.id).set(data);
  }

  Future<Patient?> getPatient(String patientId) async {
    try {
      // Validate patientId
      if (patientId.isEmpty) {
        print('Error: patientId is empty');
        return null;
      }

      // First try to get from patients collection
      DocumentSnapshot doc =
      await _firestore.collection('patients').doc(patientId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Patient.fromMap(data);
      }

      // If not found in patients, check users collection
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(patientId).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['userType'] == 'patient') {
          userData['id'] = userDoc.id;
          final patient = Patient.fromMap(userData);

          // Migrate to patients collection
          await createPatient(patient);

          return patient;
        }
      }

      return null;
    } catch (e) {
      print('Error getting patient: $e');
      return null;
    }
  }

  Stream<List<Patient>> getAllPatients() {
    return _firestore.collection('patients').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return Patient.fromMap(data);
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
    await _firestore.collection('patients').doc(patient.id).update(data);

    // Also update in users collection if exists
    final userDoc = await _firestore.collection('users').doc(patient.id).get();

    if (userDoc.exists) {
      await _firestore.collection('users').doc(patient.id).update(data);
    }
  }

  // ========================= DOCTORS =========================
  Future<void> createDoctor(Doctor doctor) async {
    try {
      final data = _convertDatesToTimestamps(doctor.toMap());
      await _firestore.collection('doctors').doc(doctor.id).set(data);
      print('Doctor created successfully: ${doctor.id}');
    } catch (e) {
      print('Error creating doctor: $e');
      rethrow;
    }
  }

  Future<Doctor?> getDoctor(String doctorId) async {
    try {
      if (doctorId.isEmpty) {
        print('Error: doctorId is empty');
        return null;
      }

      print('Fetching doctor with ID: $doctorId');

      // Try doctors collection first
      DocumentSnapshot doc =
      await _firestore.collection('doctors').doc(doctorId).get();

      if (doc.exists && doc.data() != null) {
        print('Doctor found in doctors collection');
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Debug: Print the raw data
        print('Raw doctor data: $data');

        try {
          return Doctor.fromMap(data);
        } catch (parseError) {
          print('Error parsing doctor from doctors collection: $parseError');
          print('Doctor data that failed to parse: $data');

          // Try to fix the data and retry
          final fixedData = _fixDoctorData(data);
          return Doctor.fromMap(fixedData);
        }
      }

      // Try users collection
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(doctorId).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print('User data found: ${userData['userType']}');

        if (userData['userType'] == 'doctor') {
          userData['id'] = userDoc.id;

          // Debug: Print the raw data
          print('Raw user data: $userData');

          try {
            final doctor = Doctor.fromMap(userData);

            // Migrate to doctors collection for future use
            await _migrateDoctorData(doctor);

            return doctor;
          } catch (parseError) {
            print('Error parsing doctor from users collection: $parseError');
            print('User data that failed to parse: $userData');

            // Try to fix the data and retry
            final fixedData = _fixDoctorData(userData);
            final doctor = Doctor.fromMap(fixedData);
            await _migrateDoctorData(doctor);
            return doctor;
          }
        }
      }

      print('Doctor not found in any collection for ID: $doctorId');
      return null;
    } catch (e) {
      print('Error getting doctor: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

// Helper method to fix doctor data with null values
  Map<String, dynamic> _fixDoctorData(Map<String, dynamic> data) {
    return {
      'id': data['id'] ?? data['uid'] ?? '',
      'uid': data['uid'] ?? data['id'] ?? '',
      'email': data['email'] ?? '',
      'firstName': data['firstName'] ?? '',
      'lastName': data['lastName'] ?? '',
      'phone': data['phone'] ?? '',
      'specialization': data['specialization'] ?? 'General Practice',
      'licenseNumber': data['licenseNumber'] ?? '',
      'qualification': data['qualification'] ?? '',
      'experienceYears': data['experienceYears'] ?? 0,
      'consultationFee': data['consultationFee'] ?? 0.0,
      'availableDays': data['availableDays'] ??
          ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      'startTime': data['startTime'] ?? '09:00',
      'endTime': data['endTime'] ?? '17:00',
      'status': data['status'] ?? 'available',
      'userType': 'doctor',
    };
  }

  // Alias method for getDoctorById
  Future<Doctor?> getDoctorById(String doctorId) async {
    return await getDoctor(doctorId);
  }

  Future<void> _migrateDoctorData(Doctor doctor) async {
    try {
      final doctorDoc =
      await _firestore.collection('doctors').doc(doctor.id).get();

      if (!doctorDoc.exists) {
        print('Migrating doctor ${doctor.id} to doctors collection');
        await createDoctor(doctor);
      }
    } catch (e) {
      print('Error migrating doctor data: $e');
    }
  }

  Stream<List<Doctor>> getAllDoctors() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'doctor')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
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
          data['id'] = doc.id;
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

  Future<void> updateDoctorStatus(String doctorId, String status) async {
    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update in users collection
      final userDoc = await _firestore.collection('users').doc(doctorId).get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(doctorId).update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('Doctor status updated to: $status');
    } catch (e) {
      print('Error updating doctor status: $e');
      rethrow;
    }
  }

  // ========================= APPOINTMENTS =========================
  Future<void> createAppointment(Appointment appointment) async {
    // Validate required fields
    if (appointment.doctorId.isEmpty) {
      throw Exception('Doctor ID is required for appointment');
    }
    if (appointment.patientId.isEmpty) {
      throw Exception('Patient ID is required for appointment');
    }

    final data = _convertDatesToTimestamps(appointment.toMap());
    await _firestore.collection('appointments').doc(appointment.id).set(data);
  }

  Stream<List<Appointment>> getPatientAppointments(String patientId) {
    if (patientId.isEmpty) {
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
          data['id'] = doc.id;
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
    if (doctorId.isEmpty) {
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
          data['id'] = doc.id;
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
    if (doctorId.isEmpty) {
      print('Warning: doctorId is empty in getTodayAppointments');
      return Stream.value([]);
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    print('Fetching appointments for doctor: $doctorId on $startOfDay');

    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      print('Found ${snapshot.docs.length} total appointments for doctor');

      return snapshot.docs
          .map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return Appointment.fromMap(data);
        } catch (e) {
          print('Error parsing appointment ${doc.id}: $e');
          return null;
        }
      })
          .where((appointment) => appointment != null)
          .cast<Appointment>()
          .where((appointment) {
        final aptDate = appointment.appointmentDate;
        return aptDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            aptDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
      })
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

  Future<List<String>> getAvailableTimeSlots(
      String doctorId, DateTime date) async {
    if (doctorId.isEmpty) {
      print('Error: doctorId is empty in getAvailableTimeSlots');
      return [];
    }

    Doctor? doctor = await getDoctor(doctorId);
    if (doctor == null) {
      print('Doctor not found for available time slots');
      return [];
    }

    List<String> allSlots = _generateTimeSlots(
      doctor.startTime,
      doctor.endTime,
    );

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    QuerySnapshot snapshot = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('appointmentDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: ['scheduled', 'confirmed']).get();

    List<String> bookedSlots = snapshot.docs.map((doc) {
      return doc.get('timeSlot') as String;
    }).toList();

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

  // ========================= PRESCRIPTIONS =========================
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
      'status': 'completed',
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
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Prescription.fromMap(data);
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
          final data = doc.data();
          data['id'] = doc.id;
          return Prescription.fromMap(data);
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

  // ========================= BILLING =========================
  Future<void> createBill(Billing bill) async {
    final data = _convertDatesToTimestamps(bill.toMap());
    await _firestore.collection('bills').doc(bill.id).set(data);
  }

  Future<Billing?> getBill(String billId) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('bills').doc(billId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Billing.fromMap(data);
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
          final data = doc.data();
          data['id'] = doc.id;
          return Billing.fromMap(data);
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

  // ========================= STATISTICS =========================
  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      QuerySnapshot patientsSnapshot =
      await _firestore.collection('patients').get();
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