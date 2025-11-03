import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String diagnosis;
  final List<Medicine> medicines;
  final String? additionalNotes;
  final DateTime prescribedDate;
  final String? followUpDate;

  Prescription({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.diagnosis,
    required this.medicines,
    this.additionalNotes,
    required this.prescribedDate,
    this.followUpDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'diagnosis': diagnosis,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'additionalNotes': additionalNotes,
      'prescribedDate': Timestamp.fromDate(prescribedDate),
      'followUpDate': followUpDate,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      medicines: (map['medicines'] as List)
          .map((m) => Medicine.fromMap(m))
          .toList(),
      additionalNotes: map['additionalNotes'],
      prescribedDate: (map['prescribedDate'] as Timestamp).toDate(),
      followUpDate: map['followUpDate'],
    );
  }
}

class Medicine {
  final String name;
  final String dosage;
  final String frequency;
  final int duration; // in days
  final String? instructions;

  Medicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? 0,
      instructions: map['instructions'],
    );
  }
}