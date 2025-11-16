import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adminappbar.dart'; // Make sure this path is correct

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B2CBF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AdminAppBar(), // remove const for dynamic rebuild
      drawer: AdminDrawer(), // remove const
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Expanded to make table scrollable within column
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('patients')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No patient records'));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          WidgetStatePropertyAll(Colors.grey.shade800),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      columns: const [
                        DataColumn(label: Text('IC Number')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Address')),
                        DataColumn(label: Text('Age')),
                        DataColumn(label: Text('Mobile')),
                      ],
                      rows: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text(data['ic_number'] ?? '')),
                          DataCell(Text(data['name'] ?? '')),
                          DataCell(Text(data['address'] ?? '')),
                          DataCell(Text(data['age'] ?? '')),
                          DataCell(Text(data['mobile'] ?? '')),
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
    );
  }
}
