import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_appbar.dart';
import 'doctor_drawer.dart';

class DoctorAvailableDate extends StatefulWidget {
  const DoctorAvailableDate({super.key});

  @override
  State<DoctorAvailableDate> createState() => _DoctorAvailableDateState();
}

class _DoctorAvailableDateState extends State<DoctorAvailableDate> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _uid;
  String? _userName;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _uid = user.uid;

    final doc = await _firestore.collection('users').doc(_uid).get();
    if (doc.exists) {
      setState(() => _userName = doc['user_name'] ?? 'Doctor');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  List<DropdownMenuItem<TimeOfDay>> _timeOptions() {
    final items = <DropdownMenuItem<TimeOfDay>>[];
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += 30) {
        items.add(DropdownMenuItem(
          value: TimeOfDay(hour: h, minute: m),
          child: Text(
              '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'),
        ));
      }
    }
    return items;
  }

  Future<void> _saveAvailability() async {
    if (_uid == null ||
        _selectedDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() => _loading = true);

    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    await _firestore.collection('doctor_availability').add({
      'uid': _uid,
      'user_name': _userName ?? 'Doctor',
      'date': dateStr,
      'start': _startTime!.format(context),
      'end': _endTime!.format(context),
      'timestamp': Timestamp.now(),
    });

    setState(() {
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
      _loading = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Availability saved')));
  }

  void _editAvailability(String id, Map<String, dynamic> data) {
    DateTime? editDate = DateTime.tryParse(data['date']);
    TimeOfDay? editStart = _parseTime(data['start']);
    TimeOfDay? editEnd = _parseTime(data['end']);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Availability',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  editDate == null
                      ? 'Select Date'
                      : '${editDate!.year}-${editDate!.month.toString().padLeft(2, '0')}-${editDate!.day.toString().padLeft(2, '0')}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: editDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => editDate = picked);
                },
              ),
              DropdownButtonFormField<TimeOfDay>(
                value: editStart,
                decoration: const InputDecoration(labelText: 'Start Time'),
                items: _timeOptions(),
                onChanged: (v) => setState(() => editStart = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<TimeOfDay>(
                value: editEnd,
                decoration: const InputDecoration(labelText: 'End Time'),
                items: _timeOptions(),
                onChanged: (v) => setState(() => editEnd = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2CBF)),
                onPressed: () async {
                  if (editDate == null ||
                      editStart == null ||
                      editEnd == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please complete fields')));
                    return;
                  }

                  await _firestore
                      .collection('doctor_availability')
                      .doc(id)
                      .update({
                    'date':
                        '${editDate!.year}-${editDate!.month.toString().padLeft(2, '0')}-${editDate!.day.toString().padLeft(2, '0')}',
                    'start': editStart!.format(context),
                    'end': editEnd!.format(context),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    int h = int.parse(parts[0]);
    int m = int.parse(parts[1].split(' ')[0]);
    bool pm = t.toLowerCase().contains('pm');
    if (pm && h != 12) h += 12;
    if (!pm && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B2CBF);

    return Scaffold(
      appBar: const DoctorAppBar(),
      drawer: const DoctorDrawer(),
      backgroundColor: const Color(0xFFF6F6F6),
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doctor Availability',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: purple)),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add availability form
                        Expanded(
                          flex: wide ? 1 : 0,
                          child: Container(
                            width: wide ? null : 420,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10)
                              ],
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Select Date',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: _pickDate,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: _selectedDate == null
                                        ? ''
                                        : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<TimeOfDay>(
                                  value: _startTime,
                                  decoration: const InputDecoration(
                                      labelText: 'Start Time',
                                      border: OutlineInputBorder()),
                                  items: _timeOptions(),
                                  onChanged: (v) =>
                                      setState(() => _startTime = v),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<TimeOfDay>(
                                  value: _endTime,
                                  decoration: const InputDecoration(
                                      labelText: 'End Time',
                                      border: OutlineInputBorder()),
                                  items: _timeOptions(),
                                  onChanged: (v) =>
                                      setState(() => _endTime = v),
                                ),
                                const SizedBox(height: 20),
                                _loading
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 68, 52, 82),
                                            minimumSize: const Size(
                                                double.infinity, 45)),
                                        onPressed: _saveAvailability,
                                        icon: const Icon(Icons.save),
                                        label: const Text('Save Availability')),
                              ],
                            ),
                          ),
                        ),
                        if (wide) const SizedBox(width: 32),

                        // Data table
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10)
                              ],
                            ),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('doctor_availability')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                // 🔍 Client-side filter for current UID
                                final docs = snapshot.data!.docs.where((d) {
                                  final data = d.data() as Map<String, dynamic>;
                                  return data['uid'] == _uid;
                                }).toList();

                                if (docs.isEmpty) {
                                  return const Text(
                                      'No availability records found.');
                                }

                                return DataTable(
                                  headingRowColor: MaterialStatePropertyAll(
                                      purple.withOpacity(0.1)),
                                  columns: const [
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Start')),
                                    DataColumn(label: Text('End')),
                                    DataColumn(label: Text('Edit')),
                                  ],
                                  rows: docs.map((d) {
                                    final data =
                                        d.data() as Map<String, dynamic>;
                                    return DataRow(cells: [
                                      DataCell(Text(data['date'] ?? '')),
                                      DataCell(Text(data['start'] ?? '')),
                                      DataCell(Text(data['end'] ?? '')),
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: purple),
                                        onPressed: () =>
                                            _editAvailability(d.id, data),
                                      )),
                                    ]);
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
