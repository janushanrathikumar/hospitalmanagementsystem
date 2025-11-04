// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../nurse/nurse_appbar.dart';
// import '../nurse/nurse_drawer.dart';

// class HomeVisitTrackingPage extends StatefulWidget {
//   const HomeVisitTrackingPage({super.key});

//   @override
//   State<HomeVisitTrackingPage> createState() => _HomeVisitTrackingPageState();
// }

// class _HomeVisitTrackingPageState extends State<HomeVisitTrackingPage> {
//   final _firestore = FirebaseFirestore.instance;

//   Future<void> _addRecordDialog() async {
//     final patientCtrl = TextEditingController();
//     final summaryCtrl = TextEditingController();
//     final taskCtrl = TextEditingController();

//     String? selectedDoctorUid;
//     String? selectedDoctorName;
//     Map<String, dynamic>? selectedAvailability;
//     DateTime? selectedDate;

//     await showDialog(
//       context: context,
//       builder: (_) => StatefulBuilder(
//         builder: (context, setState) => Dialog(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: Container(
//             width: 500,
//             padding: const EdgeInsets.all(24),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Add Home Visit Record',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 20),

//                   // Patient Name
//                   TextField(
//                     controller: patientCtrl,
//                     decoration: const InputDecoration(
//                       labelText: 'Patient Name',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Doctor dropdown
//                   FutureBuilder<QuerySnapshot>(
//                     future: _firestore.collection('doctor_availability').get(),
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData) {
//                         return const Center(child: CircularProgressIndicator());
//                       }

// // Build unique doctor list correctly
//                       final doctorMap = <String, String>{};
//                       for (var doc in snapshot.data!.docs) {
//                         final data = doc.data() as Map<String, dynamic>;
//                         doctorMap[data['uid']] = data['user_name'];
//                       }
//                       final doctorList = doctorMap.entries
//                           .map((e) => {'uid': e.key, 'user_name': e.value})
//                           .toList();

//                       return DropdownButtonFormField<String>(
//                         decoration: const InputDecoration(
//                           labelText: 'Select Doctor',
//                           border: OutlineInputBorder(),
//                         ),
//                         value: selectedDoctorUid,
//                         items: doctorList
//                             .map<DropdownMenuItem<String>>(
//                                 (d) => DropdownMenuItem<String>(
//                                       value: d['uid'] as String,
//                                       child: Text(d['user_name'] as String),
//                                     ))
//                             .toList(),
//                         onChanged: (val) async {
//                           selectedDoctorUid = val;
//                           selectedDoctorName = doctorList
//                               .firstWhere((e) => e['uid'] == val)['user_name'];

// // Fetch all availability docs once
//                           final availDocs = snapshot.data!.docs;
//                           List<Map<String, dynamic>> doctorAvailabilities = [];

//                           for (var d in availDocs) {
//                             final data = d.data() as Map<String, dynamic>;
//                             if (data['uid'] == val) {
//                               doctorAvailabilities.add(data);
//                             }
//                           }

// // Sort by timestamp descending
//                           doctorAvailabilities.sort((a, b) {
//                             final t1 = a['timestamp'] as Timestamp?;
//                             final t2 = b['timestamp'] as Timestamp?;
//                             return (t2?.compareTo(t1 ?? Timestamp.now()) ?? 0);
//                           });

//                           selectedAvailability = {
//                             'doctor_availabilities': doctorAvailabilities,
//                           };

//                           setState(() {});
//                         },
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 16),

//                   // Show availability info
//                   if (selectedAvailability != null &&
//                       selectedAvailability!['doctor_availabilities'] != null)
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Doctor Availability:',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87),
//                           ),
//                           const SizedBox(height: 8),
//                           Container(
//                             constraints: const BoxConstraints(maxHeight: 200),
//                             child: ListView.builder(
//                               shrinkWrap: true,
//                               itemCount:
//                                   selectedAvailability!['doctor_availabilities']
//                                       .length,
//                               itemBuilder: (context, index) {
//                                 final avail = selectedAvailability![
//                                     'doctor_availabilities'][index];
//                                 return Container(
//                                   margin: const EdgeInsets.only(bottom: 6),
//                                   padding: const EdgeInsets.symmetric(
//                                       vertical: 8, horizontal: 10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     border:
//                                         Border.all(color: Colors.grey.shade300),
//                                     borderRadius: BorderRadius.circular(6),
//                                   ),
//                                   child: Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Text('Date: ${avail['date']}'),
//                                       Text(
//                                           'Time: ${avail['start']} - ${avail['end']}'),
//                                     ],
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                   const SizedBox(height: 16),

