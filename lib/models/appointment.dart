import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime appointmentDate;
  final String timeSlot;
  final String status; // scheduled, completed, cancelled
  final String reason;
  final String? notes;
  final DateTime createdAt;
  final String? prescriptionId;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    required this.reason,
    this.notes,
    required this.createdAt,
    this.prescriptionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': timeSlot,
      'status': status,
      'reason': reason,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'prescriptionId': prescriptionId,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      timeSlot: map['timeSlot'] ?? '',
      status: map['status'] ?? '',
      reason: map['reason'] ?? '',
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      prescriptionId: map['prescriptionId'],
    );
  }
}