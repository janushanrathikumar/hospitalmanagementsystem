import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../nurse/nurse_appbar.dart';
import '../nurse/nurse_drawer.dart';

class AppointmentSchedulingPage extends StatefulWidget {
  const AppointmentSchedulingPage({super.key});

  @override
  State<AppointmentSchedulingPage> createState() =>
      _AppointmentSchedulingPageState();
}

class _AppointmentSchedulingPageState extends State<AppointmentSchedulingPage> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _addRecordDialog() async {
    final icCtrl = TextEditingController();
    final taskCtrl = TextEditingController();

    String? selectedDoctorUid;
    String? selectedDoctorName;
    List<Map<String, dynamic>> doctorAvailabilities = [];
    Map<String, dynamic>? selectedAvailability;
    String? selectedSlot;

    // Patient details
    String? patientName;
    String? address;
    String? age;
    String? mobile;
    List<String> icSuggestions = [];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // IC Input
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
                                      patientName = data['name'];
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

                  if (patientName != null)
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
                          Text('Name: $patientName'),
                          Text('Address: $address'),
                          Text('Age: $age'),
                          Text('Mobile: $mobile'),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Doctor dropdown
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore.collection('doctor_availability').get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final doctorMap = <String, String>{};
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        doctorMap[data['uid']] = data['user_name'];
                      }
                      final doctorList = doctorMap.entries
                          .map((e) => {'uid': e.key, 'user_name': e.value})
                          .toList();

                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Doctor',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: selectedDoctorUid,
                        items: doctorList
                            .map<DropdownMenuItem<String>>(
                                (d) => DropdownMenuItem<String>(
                                      value: d['uid'] as String,
                                      child: Text(d['user_name'] as String),
                                    ))
                            .toList(),
                        onChanged: (val) async {
                          selectedDoctorUid = val;
                          selectedDoctorName = doctorList
                              .firstWhere((e) => e['uid'] == val)['user_name'];

                          // Filter availability
                          final allDocs = snapshot.data!.docs;
                          doctorAvailabilities.clear();
                          for (var d in allDocs) {
                            final data = d.data() as Map<String, dynamic>;
                            if (data['uid'] == val) {
                              doctorAvailabilities.add({
                                ...data,
                                'id': d.id,
                              });
                            }
                          }
                          doctorAvailabilities.sort((a, b) {
                            final t1 = a['timestamp'] as Timestamp?;
                            final t2 = b['timestamp'] as Timestamp?;
                            return (t2?.compareTo(t1 ?? Timestamp.now()) ?? 0);
                          });

                          selectedAvailability = null;
                          selectedSlot = null;
                          setState(() {});
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  if (doctorAvailabilities.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Doctor Availability:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: doctorAvailabilities.length,
                          itemBuilder: (context, index) {
                            final avail = doctorAvailabilities[index];
                            final isSelected = selectedAvailability == avail;

                            return InkWell(
                              onTap: () {
                                selectedAvailability = avail;
                                selectedSlot = null;
                                setState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.purple.shade50
                                      : Colors.white,
                                  border: Border.all(
                                      color: isSelected
                                          ? Colors.purple
                                          : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Date: ${avail['date']}'),
                                    Text(
                                        'Time: ${avail['start']} - ${avail['end']}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  if (selectedAvailability != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available 30-min Slots:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _generateTimeSlots(
                            selectedAvailability!['start'],
                            selectedAvailability!['end'],
                            (selectedAvailability!['booked_slots'] as List?) ??
                                [],
                          )
                              .map((slot) => ChoiceChip(
                                    label: Text(slot),
                                    selected: selectedSlot == slot,
                                    selectedColor: Colors.purple.shade300,
                                    onSelected: (_) {
                                      selectedSlot = slot;
                                      setState(() {});
                                    },
                                  ))
                              .toList(),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: taskCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Task / Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Book Appointment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B2CBF),
                      minimumSize: const Size.fromHeight(45),
                      foregroundColor: Colors.white,    
                     
                    ),
                    onPressed: () async {
                      if (icCtrl.text.isEmpty ||
                          selectedDoctorName == null ||
                          selectedAvailability == null ||
                          selectedSlot == null ||
                          taskCtrl.text.isEmpty ||
                          patientName == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please fill all fields and select a slot')),
                        );
                        return;
                      }

                      final availabilityId = selectedAvailability!['id'];
                      final bookedSlot = selectedSlot!;

                      await _firestore.collection('appointments').add({
                        'ic_number': icCtrl.text,
                        'name': patientName,
                        'address': address,
                        'age': age,
                        'mobile': mobile,
                        'doctor': selectedDoctorName,
                        'doctor_uid': selectedDoctorUid,
                        'availability_id': availabilityId,
                        'availability_date': selectedAvailability!['date'],
                        'slot_time': bookedSlot,
                        'task': taskCtrl.text,
                        'timestamp': Timestamp.now(),
                      });

                      await _firestore
                          .collection('doctor_availability')
                          .doc(availabilityId)
                          .set({
                        'booked_slots': FieldValue.arrayUnion([bookedSlot]),
                      }, SetOptions(merge: true));

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

  /// Generate 30-min slots
  List<String> _generateTimeSlots(
      String start, String end, List<dynamic> booked) {
    try {
      final startParts = _parseTime(start);
      final endParts = _parseTime(end);

      final startTime =
          TimeOfDay(hour: startParts['h']!, minute: startParts['m']!);
      final endTime = TimeOfDay(hour: endParts['h']!, minute: endParts['m']!);

      final slots = <String>[];
      TimeOfDay current = startTime;

      while (_compareTime(current, endTime) < 0) {
        final next = _addMinutes(current, 30);
        if (_compareTime(next, endTime) <= 0) {
          final slot = '${_formatTime(current)} - ${_formatTime(next)}';
          if (!booked.contains(slot)) slots.add(slot);
        }
        current = next;
      }

      return slots;
    } catch (_) {
      return [];
    }
  }

  Map<String, int> _parseTime(String time) {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1].split(' ')[0]);
    final isPM = time.toLowerCase().contains('pm');
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return {'h': hour, 'm': minute};
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    int total = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  int _compareTime(TimeOfDay a, TimeOfDay b) => a.hour == b.hour
      ? a.minute.compareTo(b.minute)
      : a.hour.compareTo(b.hour);

  String _formatTime(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
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
                  offset: const Offset(0, 5))
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
                      'APPOINTMENT SCHEDULING',
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
                  stream: _firestore
                      .collection('appointments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No appointments yet'));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStatePropertyAll(Colors.grey.shade800),
                        headingTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(label: Text('IC Number')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Address')),
                          DataColumn(label: Text('Age')),
                          DataColumn(label: Text('Mobile')),
                          DataColumn(label: Text('Doctor')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Slot')),
                          DataColumn(label: Text('Task / Notes')),
                        ],
                        rows: docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return DataRow(cells: [
                            DataCell(Text(data['ic_number'] ?? '')),
                            DataCell(Text(data['name'] ?? '')),
                            DataCell(Text(data['address'] ?? '')),
                            DataCell(Text(data['age'] ?? '')),
                            DataCell(Text(data['mobile'] ?? '')),
                            DataCell(Text(data['doctor'] ?? '')),
                            DataCell(Text(data['availability_date'] ?? '')),
                            DataCell(Text(data['slot_time'] ?? '')),
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