//                   // Date picker
//                   TextFormField(
//                     readOnly: true,
//                     decoration: InputDecoration(
//                       labelText: selectedDate == null
//                           ? 'Select Visit Date'
//                           : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
//                       border: const OutlineInputBorder(),
//                       suffixIcon: IconButton(
//                         icon: const Icon(Icons.calendar_today),
//                         onPressed: () async {
//                           final picked = await showDatePicker(
//                             context: context,
//                             initialDate: DateTime.now(),
//                             firstDate: DateTime(2020),
//                             lastDate: DateTime(2030),
//                           );
//                           if (picked != null) {
//                             setState(() => selectedDate = picked);
//                           }
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Summary
//                   TextField(
//                     controller: summaryCtrl,
//                     maxLines: 2,
//                     decoration: const InputDecoration(
//                       labelText: 'Summary',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Task
//                   TextField(
//                     controller: taskCtrl,
//                     decoration: const InputDecoration(
//                       labelText: 'Task',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   ElevatedButton.icon(
//                     icon: const Icon(Icons.save),
//                     label: const Text('Save Record'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF7B2CBF),
//                       minimumSize: const Size.fromHeight(45),
//                     ),
//                     onPressed: () async {
//                       if (patientCtrl.text.isEmpty ||
//                           selectedDoctorName == null ||
//                           summaryCtrl.text.isEmpty ||
//                           taskCtrl.text.isEmpty ||
//                           selectedDate == null) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                               content: Text('Please fill all fields')),
//                         );
//                         return;
//                       }

//                       await _firestore.collection('home_visits').add({
//                         'patient': patientCtrl.text,
//                         'doctor': selectedDoctorName,
//                         'doctor_uid': selectedDoctorUid,
//                         'availability_date': selectedAvailability?['date'],
//                         'availability_start': selectedAvailability?['start'],
//                         'availability_end': selectedAvailability?['end'],
//                         'visit_date':
//                             '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
//                         'summary': summaryCtrl.text,
//                         'task': taskCtrl.text,
//                         'timestamp': Timestamp.now(),
//                       });

//                       if (context.mounted) Navigator.pop(context);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const purple = Color(0xFF7B2CBF);

//     return Scaffold(
//       appBar: const NurseAppBar(),
//       drawer: const NurseDrawer(),
//       backgroundColor: const Color(0xFFF5F5F5),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'HOME VISIT TRACKING',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     IconButton(
//                       icon:
//                           const Icon(Icons.add_circle, color: purple, size: 30),
//                       onPressed: _addRecordDialog,
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: _firestore
//                       .collection('home_visits')
//                       .orderBy('timestamp', descending: true)
//                       .snapshots(),
//                   builder: (context, snapshot) {
//                     if (!snapshot.hasData) {
//                       return const Center(child: CircularProgressIndicator());
//                     }

//                     final docs = snapshot.data!.docs;
//                     if (docs.isEmpty) {
//                       return const Center(child: Text('No records found'));
//                     }

//                     return SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: DataTable(
//                         headingRowColor:
//                             MaterialStatePropertyAll(Colors.grey.shade800),
//                         headingTextStyle: const TextStyle(
//                             color: Colors.white, fontWeight: FontWeight.bold),
//                         columns: const [
//                           DataColumn(label: Text('Patient')),
//                           DataColumn(label: Text('Doctor')),
//                           DataColumn(label: Text('Date')),
//                           DataColumn(label: Text('Summary')),
//                           DataColumn(label: Text('Task')),
//                         ],
//                         rows: docs.map((d) {
//                           final data = d.data() as Map<String, dynamic>;
//                           return DataRow(cells: [
//                             DataCell(Text(data['patient'] ?? '')),
//                             DataCell(Text(data['doctor'] ?? '')),
//                             DataCell(Text(data['visit_date'] ?? '')),
//                             DataCell(Text(data['summary'] ?? '')),
//                             DataCell(Text(data['task'] ?? '')),
//                           ]);
//                         }).toList(),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
