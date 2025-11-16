import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Reminders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('availability_date', isEqualTo: today)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No appointments for today'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    data['patient'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Doctor: ${data['doctor']}'),
                      Text('Time: ${data['slot_time']}'),
                      Text('Task: ${data['task']}'),
                    ],
                  ),
                  leading: const Icon(Icons.notifications_active,
                      color: Colors.deepPurple),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
