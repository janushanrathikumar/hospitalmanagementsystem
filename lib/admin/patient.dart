import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adminappbar.dart'; 
import 'admindrawer.dart'; // Ensure this is imported

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  final _firestore = FirebaseFirestore.instance;

  // Define the purple brand color as a constant for consistency
  static const Color brandPurple = Color(0xFF7B2CBF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const AdminAppBar(), 
      drawer: const AdminDrawer(), 
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Row(
              children: [
                Icon(Icons.people_alt_rounded, color: brandPurple, size: 28),
                SizedBox(width: 12),
                Text(
                  'Patient Directory',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Data Table Section
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('patients')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: brandPurple));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final docs = snapshot.data!.docs;

                  return Card(
                    elevation: 4,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            // This ensures the table stretches to fill the width if data is sparse
                            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(brandPurple),
                              headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              dataRowMaxHeight: 60,
                              columnSpacing: 40,
                              columns: const [
                                DataColumn(label: Text('IC Number')),
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Address')),
                                DataColumn(label: Text('Age')),
                                DataColumn(label: Text('Mobile')),
                              ],
                              rows: docs.asMap().entries.map((entry) {
                                int index = entry.key;
                                var d = entry.value;
                                final data = d.data() as Map<String, dynamic>;
                                
                                return DataRow(
                                  // Zebra striping: Alternate colors for rows
                                  color: WidgetStateProperty.all(
                                    index.isEven ? Colors.white : Colors.grey.withOpacity(0.05),
                                  ),
                                  cells: [
                                    DataCell(Text(data['ic_number']?.toString() ?? '-', 
                                        style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(data['name']?.toString() ?? '-')),
                                    DataCell(Text(data['address']?.toString() ?? '-')),
                                    DataCell(Text(data['age']?.toString() ?? '-')),
                                    DataCell(Text(data['mobile']?.toString() ?? '-')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No patient records found', 
            style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}