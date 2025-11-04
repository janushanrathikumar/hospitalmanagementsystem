import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeVisitTrackingPage extends StatefulWidget {
  const HomeVisitTrackingPage({super.key});

  @override
  State<HomeVisitTrackingPage> createState() => _HomeVisitTrackingPageState();
}

class _HomeVisitTrackingPageState extends State<HomeVisitTrackingPage> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _addRecordDialog() async {
    final patientCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final taskCtrl = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Home Visit Record',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: patientCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Patient Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doctorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: selectedDate == null
                        ? 'Select Date'
                        : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Summary',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: taskCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Task',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2CBF),
                    minimumSize: const Size.fromHeight(45),
                  ),
                  onPressed: () async {
                    if (patientCtrl.text.isEmpty ||
                        doctorCtrl.text.isEmpty ||
                        summaryCtrl.text.isEmpty ||
                        taskCtrl.text.isEmpty ||
                        selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    await _firestore.collection('home_visits').add({
                      'patient': patientCtrl.text,
                      'doctor': doctorCtrl.text,
                      'date':
                          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                      'summary': summaryCtrl.text,
                      'task': taskCtrl.text,
                      'timestamp': Timestamp.now(),
                    });

                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B2CBF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HOME VISIT TRACKING'),
        backgroundColor: purple,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            children: [
              // Header Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HOME VISIT TRACKING',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.add_circle, color: purple, size: 30),
                      onPressed: _addRecordDialog,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('home_visits')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No records found'),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStatePropertyAll(
                            Colors.grey.shade800.withOpacity(0.9)),
                        headingTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(label: Text('Patient')),
                          DataColumn(label: Text('Doctor')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Summary')),
                          DataColumn(label: Text('Task')),
                        ],
                        rows: docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return DataRow(cells: [
                            DataCell(Text(data['patient'] ?? '')),
                            DataCell(Text(data['doctor'] ?? '')),
                            DataCell(Text(data['date'] ?? '')),
                            DataCell(Text(data['summary'] ?? '')),
                            DataCell(Text(data['task'] ?? '')),
                          ]);
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
