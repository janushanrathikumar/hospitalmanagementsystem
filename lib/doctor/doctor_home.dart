import 'package:flutter/material.dart';
import 'doctor_appbar.dart';
import 'doctor_drawer.dart';

class DoctorHome extends StatelessWidget {
  const DoctorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DoctorAppBar(),
      drawer: const DoctorDrawer(),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Doctor!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B2CBF),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text(
                      'Your Dashboard Overview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Check your appointments, manage availability, and view patient summaries.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
