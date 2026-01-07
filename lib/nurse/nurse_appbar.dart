import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hospitalmanagementsystem/login.dart';

class NurseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NurseAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

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
    // Matching the purple from your Patient Details table
    const purple = Color(0xFF7B2CBF);

    return AppBar(
      backgroundColor: purple, // Changed to purple
      elevation: 4, // Slight shadow for depth
      centerTitle: false,
      // IconTheme makes the drawer (hamburger) icon white
      iconTheme: const IconThemeData(color: Colors.white), 
      title: const Text(
        'CLINIC INFORMATION SYSTEM',
        style: TextStyle(
          color: Colors.white, // Text changed to white
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: OutlinedButton( // Changed to Outlined for a cleaner look on purple
            onPressed: () => _logout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
    );
  }
}