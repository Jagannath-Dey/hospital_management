import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final String licenseNumber;
  final List<String> availableDays;
  final String startTime;
  final String endTime;
  final double consultationFee;
  final String? profileImageUrl;
  final String status; // available, busy, offline

  Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.licenseNumber,
    required this.availableDays,
    required this.startTime,
    required this.endTime,
    required this.consultationFee,
    this.profileImageUrl,
    this.status = 'available',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'qualification': qualification,
      'experienceYears': experienceYears,
      'licenseNumber': licenseNumber,
      'availableDays': availableDays,
      'startTime': startTime,
      'endTime': endTime,
      'consultationFee': consultationFee,
      'profileImageUrl': profileImageUrl,
      'status': status,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      specialization: map['specialization'] ?? '',
      qualification: map['qualification'] ?? '',
      experienceYears: map['experienceYears'] ?? 0,
      licenseNumber: map['licenseNumber'] ?? '',
      availableDays: List<String>.from(map['availableDays'] ?? []),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      profileImageUrl: map['profileImageUrl'],
      status: map['status'] ?? 'available',
    );
  }

  String get fullName => '$firstName $lastName';
}