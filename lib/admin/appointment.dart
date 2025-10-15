import 'package:flutter/material.dart';
import 'package:hospitalmanagementsystem/admin/admindrawer.dart';
import 'adminappbar.dart';

class AppointmentPage extends StatelessWidget {
  const AppointmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AdminAppBar(),
      drawer: AdminDrawer(),
      body: Center(
        child: Text(
          'View Appointments Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
