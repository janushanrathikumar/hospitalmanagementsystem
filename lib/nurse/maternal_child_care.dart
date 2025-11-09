import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../nurse/nurse_appbar.dart';
import '../nurse/nurse_drawer.dart';

class MaternalChildCarePage extends StatefulWidget {
  const MaternalChildCarePage({super.key});

  @override
  State<MaternalChildCarePage> createState() => _MaternalChildCarePageState();
}

class _MaternalChildCarePageState extends State<MaternalChildCarePage> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _addRecordDialog() async {
    final icCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final vaccinationCtrl = TextEditingController();
    final riskSignCtrl = TextEditingController();

    DateTime? selectedDate;
    String? name, address, age, mobile;
    List<String> icSuggestions = [];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Maternal and Child Care Record',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // IC Number input
                  TextField(
                    controller: icCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Patient IC Number',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) async {
                      if (val.length >= 2) {
                        final querySnap =
                            await _firestore.collection('patients').get();

                        final matches = querySnap.docs
                            .where((doc) => doc.id
                                .toLowerCase()
                                .contains(val.toLowerCase()))
                            .map((doc) => doc.id)
                            .toList();

                        setState(() => icSuggestions = matches);
                      } else {
                        setState(() => icSuggestions = []);
                      }
                    },
                  ),

                  if (icSuggestions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: icSuggestions
                            .map(
                              (ic) => ListTile(
                                title: Text(ic),
                                onTap: () async {
                                  icCtrl.text = ic;
                                  setState(() => icSuggestions = []);

                                  final doc = await _firestore
                                      .collection('patients')
                                      .doc(ic)
                                      .get();
                                  if (doc.exists) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    setState(() {
                                      name = data['name'];
                                      address = data['address'];
                                      age = data['age'];
                                      mobile = data['mobile'];
                                    });
                                  }
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 12),

                  if (name != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: $name'),
                          Text('Address: $address'),
                          Text('Age: $age'),
                          Text('Mobile: $mobile'),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Visit Date picker
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: selectedDate == null
                          ? 'Select Visit Date'
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
                  const SizedBox(height: 16),

                  // Type
                  TextField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vaccination Status
                  TextField(
                    controller: vaccinationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Vaccination Status',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Risk Sign
                  TextField(
                    controller: riskSignCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Risk Sign',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B2CBF),
                      minimumSize: const Size.fromHeight(45),
                    ),
                    onPressed: () async {
                      if (icCtrl.text.isEmpty ||
                          selectedDate == null ||
                          typeCtrl.text.isEmpty ||
                          vaccinationCtrl.text.isEmpty ||
                          riskSignCtrl.text.isEmpty ||
                          name == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      await _firestore.collection('maternal_child_care').add({
                        'ic_number': icCtrl.text,
                        'name': name,
                        'address': address,
                        'age': age,
                        'mobile': mobile,
                        'visit_date':
                            '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                        'type': typeCtrl.text,
                        'vaccination_status': vaccinationCtrl.text,
                        'risk_sign': riskSignCtrl.text,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B2CBF);

    return Scaffold(
      appBar: const NurseAppBar(),
      drawer: const NurseDrawer(),
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
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MATERNAL AND CHILD CARE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
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
                  stream: _firestore
                      .collection('maternal_child_care')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No records found'));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            MaterialStatePropertyAll(Colors.grey.shade800),
                        headingTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(label: Text('IC Number')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Address')),
                          DataColumn(label: Text('Age')),
                          DataColumn(label: Text('Mobile')),
                          DataColumn(label: Text('Visit Date')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Vaccination Status')),
                          DataColumn(label: Text('Risk Sign')),
                        ],
                        rows: docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return DataRow(cells: [
                            DataCell(Text(data['ic_number'] ?? '')),
                            DataCell(Text(data['name'] ?? '')),
                            DataCell(Text(data['address'] ?? '')),
                            DataCell(Text(data['age'] ?? '')),
                            DataCell(Text(data['mobile'] ?? '')),
                            DataCell(Text(data['visit_date'] ?? '')),
                            DataCell(Text(data['type'] ?? '')),
                            DataCell(Text(data['vaccination_status'] ?? '')),
                            DataCell(Text(data['risk_sign'] ?? '')),
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
