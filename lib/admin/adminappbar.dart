import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hospitalmanagementsystem/admin/add_user.dart';
import 'admin.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF7B2CBF),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        'ADMIN DASHBOARD',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7B2CBF),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('LOG OUT'),
          ),
        ),
      ],
    );
  }
}

// Drawer widget
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF7B2CBF),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF7B2CBF)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Admin Menu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text('Admin Home',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.white),
              title:
                  const Text('Add User', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUserPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
