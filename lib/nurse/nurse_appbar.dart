import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hospitalmanagementsystem/login.dart';

class NurseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NurseAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70); // Slightly taller for a modern look

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.black87),
      title: const Text(
        'CLINIC INFORMATION SYSTEM',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.print_outlined, color: Colors.black87),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF23262F), // Dark grey/black from image
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'LOG OUT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.withOpacity(0.2), height: 1),
      ),
    );
  }
}