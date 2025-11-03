import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final String gender;
  final String bloodGroup;
  final String address;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String emergencyContact;
  final DateTime registrationDate;
  final String? profileImageUrl;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodGroup,
    required this.address,
    this.allergies = const [],
    this.chronicConditions = const [],
    required this.emergencyContact,
    required this.registrationDate,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'emergencyContact': emergencyContact,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'profileImageUrl': profileImageUrl,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    // Helper function to parse date from either String or Timestamp
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) {
        return DateTime.now();
      }
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      // If it's already a DateTime (shouldn't happen but just in case)
      if (dateValue is DateTime) {
        return dateValue;
      }
      // Fallback
      return DateTime.now();
    }

    // Parse name - handle both 'name' field and separate firstName/lastName
    String firstName = map['firstName'] ?? '';
    String lastName = map['lastName'] ?? '';

    // If firstName/lastName are empty but 'name' exists, split it
    if (firstName.isEmpty && lastName.isEmpty && map['name'] != null) {
      final nameParts = (map['name'] as String).split(' ');
      firstName = nameParts.first;
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    return Patient(
      id: map['id'] ?? map['uid'] ?? '',
      firstName: firstName,
      lastName: lastName,
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      dateOfBirth: parseDate(map['dateOfBirth']),
      gender: map['gender'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      address: map['address'] ?? '',
      allergies: map['allergies'] != null
          ? List<String>.from(map['allergies'])
          : [],
      chronicConditions: map['chronicConditions'] != null
          ? List<String>.from(map['chronicConditions'])
          : [],
      emergencyContact: map['emergencyContact'] ?? '',
      registrationDate: parseDate(map['registrationDate'] ?? map['registeredAt'] ?? map['createdAt']),
      profileImageUrl: map['profileImageUrl'],
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // Create a copy with updated fields
  Patient copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? emergencyContact,
    DateTime? registrationDate,
    String? profileImageUrl,
  }) {
    return Patient(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      registrationDate: registrationDate ?? this.registrationDate,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}