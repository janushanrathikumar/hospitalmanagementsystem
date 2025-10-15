import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin.dart';
import 'add_nurse.dart';
import 'appointment.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : 'Admin';

    return AppBar(
      backgroundColor: Colors.red[800],
      iconTheme: const IconThemeData(color: Colors.white),
      title: Row(
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const Spacer(),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
