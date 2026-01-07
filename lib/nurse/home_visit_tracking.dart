import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'nurse_drawer.dart';
import 'nurse_appbar.dart';

class HomeVisitTrackingPage extends StatefulWidget {
  const HomeVisitTrackingPage({super.key});

  @override
  State<HomeVisitTrackingPage> createState() => _HomeVisitTrackingPageState();
}

class _HomeVisitTrackingPageState extends State<HomeVisitTrackingPage> {
  final _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";

  final Color primaryTeal = const Color(0xFF356859);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color statusBlueBg = const Color(0xFFE0F2F1);
  final Color statusBlueText = const Color(0xFF4DB6AC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: const NurseAppBar(),
      drawer: const NurseDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderControls(),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('home_visits')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No records found."));
                  }

                  // Filtering logic for the search bar
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final name = (doc['name'] ?? "").toString().toLowerCase();
                    final ic =
                        (doc['ic_number'] ?? "").toString().toLowerCase();
                    return name.contains(_searchQuery.toLowerCase()) ||
                        ic.contains(_searchQuery.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          filteredDocs[index].data() as Map<String, dynamic>;
                      return _buildPatientVisitCard(data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeaderControls() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search by name or NRIC',
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterDropdown("Date", "All"),
        const SizedBox(width: 12),
        _buildFilterDropdown("Status", "All"),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _addRecordDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add New Home Visit"),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text("$label  ", style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }

  Widget _buildPatientVisitCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Top Info Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${data['ic_number']}  |  Age: ${data['age']}",
                          style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      Text(data['address'] ?? '',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Visit Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFC),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: DataTable(
              headingTextStyle: const TextStyle(
                  color: Colors.black54, fontWeight: FontWeight.w600),
              dataTextStyle: const TextStyle(color: Colors.black87),
              horizontalMargin: 20,
              dividerThickness: 0.1,
              columns: const [
                DataColumn(label: Text('Doctor')),
                DataColumn(label: Text('Visit Date')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Summary')),
                DataColumn(label: Text('Task'))
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text(data['doctor'] ?? '')),
                  DataCell(Text(data['visit_date'] ?? '')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: statusBlueBg,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text("Upcoming",
                          style: TextStyle(
                              color: statusBlueText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataCell(Text(data['summary'] ?? '')),
                  DataCell(Text(data['task'] ?? '')),
                ]),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _addRecordDialog() async {
    final icCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final taskCtrl = TextEditingController();
    const Color purpleTheme = Color(0xFF4A3469);
    final bpCtrl = TextEditingController();
    final hbA1cCtrl = TextEditingController();

    String? patientName;
    String? address;
    String? age;
    DateTime? selectedDate;

    List<DocumentSnapshot> icSuggestions = [];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFF8F9FA),
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFECE6F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_filled, color: purpleTheme, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        "New Home Visit",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  _buildSectionLabel("Patient Search"),
                  TextField(
                    controller: icCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter NRIC / IC Number',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) async {
                      if (val.length >= 1) {
                        final snap = await _firestore
                            .collection('patients')
                            .where('ic_number', isGreaterThanOrEqualTo: val)
                            .where('ic_number',
                                isLessThanOrEqualTo: '$val\uf8ff')
                            .limit(5)
                            .get();

                        setDialogState(() {
                          icSuggestions = snap.docs;
                        });
                      } else {
                        setDialogState(() => icSuggestions = []);
                      }
                    },
                  ),

                  if (icSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: Column(
                        children: icSuggestions.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(data['name'] ?? ''),
                            subtitle: Text(data['ic_number'] ?? ''),
                            onTap: () {
                              setDialogState(() {
                                icCtrl.text = data['ic_number'];
                                patientName = data['name'];
                                address = data['address'];
                                age = data['age'];
                                icSuggestions = [];
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  if (patientName != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: purpleTheme.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: purpleTheme.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "$patientName ($age yrs)\n$address",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  _buildSectionLabel("Visit Information"),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: doctorCtrl,
                          decoration: InputDecoration(
                            labelText: "Doctor Name",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setDialogState(() => selectedDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Visit Date",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              selectedDate == null
                                  ? "Select date"
                                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
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
                        child: TextField(
                          controller: bpCtrl,
                          decoration: InputDecoration(
                            labelText: "BP (mmHg)",
                            hintText: "120/80",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: hbA1cCtrl,
                          decoration: InputDecoration(
                            labelText: "HbA1c (%)",
                            hintText: "6.5",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: summaryCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Clinical Summary",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: taskCtrl,
                    decoration: InputDecoration(
                      labelText: "Task / Action Required",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// ---------- ACTION BUTTON ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purpleTheme,
                          minimumSize: const Size(220, 55),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (patientName == null || selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please complete all fields")),
                            );
                            return;
                          }

                          await _firestore.collection('home_visits').add({
                            'name': patientName,
                            'ic_number': icCtrl.text,
                            'age': age,
                            'address': address,
                            'doctor': doctorCtrl.text,
                            'visit_date':
                                "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                            'summary': summaryCtrl.text,
                            'task': taskCtrl.text,
                            'bp': bpCtrl.text,
                            'hba1c': hbA1cCtrl.text,
                            'status': 'Upcoming',
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          Navigator.pop(context);
                        },
                        child: const Text(
                          "SAVE VISIT",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogFieldInline(String label, TextEditingController controller,
      {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF4A345C), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF4A345C) // sidebarPurple
                  )),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPatientMiniProfile(String name, String age, String address) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Selected: $name (Age: $age) - $address",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(
      String label, DateTime? selectedDate, Function(DateTime) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedDate == null
                    ? "Select Date"
                    : "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
