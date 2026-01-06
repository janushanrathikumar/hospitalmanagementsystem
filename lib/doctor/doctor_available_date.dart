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

  final Color primaryPurple = const Color(0xFF7B2CBF);
  final Color bgGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // --------------------------------------------------------
  // LOGIC METHODS (Fixes your "undefined" errors)
  // --------------------------------------------------------

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
          const SnackBar(content: Text('Please fill all fields')));
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
    DateTime? editDate = DateTime.tryParse(data['date'] ?? "");
    TimeOfDay? editStart = _parseTime(data['start']);
    TimeOfDay? editEnd = _parseTime(data['end']);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        // Added to ensure dialog updates
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Availability',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(editDate == null
                    ? "Select Date"
                    : "${editDate!.year}-${editDate!.month}-${editDate!.day}"),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final p = await showDatePicker(
                      context: context,
                      initialDate: editDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030));
                  if (p != null) setDialogState(() => editDate = p);
                },
              ),
              DropdownButtonFormField<TimeOfDay>(
                value: editStart,
                items: _timeOptions(),
                onChanged: (v) => setDialogState(() => editStart = v),
                decoration: const InputDecoration(labelText: 'Start Time'),
              ),
              DropdownButtonFormField<TimeOfDay>(
                value: editEnd,
                items: _timeOptions(),
                onChanged: (v) => setDialogState(() => editEnd = v),
                decoration: const InputDecoration(labelText: 'End Time'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await _firestore
                    .collection('doctor_availability')
                    .doc(id)
                    .update({
                  'date':
                      '${editDate!.year}-${editDate!.month.toString().padLeft(2, '0')}-${editDate!.day.toString().padLeft(2, '0')}',
                  'start': editStart!.format(context),
                  'end': editEnd!.format(context),
                });
                Navigator.pop(context);
              },
              child: const Text("Update"),
            )
          ],
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

  // --------------------------------------------------------
  // UI BUILD METHODS
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DoctorAppBar(),
      drawer: const DoctorDrawer(),
      backgroundColor: bgGrey,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 2, child: _buildAvailabilityForm()),
                              const SizedBox(width: 30),
                              Expanded(
                                  flex: 3, child: _buildAvailabilityList()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildAvailabilityForm(),
                              const SizedBox(height: 30),
                              _buildAvailabilityList(),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manage Availability',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade900)),
        const SizedBox(height: 4),
        Text('Set your working hours for patient appointments.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
      ],
    );
  }

  Widget _buildAvailabilityForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Schedule New Slot",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          _inputLabel("Working Date"),
          _buildDateTile(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _inputLabel("Start Time"),
                    _buildTimeDropdown(
                        _startTime, (v) => setState(() => _startTime = v)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _inputLabel("End Time"),
                    _buildTimeDropdown(
                        _endTime, (v) => setState(() => _endTime = v)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _saveAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3142),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Availability Slot"),
                ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityList() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Your Active Slots",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('doctor_availability')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs
                  .where((d) => (d.data() as Map)['uid'] == _uid)
                  .toList();
              if (docs.isEmpty) return _buildEmptyState();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 30),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildAvailabilityItem(docs[index].id, data);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityItem(String id, Map<String, dynamic> data) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.calendar_today_outlined,
              color: primaryPurple, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['date'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${data['start']} - ${data['end']}",
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _editAvailability(id, data),
          icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
        ),
      ],
    );
  }

  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700)),
    );
  }

  Widget _buildDateTile() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            const Icon(Icons.event, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Text(_selectedDate == null
                ? "Select working date"
                : "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}"),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDropdown(TimeOfDay? value, Function(TimeOfDay?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeOfDay>(
          value: value,
          isExpanded: true,
          items: _timeOptions(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
        child:
            Text("No slots defined yet", style: TextStyle(color: Colors.grey)));
  }
}
