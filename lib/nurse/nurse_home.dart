import 'package:flutter/material.dart';
import 'nurse_appbar.dart';
import 'nurse_drawer.dart';

class NurseHome extends StatelessWidget {
  const NurseHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NurseAppBar(),
      drawer: const NurseDrawer(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar left (hidden when Drawer is used)

            const SizedBox(width: 20),

            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HEALTH INFORMATION SYSTEM',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Access vital tools for rural healthcare, manage visits, '
                    'track patient health, and streamline care coordination.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Image.asset(
                      'assets/nurse_dashboard.jpg', // replace with your image
                      fit: BoxFit.contain,
                      height: 350,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
