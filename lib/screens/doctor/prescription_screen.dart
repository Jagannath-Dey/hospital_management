import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hospital_management_app/models/appointment.dart';
import 'package:hospital_management_app/models/patient.dart';
import 'package:hospital_management_app/models/prescription.dart';
import 'package:hospital_management_app/models/billing.dart';
import 'package:hospital_management_app/models/doctor.dart';
import 'package:hospital_management_app/services/database_service.dart';
import 'package:hospital_management_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PrescriptionScreen extends StatefulWidget {
  final Appointment appointment;
  final Patient patient;

  const PrescriptionScreen({
    Key? key,
    required this.appointment,
    required this.patient,
  }) : super(key: key);

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _diagnosisController = TextEditingController();
  final _vitalBPController = TextEditingController();
  final _vitalPulseController = TextEditingController();
  final _vitalTempController = TextEditingController();
  final _vitalWeightController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _followUpDaysController = TextEditingController();

  // Medicine Controllers
  final List<MedicineEntry> _medicines = [];

  // Lab Tests
  final List<String> _recommendedTests = [];
  final _testController = TextEditingController();

  bool _isLoading = false;
  Doctor? _doctor;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
    // Add one empty medicine entry by default
    _addMedicineEntry();
  }

  Future<void> _loadDoctorInfo() async {
    final authService = context.read<AuthService>();
    final doctorId = authService.currentUser?.uid;
    if (doctorId != null) {
      _doctor = await _databaseService.getDoctor(doctorId);
      setState(() {});
    }
  }

  void _addMedicineEntry() {
    setState(() {
      _medicines.add(MedicineEntry());
    });
  }

  void _removeMedicineEntry(int index) {
    setState(() {
      _medicines[index].dispose();
      _medicines.removeAt(index);
    });
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _vitalBPController.dispose();
    _vitalPulseController.dispose();
    _vitalTempController.dispose();
    _vitalWeightController.dispose();
    _symptomsController.dispose();
    _additionalNotesController.dispose();
    _followUpDaysController.dispose();
    _testController.dispose();
    for (var medicine in _medicines) {
      medicine.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Prescription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
            tooltip: 'Generate PDF',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Information Card
              _buildPatientInfoCard(),
              const SizedBox(height: 16),

              // Vital Signs Card
              _buildVitalSignsCard(),
              const SizedBox(height: 16),

              // Symptoms & Diagnosis Card
              _buildDiagnosisCard(),
              const SizedBox(height: 16),

              // Medicines Card
              _buildMedicinesCard(),
              const SizedBox(height: 16),

              // Lab Tests Card
              _buildLabTestsCard(),
              const SizedBox(height: 16),

              // Additional Notes & Follow-up
              _buildAdditionalInfoCard(),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Patient Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ID: ${widget.patient.id.substring(0, 8)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', widget.patient.fullName),
            _buildInfoRow('Age', '${widget.patient.age} years'),
            _buildInfoRow('Gender', widget.patient.gender),
            _buildInfoRow('Blood Group', widget.patient.bloodGroup),
            _buildInfoRow('Phone', widget.patient.phone),
            if (widget.patient.allergies.isNotEmpty)
              _buildInfoRow(
                'Allergies',
                widget.patient.allergies.join(', '),
                isHighlight: true,
              ),
            if (widget.patient.chronicConditions.isNotEmpty)
              _buildInfoRow(
                'Chronic Conditions',
                widget.patient.chronicConditions.join(', '),
                isHighlight: true,
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason for visit: ${widget.appointment.reason}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vital Signs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vitalBPController,
                    decoration: const InputDecoration(
                      labelText: 'Blood Pressure',
                      hintText: '120/80',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _vitalPulseController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Pulse',
                      hintText: '72',
                      suffixText: 'bpm',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vitalTempController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Temperature',
                      hintText: '98.6',
                      suffixText: '°F',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _vitalWeightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      hintText: '70',
                      suffixText: 'kg',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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

  Widget _buildDiagnosisCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Symptoms & Diagnosis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Symptoms',
                hintText: 'Enter patient symptoms...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter symptoms';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diagnosisController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Diagnosis *',
                hintText: 'Enter diagnosis...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter diagnosis';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prescription',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMedicineEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Medicine'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_medicines.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No medicines added',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _addMedicineEntry,
                      child: const Text('Add First Medicine'),
                    ),
                  ],
                ),
              )
            else
              ..._medicines.asMap().entries.map((entry) {
                int index = entry.key;
                MedicineEntry medicine = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Medicine ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeMedicineEntry(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: medicine.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name *',
                          hintText: 'e.g., Paracetamol',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter medicine name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: medicine.dosageController,
                              decoration: const InputDecoration(
                                labelText: 'Dosage *',
                                hintText: 'e.g., 500mg',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter dosage';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: medicine.frequency,
                              decoration: const InputDecoration(
                                labelText: 'Frequency *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                'Once daily',
                                'Twice daily',
                                'Thrice daily',
                                'Four times daily',
                                'Every 4 hours',
                                'Every 6 hours',
                                'Every 8 hours',
                                'Every 12 hours',
                                'As needed',
                                'Before meals',
                                'After meals',
                              ].map((freq) {
                                return DropdownMenuItem(
                                  value: freq,
                                  child: Text(
                                    freq,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  medicine.frequency = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: medicine.durationController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Duration (days) *',
                                hintText: 'e.g., 7',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter duration';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: medicine.timing,
                              decoration: const InputDecoration(
                                labelText: 'Timing',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                'Before Food',
                                'After Food',
                                'With Food',
                                'Empty Stomach',
                                'Anytime',
                              ].map((time) {
                                return DropdownMenuItem(
                                  value: time,
                                  child: Text(
                                    time,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  medicine.timing = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: medicine.instructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Special Instructions (Optional)',
                          hintText: 'e.g., Take with plenty of water',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
    );
  }

  Widget _buildLabTestsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommended Lab Tests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _testController,
                    decoration: const InputDecoration(
                      labelText: 'Add Lab Test',
                      hintText: 'e.g., Complete Blood Count',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_testController.text.isNotEmpty) {
                      setState(() {
                        _recommendedTests.add(_testController.text);
                        _testController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).primaryColor,
                  iconSize: 32,
                ),
              ],
            ),
            if (_recommendedTests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recommendedTests.map((test) {
                  return Chip(
                    label: Text(test),
                    onDeleted: () {
                      setState(() {
                        _recommendedTests.remove(test);
                      });
                    },
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            // Quick add common tests
            const Text(
              'Quick Add:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'CBC',
                'Blood Sugar',
                'Urine Test',
                'X-Ray',
                'ECG',
                'Lipid Profile',
                'Thyroid Test',
              ].map((test) {
                return ActionChip(
                  label: Text(
                    test,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    if (!_recommendedTests.contains(test)) {
                      setState(() {
                        _recommendedTests.add(test);
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _additionalNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional Notes / Advice',
                hintText: 'Any additional instructions or lifestyle advice...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _followUpDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Follow-up After (days)',
                hintText: 'e.g., 7',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                helperText: 'Leave empty if no follow-up needed',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Save as draft
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved as draft'),
                ),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _savePrescription,
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.check),
            label: Text(_isLoading ? 'Saving...' : 'Complete & Save'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isHighlight ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one medicine'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create prescription
      final prescriptionId = const Uuid().v4();
      final medicines = _medicines.map((entry) {
        return Medicine(
          name: entry.nameController.text,
          dosage: entry.dosageController.text,
          frequency: entry.frequency,
          duration: int.parse(entry.durationController.text),
          instructions: entry.instructionsController.text.isNotEmpty
              ? '${entry.timing}. ${entry.instructionsController.text}'
              : entry.timing,
        );
      }).toList();

      final prescription = Prescription(
        id: prescriptionId,
        appointmentId: widget.appointment.id,
        patientId: widget.patient.id,
        doctorId: widget.appointment.doctorId,
        diagnosis: _diagnosisController.text,
        medicines: medicines,
        additionalNotes: _additionalNotesController.text.isNotEmpty
            ? _additionalNotesController.text
            : null,
        prescribedDate: DateTime.now(),
        followUpDate: _followUpDaysController.text.isNotEmpty
            ? DateTime.now().add(
          Duration(days: int.parse(_followUpDaysController.text)),
        ).toIso8601String()
            : null,
      );

      await _databaseService.createPrescription(prescription);

      // Update appointment status
      await _databaseService.updateAppointmentStatus(
        widget.appointment.id,
        'completed',
      );

      // Create bill
      await _createBill();

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          title: const Text('Prescription Saved!'),
          content: const Text(
            'The prescription has been saved successfully. Would you like to generate a PDF?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
              },
              child: const Text('No, Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _generatePDF();
              },
              child: const Text('Generate PDF'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving prescription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBill() async {
    if (_doctor == null) return;

    final billId = const Uuid().v4();
    final items = <BillItem>[];

    // Add medicine charges if any
    if (_medicines.isNotEmpty) {
      items.add(
        BillItem(
          description: 'Medicines',
          amount: 0, // In real app, calculate based on medicine prices
          quantity: _medicines.length,
        ),
      );
    }

    // Add lab test charges if any
    if (_recommendedTests.isNotEmpty) {
      items.add(
        BillItem(
          description: 'Lab Tests',
          amount: 0, // In real app, calculate based on test prices
          quantity: _recommendedTests.length,
        ),
      );
    }

    final subtotal = _doctor!.consultationFee +
        items.fold(0.0, (sum, item) => sum + item.total);
    final tax = subtotal * 0.1; // 10% tax
    final totalAmount = subtotal + tax;

    final bill = Billing(
      id: billId,
      patientId: widget.patient.id,
      appointmentId: widget.appointment.id,
      billDate: DateTime.now(),
      consultationFee: _doctor!.consultationFee,
      items: items,
      subtotal: subtotal,
      tax: tax,
      discount: 0,
      totalAmount: totalAmount,
      paymentStatus: 'pending',
    );

    await _databaseService.createBill(bill);
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'HOSPITAL MANAGEMENT SYSTEM',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'E-PRESCRIPTION',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Doctor and Date Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Dr. ${_doctor?.fullName ?? ""}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(_doctor?.specialization ?? ""),
                    pw.Text('License: ${_doctor?.licenseNumber ?? ""}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Date: ${DateFormat('MMM d, y').format(DateTime.now())}',
                    ),
                    pw.Text(
                      'Time: ${DateFormat('HH:mm').format(DateTime.now())}',
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Patient Information
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PATIENT INFORMATION',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Name: ${widget.patient.fullName}'),
                      pw.Text('Age: ${widget.patient.age} years'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Gender: ${widget.patient.gender}'),
                      pw.Text('Blood Group: ${widget.patient.bloodGroup}'),
                    ],
                  ),
                  if (widget.patient.allergies.isNotEmpty)
                    pw.Text(
                      'Allergies: ${widget.patient.allergies.join(', ')}',
                      style: const pw.TextStyle(color: PdfColors.red),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Vital Signs (if entered)
            if (_vitalBPController.text.isNotEmpty ||
                _vitalPulseController.text.isNotEmpty) ...[
              pw.Text(
                'VITAL SIGNS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (_vitalBPController.text.isNotEmpty)
                    pw.Text('BP: ${_vitalBPController.text} mmHg'),
                  if (_vitalPulseController.text.isNotEmpty)
                    pw.Text('Pulse: ${_vitalPulseController.text} bpm'),
                  if (_vitalTempController.text.isNotEmpty)
                    pw.Text('Temp: ${_vitalTempController.text}°F'),
                  if (_vitalWeightController.text.isNotEmpty)
                    pw.Text('Weight: ${_vitalWeightController.text} kg'),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Diagnosis
            pw.Text(
              'DIAGNOSIS',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(_diagnosisController.text),
            ),
            pw.SizedBox(height: 20),

            // Prescription
            pw.Text(
              'PRESCRIPTION',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 12),
            ..._medicines.asMap().entries.map((entry) {
              int index = entry.key;
              MedicineEntry medicine = entry.value;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${index + 1}. ${medicine.nameController.text}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(medicine.dosageController.text),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${medicine.frequency} for ${medicine.durationController.text} days',
                    ),
                    if (medicine.instructionsController.text.isNotEmpty)
                      pw.Text(
                        medicine.instructionsController.text,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              );
            }).toList(),

            // Lab Tests
            if (_recommendedTests.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'RECOMMENDED LAB TESTS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              ..._recommendedTests.map((test) => pw.Text('• $test')).toList(),
            ],

            // Additional Notes
            if (_additionalNotesController.text.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'ADDITIONAL NOTES',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.yellow50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(_additionalNotesController.text),
              ),
            ],

            // Follow-up
            if (_followUpDaysController.text.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Follow-up after ${_followUpDaysController.text} days',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],

            // Footer
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Doctor\'s Signature',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      width: 150,
                      height: 1,
                      color: PdfColors.black,
                    ),
                  ],
                ),
                pw.Text(
                  'Generated on ${DateFormat('MMM d, y HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Display the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'prescription_${widget.patient.fullName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}

// Medicine Entry Helper Class
class MedicineEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  String frequency = 'Twice daily';
  String timing = 'After Food';

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    durationController.dispose();
    instructionsController.dispose();
  }
}