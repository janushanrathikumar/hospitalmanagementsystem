import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_appbar.dart';
import 'doctor_drawer.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  final _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  String _filterGender = "All";
  String _filterAgeRange = "All";

  // Colors from the design
  final Color accentGreen = const Color(0xFF3E6E64);
  final Color bgGrey = const Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: DoctorAppBar(),
      drawer: DoctorDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PATIENT LIST',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 20),
            _buildTopFilterBar(),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    const Divider(height: 1),
                    Expanded(child: _buildPatientListStream()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TOP FILTER & SEARCH BAR ---
  Widget _buildTopFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search by name or NRIC",
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildDropdown("Gender", ["All", "Male", "Female"], _filterGender,
              (val) {
            setState(() => _filterGender = val!);
          }),
          const SizedBox(width: 16),
          _buildDropdown(
              "Age", ["All", "0-18", "19-40", "41-60", "60+"], _filterAgeRange,
              (val) {
            setState(() => _filterAgeRange = val!);
          }),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return Row(
      children: [
        Text("$label ", style: const TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // --- TABLE HEADER ---
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: const Row(
        children: [
          Expanded(
              child:
                  Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text("NRIC", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text("Gender",
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text("Age", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text("Address",
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text("BMI", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text("BP", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text("HbA1c", style: TextStyle(fontWeight: FontWeight.bold))),
          
        ],
      ),
    );
  }

  // --- LIST CONTENT ---
  Widget _buildPatientListStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('patients')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.where((d) {
          final name = d['name'].toString().toLowerCase();
          final ic = d['ic_number'].toString();
          final gender = d['gender'] ?? "";

          bool matchesSearch =
              name.contains(_searchQuery) || ic.contains(_searchQuery);
          bool matchesGender =
              _filterGender == "All" || gender == _filterGender;
          return matchesSearch && matchesGender;
        }).toList();

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildPatientRow(data);
          },
        );
      },
    );
  }

  Widget _buildPatientRow(Map<String, dynamic> data) {
    bool isMale = data['gender'] == "Male";
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
              child: Text(data['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(data['ic_number'] ?? '-')),
          Expanded(
            child: Row(
              children: [
                Icon(isMale ? Icons.person : Icons.person_2,
                    size: 16, color: isMale ? Colors.blue : Colors.pink),
                const SizedBox(width: 4),
                Text(data['gender'] ?? '-'),
              ],
            ),
          ),
          Expanded(child: Text(data['age']?.toString() ?? '-')),
          Expanded(
              flex: 2,
              child: Text(data['address'] ?? '-',
                  overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(data['bmi'] ?? '-')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['bp'] ?? '-'),
                const Text("mmHg",
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(child: Text("${data['hba1c'] ?? '-'}%")),
        
        ],
      ),
    );
  }
}
