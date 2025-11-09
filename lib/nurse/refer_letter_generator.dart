import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import 'nurse_appbar.dart'; // <-- ADD THIS
import 'nurse_drawer.dart'; // <-- ADD THIS

class ReferLetterGeneratorPage extends StatefulWidget {
  const ReferLetterGeneratorPage({super.key});

  @override
  State<ReferLetterGeneratorPage> createState() =>
      _ReferLetterGeneratorPageState();
}

class _ReferLetterGeneratorPageState extends State<ReferLetterGeneratorPage> {
  // Form Controllers
  final _patientNameCtrl = TextEditingController();
  final _patientNricCtrl = TextEditingController();
  final _patientContactCtrl = TextEditingController();
  final _referrerNameCtrl = TextEditingController();
  final _referrerContactCtrl = TextEditingController();
  final _referrerOrgCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientNricCtrl.dispose();
    _patientContactCtrl.dispose();
    _referrerNameCtrl.dispose();
    _referrerContactCtrl.dispose();
    _referrerOrgCtrl.dispose();
    _dateCtrl.dispose();
    _summaryCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  /// Gathers all data from form controllers into a Map
  Map<String, dynamic> _getFormData() {
    return {
      'patientName': _patientNameCtrl.text,
      'patientNric': _patientNricCtrl.text,
      'patientContact': _patientContactCtrl.text,
      'referrerName': _referrerNameCtrl.text,
      'referrerContact': _referrerContactCtrl.text,
      'referrerOrg': _referrerOrgCtrl.text,
      'date': _dateCtrl.text,
      'summary': _summaryCtrl.text,
      'reason': _reasonCtrl.text,
      'timestamp': Timestamp.now(), // For ordering
    };
  }

  /// Clears all text controllers
  void _clearForm() {
    _patientNameCtrl.clear();
    _patientNricCtrl.clear();
    _patientContactCtrl.clear();
    _referrerNameCtrl.clear();
    _referrerContactCtrl.clear();
    _referrerOrgCtrl.clear();
    _dateCtrl.clear();
    _summaryCtrl.clear();
    _reasonCtrl.clear();
  }

  /// Handles the "Save" button press
  Future<void> _onSavePressed() async {
    if (_patientNameCtrl.text.isEmpty ||
        _patientNricCtrl.text.isEmpty ||
        _reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill at least Patient Name, NRIC, and Reason.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final data = _getFormData();
      await _firestore.collection('referral_letters').add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral Letter Saved!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving letter: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handles the "Generate" button press
  Future<void> _onGeneratePressed() async {
    final data = _getFormData();
    await _generatePdf(data);
  }

  /// Generates and prints a PDF from the provided data map
  Future<void> _generatePdf(Map<String, dynamic> data) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'REFERRAL LETTER',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              pw.Text(
                'Date: ${data['date'] ?? ''}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              // Patient Information
              pw.Text(
                'Patient Information',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildPdfInfoRow('Name:', data['patientName'] ?? ''),
              _buildPdfInfoRow('NRIC:', data['patientNric'] ?? ''),
              _buildPdfInfoRow('Contact:', data['patientContact'] ?? ''),
              pw.SizedBox(height: 20),

              // Referrer Information
              pw.Text(
                'Referrer Information',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildPdfInfoRow('Doctor/Nurse:', data['referrerName'] ?? ''),
              _buildPdfInfoRow('Organization:', data['referrerOrg'] ?? ''),
              _buildPdfInfoRow('Contact:', data['referrerContact'] ?? ''),
              pw.SizedBox(height: 20),

              // Referral Details
              pw.Text(
                'Referral Details',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildPdfSection('Treatment Summary:', data['summary'] ?? ''),
              pw.SizedBox(height: 15),
              _buildPdfSection('Reason for Referral:', data['reason'] ?? ''),
            ],
          );
        },
      ),
    );

    // Show print preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  /// Helper for building a simple "Label: Value" row in the PDF
  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  /// Helper for building a "Label" followed by a block of text in the PDF
  pw.Widget _buildPdfSection(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(value),
        ),
      ],
    );
  }

  /// Shows a Date Picker and updates the date controller
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NurseAppBar(), // <-- CHANGE THIS
      drawer: const NurseDrawer(), // <-- ADD THIS
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The Form
            _buildFormCard(),
            const SizedBox(height: 24),
            // The Table of saved letters
            _buildSavedLettersTable(),
          ],
        ),
      ),
    );
  }

  /// Builds the main form card UI
  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info
            const Text('Patient Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField(_patientNameCtrl, 'Name'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_patientNricCtrl, 'NRIC')),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildTextField(
                        _patientContactCtrl, 'Contact Number',
                        keyboardType: TextInputType.phone)),
              ],
            ),
            const SizedBox(height: 24),

            // Referrer Info
            const Text('Referrer Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField(_referrerNameCtrl, 'Doctor/Nurse Name'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        _referrerContactCtrl, 'Contact Number',
                        keyboardType: TextInputType.phone)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildTextField(_referrerOrgCtrl, 'Organization')),
              ],
            ),
            const SizedBox(height: 24),

            // Referral Details
            const Text('Referral Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField(
              _dateCtrl,
              'Date (YYYY-MM-DD)',
              readOnly: true,
              onTap: _selectDate,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(_summaryCtrl, 'Treatment Summary', maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(_reasonCtrl, 'Reason for Referral', maxLines: 5),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _onGeneratePressed,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                  child: const Text('Generate'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _onSavePressed,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                  child: const Text('Save'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _clearForm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper for building a styled TextField
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
    );
  }

  /// Builds the stream-powered data table of saved letters
  Widget _buildSavedLettersTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Referral Letters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('referral_letters')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No saved letters found.'));
                }

                final letters = snapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Patient Name')),
                      DataColumn(label: Text('NRIC')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Referrer')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: letters.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DataRow(
                        cells: [
                          DataCell(Text(data['patientName'] ?? '')),
                          DataCell(Text(data['patientNric'] ?? '')),
                          DataCell(Text(data['date'] ?? '')),
                          DataCell(Text(data['referrerName'] ?? '')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.blue),
                              onPressed: () {
                                // Re-generate PDF using the saved data
                                _generatePdf(data);
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
