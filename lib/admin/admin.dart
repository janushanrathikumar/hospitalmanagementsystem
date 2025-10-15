import 'package:flutter/material.dart';
import 'package:hospitalmanagementsystem/admin/admindrawer.dart';
import 'adminappbar.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AdminAppBar(),
      drawer: AdminDrawer(),
      body: Center(
        child: Text(
          'Welcome to Admin Dashboard',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
