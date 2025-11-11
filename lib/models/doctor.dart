class Doctor {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String specialization;
  final String licenseNumber;
  final String qualification;
  final int experienceYears;
  final double consultationFee;
  final List<String> availableDays;
  final String startTime;
  final String endTime;
  final String status;

  String get fullName => '$firstName $lastName';

  Doctor({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.specialization = 'General Practice',
    this.licenseNumber = '',
    this.qualification = '',
    this.experienceYears = 0,
    this.consultationFee = 0.0,
    this.availableDays = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ],
    this.startTime = '09:00',
    this.endTime = '17:00',
    this.status = 'available',
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    // Helper function to safely parse int
    int parseIntSafely(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper function to safely parse double
    double parseDoubleSafely(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper function to safely parse string
    String parseStringSafely(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Helper function to safely parse list
    List<String> parseListSafely(dynamic value, List<String> defaultValue) {
      if (value == null) return defaultValue;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return defaultValue;
    }

    return Doctor(
      id: parseStringSafely(map['id'] ?? map['uid'], ''),
      email: parseStringSafely(map['email'], ''),
      firstName: parseStringSafely(map['firstName'], ''),
      lastName: parseStringSafely(map['lastName'], ''),
      phone: parseStringSafely(map['phone'], ''),
      specialization: parseStringSafely(map['specialization'], 'General Practice'),
      licenseNumber: parseStringSafely(map['licenseNumber'], ''),
      qualification: parseStringSafely(map['qualification'], ''),
      experienceYears: parseIntSafely(map['experienceYears'], 0),
      consultationFee: parseDoubleSafely(map['consultationFee'], 0.0),
      availableDays: parseListSafely(
        map['availableDays'],
        ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      ),
      startTime: parseStringSafely(map['startTime'], '09:00'),
      endTime: parseStringSafely(map['endTime'], '17:00'),
      status: parseStringSafely(map['status'], 'available'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'specialization': specialization,
      'licenseNumber': licenseNumber,
      'qualification': qualification,
      'experienceYears': experienceYears,
      'consultationFee': consultationFee,
      'availableDays': availableDays,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'userType': 'doctor',
    };
  }

  Doctor copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? specialization,
    String? licenseNumber,
    String? qualification,
    int? experienceYears,
    double? consultationFee,
    List<String>? availableDays,
    String? startTime,
    String? endTime,
    String? status,
  }) {
    return Doctor(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      qualification: qualification ?? this.qualification,
      experienceYears: experienceYears ?? this.experienceYears,
      consultationFee: consultationFee ?? this.consultationFee,
      availableDays: availableDays ?? this.availableDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }
}