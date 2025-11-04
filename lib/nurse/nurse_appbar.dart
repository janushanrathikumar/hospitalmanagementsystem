import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hospitalmanagementsystem/login.dart'; // <-- make sure this path matches your project

class NurseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NurseAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black),
      title: const Text(
        'HEALTH INFORMATION SYSTEM',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('LOG OUT'),
          ),
        ),
      ],
    );
  }
}
