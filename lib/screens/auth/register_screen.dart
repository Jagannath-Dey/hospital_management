import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_app/services/auth_service.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  String _userType = 'patient'; // patient, doctor, admin

  // Common fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Patient specific fields
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'Male';
  String _bloodGroup = 'A+';
  List<String> _allergies = [];
  List<String> _chronicConditions = [];
  final _allergyController = TextEditingController();
  final _conditionController = TextEditingController();

  // Doctor specific fields
  final _specializationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _experienceController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  String _startTime = '09:00';
  String _endTime = '17:00';
  List<String> _availableDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  // Admin specific fields
  final _adminCodeController = TextEditingController();
  final _departmentController = TextEditingController();

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _specializations = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Orthopedic',
    'Pediatrician',
    'Psychiatrist',
    'Surgeon',
    'Dentist',
    'ENT Specialist',
    'Gynecologist',
    'Urologist',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _allergyController.dispose();
    _conditionController.dispose();
    _specializationController.dispose();
    _qualificationController.dispose();
    _licenseNumberController.dispose();
    _experienceController.dispose();
    _consultationFeeController.dispose();
    _adminCodeController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / (_userType == 'patient' ? 3 : _userType == 'doctor' ? 4 : 2),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: _buildPages(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages() {
    List<Widget> pages = [
      _buildUserTypeSelection(),
      _buildBasicInfoPage(),
    ];

    if (_userType == 'patient') {
      pages.add(_buildPatientInfoPage());
    } else if (_userType == 'doctor') {
      pages.addAll([
        _buildDoctorProfessionalPage(),
        _buildDoctorSchedulePage(),
      ]);
    }

    return pages;
  }

  Widget _buildUserTypeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Account Type',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the type of account you want to create',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          _buildUserTypeCard(
            'patient',
            'Patient',
            'Book appointments and manage your health records',
            Icons.person_outline,
            Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildUserTypeCard(
            'doctor',
            'Doctor',
            'Manage appointments and prescriptions',
            Icons.medical_services_outlined,
            Colors.teal,
          ),
          const SizedBox(height: 16),

          _buildUserTypeCard(
            'admin',
            'Administrator',
            'Manage hospital operations and billing',
            Icons.admin_panel_settings_outlined,
            Colors.purple,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard(
      String value,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      ) {
    return InkWell(
      onTap: () {
        setState(() => _userType = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _userType == value ? color : Colors.grey[300]!,
            width: 2,
          ),
          color: _userType == value ? color.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _userType,
              activeColor: color,
              onChanged: (val) {
                setState(() => _userType = val!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _currentPage == 1 ? _formKey : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your personal details',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                prefixText: '+1 ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length != 10) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
                helperText: 'At least 6 characters',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            if (_userType == 'admin') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _adminCodeController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Admin Access Code',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(),
                  helperText: 'Enter the admin access code provided by the hospital',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter admin access code';
                  }
                  // In production, validate against secure admin codes
                  if (value != 'ADMIN2024') {
                    return 'Invalid admin access code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your department';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 32),

            Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_userType == 'admin') {
                          _register();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    },
                    child: Text(_userType == 'admin' ? 'Register' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _currentPage == 2 ? _formKey : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Information',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide your medical details for better care',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Date of Birth
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _dateOfBirth = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? DateFormat('MMMM d, y').format(_dateOfBirth!)
                      : 'Select Date',
                  style: TextStyle(
                    color: _dateOfBirth != null ? null : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              items: ['Male', 'Female', 'Other'].map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _gender = value!);
              },
            ),
            const SizedBox(height: 16),

            // Blood Group
            DropdownButtonFormField<String>(
              value: _bloodGroup,
              decoration: const InputDecoration(
                labelText: 'Blood Group',
                prefixIcon: Icon(Icons.bloodtype),
                border: OutlineInputBorder(),
              ),
              items: _bloodGroups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _bloodGroup = value!);
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Emergency Contact
            TextFormField(
              controller: _emergencyContactController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Emergency Contact',
                prefixIcon: Icon(Icons.emergency),
                border: OutlineInputBorder(),
                helperText: 'Contact person in case of emergency',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter emergency contact';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Allergies
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _allergyController,
                    decoration: const InputDecoration(
                      labelText: 'Allergies (Optional)',
                      prefixIcon: Icon(Icons.warning),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_allergyController.text.isNotEmpty) {
                      setState(() {
                        _allergies.add(_allergyController.text.trim());
                        _allergyController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            if (_allergies.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allergies.map((allergy) {
                  return Chip(
                    label: Text(allergy),
                    onDeleted: () {
                      setState(() => _allergies.remove(allergy));
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Chronic Conditions
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _conditionController,
                    decoration: const InputDecoration(
                      labelText: 'Chronic Conditions (Optional)',
                      prefixIcon: Icon(Icons.medical_services),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_conditionController.text.isNotEmpty) {
                      setState(() {
                        _chronicConditions.add(_conditionController.text.trim());
                        _conditionController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            if (_chronicConditions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _chronicConditions.map((condition) {
                  return Chip(
                    label: Text(condition),
                    onDeleted: () {
                      setState(() => _chronicConditions.remove(condition));
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      if (_dateOfBirth == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select your date of birth'),
                          ),
                        );
                        return;
                      }
                      if (_formKey.currentState!.validate()) {
                        _register();
                      }
                    },
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Register'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorProfessionalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _currentPage == 2 ? _formKey : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Professional Information',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your professional details',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Specialization
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Specialization',
                prefixIcon: Icon(Icons.medical_services),
                border: OutlineInputBorder(),
              ),
              items: _specializations.map((spec) {
                return DropdownMenuItem(
                  value: spec,
                  child: Text(spec),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _specializationController.text = value!);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your specialization';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Other fields remain the same...
            TextFormField(
              controller: _qualificationController,
              decoration: const InputDecoration(
                labelText: 'Qualification',
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(),
                helperText: 'e.g., MBBS, MD, MS',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your qualification';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _licenseNumberController,
              decoration: const InputDecoration(
                labelText: 'Medical License Number',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your license number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Years of Experience',
                prefixIcon: Icon(Icons.work_history),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter years of experience';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _consultationFeeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Consultation Fee',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                helperText: 'Fee per consultation in USD',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter consultation fee';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSchedulePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Settings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your availability and working hours',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          const Text(
            'Available Days',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
              .map((day) {
            return CheckboxListTile(
              title: Text(day),
              value: _availableDays.contains(day),
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _availableDays.add(day);
                  } else {
                    _availableDays.remove(day);
                  }
                });
              },
            );
          }).toList(),

          const SizedBox(height: 24),

          const Text(
            'Working Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _startTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_startTime),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _endTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_endTime),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    if (_availableDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one available day'),
                        ),
                      );
                      return;
                    }
                    _register();
                  },
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ IMPROVED REGISTRATION METHOD - Using RegistrationResult
  Future<void> _register() async {
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();

      // Validate email first
      final isRegistered = await authService.isEmailRegistered(_emailController.text.trim());
      if (isRegistered) {
        throw 'This email is already registered. Please use a different email or sign in.';
      }

      // Build userData with proper type safety
      final userData = _buildUserData();

      debugPrint('Registering $_userType with data:');
      debugPrint(userData.toString());

      // Call registration with improved service
      final result = await authService.registerWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _userType,
        userData,
      );

      if (!result.success) {
        throw result.error ?? 'Registration failed';
      }

      // Registration successful
      if (mounted) {
        await _showSuccessDialog();
      }

    } catch (e) {
      debugPrint('Registration error: $e');

      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Build user data with proper types
  Map<String, dynamic> _buildUserData() {
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    final baseData = {
      'name': fullName,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'userType': _userType,
      'isActive': true,
      'registeredAt': DateTime.now().toIso8601String(),
    };

    switch (_userType) {
      case 'patient':
        if (_dateOfBirth == null) {
          throw 'Date of birth is required';
        }
        return {
          ...baseData,
          'dateOfBirth': _dateOfBirth!.toIso8601String(),
          'age': DateTime.now().year - _dateOfBirth!.year,
          'gender': _gender,
          'bloodGroup': _bloodGroup,
          'address': _addressController.text.trim(),
          'emergencyContact': _emergencyContactController.text.trim(),
          'allergies': _allergies.isNotEmpty ? _allergies : [],
          'chronicConditions': _chronicConditions.isNotEmpty ? _chronicConditions : [],
          'medicalHistory': [],
          'appointments': [],
        };

      case 'doctor':
        return {
          ...baseData,
          'specialization': _specializationController.text.trim(),
          'qualification': _qualificationController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'experience': int.tryParse(_experienceController.text) ?? 0,
          'consultationFee': double.tryParse(_consultationFeeController.text) ?? 0.0,
          'rating': 0.0,
          'totalRatings': 0,
          'availability': {
            'days': _availableDays,
            'startTime': _startTime,
            'endTime': _endTime,
          },
          'appointments': [],
          'patients': [],
        };

      case 'admin':
        return {
          ...baseData,
          'department': _departmentController.text.trim(),
          'role': 'admin',
          'permissions': ['read', 'write', 'delete'],
          'lastLogin': DateTime.now().toIso8601String(),
        };

      default:
        throw 'Invalid user type';
    }
  }

  // Show success dialog
  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
          ),
          title: const Text(
            'Registration Successful!',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your ${_userType} account has been created successfully.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'You can now sign in with your credentials.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to login
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Go to Login'),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}