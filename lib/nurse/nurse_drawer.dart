import 'package:flutter/material.dart';
import 'package:hospitalmanagementsystem/nurse/nurse_home.dart';
import 'home_visit_tracking.dart';
import 'refer_letter_generator.dart';
import 'appointment_scheduling.dart';
import 'maternal_child_care.dart';
import 'patient_health_tracking.dart';
import 'reminder.dart';

class NurseDrawer extends StatelessWidget {
  const NurseDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      child: Container(
        color: const Color(0xFF7B2CBF),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF7B2CBF)),
              child: Center(
                child: Text(
                  'DASHBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _drawerButton(context, 'HOME', const NurseHome()),
            _drawerButton(
                context, 'HOME VISIT TRACKING', const HomeVisitTrackingPage()),
            _drawerButton(context, 'REFER LETTER GENERATOR',
                const ReferLetterGeneratorPage()),
            _drawerButton(context, 'APPOINTMENT SCHEDULING',
                const AppointmentSchedulingPage()),
            _drawerButton(context, 'MATERNAL AND CHILD CARE',
                const MaternalChildCarePage()),
            _drawerButton(context, 'PATIENT HEALTH TRACKING',
                const PatientHealthTrackingPage()),
            _drawerButton(context, 'REMINDER', const ReminderPage()),
          ],
        ),
      ),
    );
  }

  Widget _drawerButton(BuildContext context, String text, Widget destination) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          minimumSize: const Size.fromHeight(45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
