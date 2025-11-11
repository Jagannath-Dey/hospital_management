import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hospital_management_app/models/prescription.dart';
import 'package:hospital_management_app/models/doctor.dart';
import 'package:hospital_management_app/models/patient.dart';
import 'package:intl/intl.dart';

class PdfService {
  // Generate Prescription PDF
  static Future<pw.Document> generatePrescriptionPdf({
    required Prescription prescription,
    required Doctor doctor,
    required Patient patient,
  }) async {
    final pdf = pw.Document();

    // Load custom font (optional)
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(doctor, fontBold),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2, color: PdfColors.teal),
          pw.SizedBox(height: 20),

          // Patient Information
          _buildPatientInfo(patient, prescription, font, fontBold),
          pw.SizedBox(height: 20),

          // Diagnosis
          _buildDiagnosis(prescription, font, fontBold),
          pw.SizedBox(height: 20),

          // Prescriptions Table
          _buildPrescriptionTable(prescription, font, fontBold),
          pw.SizedBox(height: 20),

          // Additional Notes
          if (prescription.additionalNotes != null &&
              prescription.additionalNotes!.isNotEmpty)
            _buildAdditionalNotes(prescription, font, fontBold),

          pw.Spacer(),

          // Footer
          _buildFooter(doctor, prescription, font),
        ],
        footer: (context) => _buildPageFooter(context, font),
      ),
    );

    return pdf;
  }

  // Header Section
  static pw.Widget _buildHeader(Doctor doctor, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MEDICAL PRESCRIPTION',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 24,
                    color: PdfColors.teal,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Dr. ${doctor.fullName}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 18,
                  ),
                ),
                pw.Text(
                  doctor.specialization,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'License: ${doctor.licenseNumber}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Container(
              width: 80,
              height: 80,
              decoration: pw.BoxDecoration(
                color: PdfColors.teal,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Center(
                child: pw.Icon(
                  const pw.IconData(0xe3ab), // Medical icon
                  size: 48,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Icon(const pw.IconData(0xe0cd), size: 12, color: PdfColors.grey),
            pw.SizedBox(width: 4),
            pw.Text(
              doctor.phone,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(width: 16),
            pw.Icon(const pw.IconData(0xe0be), size: 12, color: PdfColors.grey),
            pw.SizedBox(width: 4),
            pw.Text(
              doctor.email,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  // Patient Information
  static pw.Widget _buildPatientInfo(
      Patient patient,
      Prescription prescription,
      pw.Font font,
      pw.Font fontBold,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PATIENT INFORMATION',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 14,
              color: PdfColors.teal,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: _buildInfoField('Patient Name', patient.fullName, font, fontBold),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildInfoField(
                  'Date',
                  DateFormat('MMM dd, yyyy').format(prescription.prescribedDate),
                  font,
                  fontBold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: _buildInfoField('Age', '${patient.age} years', font, fontBold),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildInfoField('Gender', patient.gender, font, fontBold),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildInfoField('Blood Group', patient.bloodGroup, font, fontBold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _buildInfoField('Patient ID', patient.id.substring(0, 16), font, fontBold),
        ],
      ),
    );
  }

  // Diagnosis Section
  static pw.Widget _buildDiagnosis(
      Prescription prescription,
      pw.Font font,
      pw.Font fontBold,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DIAGNOSIS',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 14,
              color: PdfColors.teal,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            prescription.diagnosis,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Prescription Table
  static pw.Widget _buildPrescriptionTable(
      Prescription prescription,
      pw.Font font,
      pw.Font fontBold,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: const pw.BoxDecoration(
            color: PdfColors.teal,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            'PRESCRIBED MEDICATIONS (Rx)',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('Medicine Name', fontBold),
                _buildTableHeader('Dosage', fontBold),
                _buildTableHeader('Frequency', fontBold),
                _buildTableHeader('Duration', fontBold),
              ],
            ),
            // Medicines
            ...prescription.medicines.map((medicine) {
              return pw.TableRow(
                children: [
                  _buildTableCell(medicine.name, font),
                  _buildTableCell(medicine.dosage, font),
                  _buildTableCell(medicine.frequency, font),
                  _buildTableCell('${medicine.duration} days', font),
                ],
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 12),
        // Medicine Instructions
        ...prescription.medicines.map((medicine) {
          if (medicine.instructions != null && medicine.instructions!.isNotEmpty) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Icon(
                    const pw.IconData(0xe88e),
                    size: 16,
                    color: PdfColors.blue,
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          medicine.name,
                          style: pw.TextStyle(font: fontBold, fontSize: 11),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          medicine.instructions!,
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return pw.SizedBox();
        }).toList(),
      ],
    );
  }

  // Additional Notes
  static pw.Widget _buildAdditionalNotes(
      Prescription prescription,
      pw.Font font,
      pw.Font fontBold,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        border: pw.Border.all(color: PdfColors.orange200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                const pw.IconData(0xe88e),
                size: 16,
                color: PdfColors.orange,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'ADDITIONAL NOTES',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: PdfColors.orange,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            prescription.additionalNotes!,
            style: pw.TextStyle(font: font, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Footer
  static pw.Widget _buildFooter(
      Doctor doctor,
      Prescription prescription,
      pw.Font font,
      ) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Doctor\'s Signature',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 150,
                  height: 1,
                  color: PdfColors.grey800,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Dr. ${doctor.fullName}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.Text(
                  DateFormat('MMM dd, yyyy').format(prescription.prescribedDate),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Prescription ID',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    prescription.id.substring(0, 16),
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Page Footer
  static pw.Widget _buildPageFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  // Helper Widgets
  static pw.Widget _buildInfoField(
      String label,
      String value,
      pw.Font font,
      pw.Font fontBold,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 10,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
        ),
      ),
    );
  }

  // Save PDF to device
  static Future<File> savePdf(
      pw.Document pdf,
      String fileName,
      ) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // Share PDF
  static Future<void> sharePdf(
      pw.Document pdf,
      String fileName,
      ) async {
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '$fileName.pdf',
    );
  }

  // Print PDF
  static Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // Preview PDF
  static Future<void> previewPdf(
      pw.Document pdf,
      String title,
      ) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: title,
    );
  }
}