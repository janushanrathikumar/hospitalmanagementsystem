import 'package:flutter/material.dart';
import 'package:hospitalmanagementsystem/admin/adminappbar.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const AdminAppBar(),
      drawer: const AdminDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B2CBF),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _InfoCard(
                        icon: Icons.people_alt_outlined,
                        label: 'Total Users',
                        value: '32'),
                    _InfoCard(
                        icon: Icons.local_hospital_outlined,
                        label: 'Doctors',
                        value: '8'),
                    _InfoCard(
                        icon: Icons.medication_outlined,
                        label: 'Pharmacists',
                        value: '5'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: Text(
                  'Admin Dashboard Overview',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7B2CBF), size: 40),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
