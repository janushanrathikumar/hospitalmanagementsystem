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
  final Color purpleTheme = const Color(0xFF4A3469);

  // --- UI REDESIGN HELPERS ---
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            color: purpleTheme,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1),
      ),
    );
  }

  // --- BOOKING DIALOG ---
  Future<void> _addRecordDialog() async {
    final icCtrl = TextEditingController();
    final taskCtrl = TextEditingController();

    String? selectedDoctorUid;
    String? selectedDoctorName;
    List<Map<String, dynamic>> doctorAvailabilities = [];
    Map<String, dynamic>? selectedAvailability;
    String? selectedSlot;

    String? patientName;
    String? address;
    String? age;
    String? mobile;
    List<Map<String, dynamic>> icSuggestions = [];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(30),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_available, color: purpleTheme, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'New Appointment',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // 1. Patient Search Section
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
                        final querySnap = await _firestore
                            .collection('patients')
                            .where('ic_number', isGreaterThanOrEqualTo: val)
                            .where('ic_number',
                                isLessThanOrEqualTo: '$val\uf8ff')
                            .limit(5)
                            .get();

                        setDialogState(() {
                          
                          icSuggestions = querySnap.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return {...data, 'id': doc.id};
                          }).toList();
                        });
                      } else {
                        setDialogState(() => icSuggestions = []);
                      }
                    },
                  ),

                  if (icSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: Column(
                        children: icSuggestions
                            .map((p) => ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(p['name'] ?? ''),
                                  subtitle: Text(p['ic_number'] ?? ''),
                                  onTap: () {
                                    setDialogState(() {
                                      icCtrl.text = p['ic_number'];
                                      patientName = p['name'];
                                      address = p['address'];
                                      age = p['age'];
                                      mobile = p['mobile'];
                                      icSuggestions = [];
                                    });
                                  },
                                ))
                            .toList(),
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
                              "Selected: $patientName ($age yrs)\n$address",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 2. Doctor Selection
                  _buildSectionLabel("Doctor Selection"),
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore.collection('doctor_availability').get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator();

                      final doctors = <String, String>{};
                      for (var doc in snapshot.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        doctors[d['uid']] = d['user_name'];
                      }

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'Choose a Doctor',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        items: doctors.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedDoctorUid = val;
                            selectedDoctorName = doctors[val];
                            selectedAvailability = null;
                            selectedSlot = null;
                           
                            doctorAvailabilities = snapshot.data!.docs
                                .where((d) => (d.data() as Map)['uid'] == val)
                                .map((d) => Map<String, dynamic>.from(
                                    {...d.data() as Map, 'id': d.id}))
                                .toList();
                          });
                        },
                      );
                    },
                  ),

                  if (doctorAvailabilities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionLabel("Available Dates"),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: doctorAvailabilities.map((avail) {
                          final isSelected = selectedAvailability == avail;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(avail['date'] ?? ''),
                              selected: isSelected,
                              selectedColor: purpleTheme.withOpacity(0.2),
                              onSelected: (s) {
                                setDialogState(() {
                                  selectedAvailability = avail;
                                  selectedSlot = null;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  if (selectedAvailability != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionLabel("Select Time Slot"),
                    Wrap(
                      spacing: 8,
                      children: _generateTimeSlots(
                        selectedAvailability!['start'],
                        selectedAvailability!['end'],
                        (selectedAvailability!['booked_slots'] as List?) ?? [],
                      )
                          .map((slot) => ChoiceChip(
                                label: Text(slot),
                                selected: selectedSlot == slot,
                                onSelected: (s) =>
                                    setDialogState(() => selectedSlot = slot),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _buildSectionLabel("Purpose of Visit"),
                  TextField(
                    controller: taskCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g., General Checkup, Diabetes',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purpleTheme,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (patientName == null ||
                          selectedSlot == null ||
                          taskCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please complete all selections')),
                        );
                        return;
                      }

                      final availId = selectedAvailability!['id'];

                      await _firestore.collection('appointments').add({
                        'ic_number': icCtrl.text,
                        'name': patientName,
                        'address': address,
                        'age': age,
                        'mobile': mobile,
                        'doctor': selectedDoctorName,
                        'doctor_uid': selectedDoctorUid,
                        'availability_id': availId,
                        'availability_date': selectedAvailability!['date'],
                        'slot_time': selectedSlot,
                        'task': taskCtrl.text,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      await _firestore
                          .collection('doctor_availability')
                          .doc(availId)
                          .update({
                        'booked_slots': FieldValue.arrayUnion([selectedSlot]),
                      });

                      Navigator.pop(context);
                    },
                    child: const Text('CONFIRM BOOKING',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 
  List<String> _generateTimeSlots(
      String start, String end, List<dynamic> booked) {
    try {
      final startParts = _parseTime(start);
      final endParts = _parseTime(end);
      TimeOfDay current =
          TimeOfDay(hour: startParts['h']!, minute: startParts['m']!);
      final endTime = TimeOfDay(hour: endParts['h']!, minute: endParts['m']!);

      final slots = <String>[];
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
    if (time.toLowerCase().contains('pm') && hour != 12) hour += 12;
    if (time.toLowerCase().contains('am') && hour == 12) hour = 0;
    return {'h': hour, 'm': minute};
  }

  int _compareTime(TimeOfDay a, TimeOfDay b) => a.hour == b.hour
      ? a.minute.compareTo(b.minute)
      : a.hour.compareTo(b.hour);

  TimeOfDay _addMinutes(TimeOfDay time, int min) {
    int total = time.hour * 60 + time.minute + min;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NurseAppBar(),
      drawer: const NurseDrawer(),
       backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecordDialog,
        backgroundColor: purpleTheme,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Book New", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'APPOINTMENT SCHEDULING',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10)
                  ],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('appointments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty)
                      return const Center(child: Text("No records found"));

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(purpleTheme),
                        headingTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(label: Text('Patient')),
                          DataColumn(label: Text('NRIC / IC')),
                          DataColumn(label: Text('Doctor')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Slot')),
                          DataColumn(label: Text('Task')),
                        ],
                        rows: docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return DataRow(cells: [
                            DataCell(Text(data['name'] ?? '')),
                            DataCell(Text(data['ic_number'] ?? '')),
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
            ),
          ],
        ),
      ),
    );
  }
}
