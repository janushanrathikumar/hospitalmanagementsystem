import 'package:flutter/material.dart';
import 'package:hospitalmanagementsystem/nurse/dash.dart';
import 'package:hospitalmanagementsystem/nurse/nurse_home1.dart';
import 'home_visit_tracking.dart';
import 'refer_letter_generator.dart';
import 'appointment_scheduling.dart';
import 'maternal_child_care.dart';
import 'reminder.dart';
import 'report.dart';

class NurseDrawer extends StatelessWidget {
  const NurseDrawer({super.key});

  @override
  Widget build(BuildContext context) {
   
    const Color sidebarColor = Color(0xFF4A3469);

    return Drawer(
      backgroundColor: sidebarColor,
      child: Column(
        children: [
        
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20),
            alignment: Alignment.center,
            child: const Text(
              'CLINIC INFORMATION SYSTEM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(color: Colors.white12, indent: 20, endIndent: 20),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _navItem(
                    context, Icons.home_outlined, 'HOME', const NurseDash()),
                _navItem(context, Icons.location_on_outlined,
                    'HOME VISIT TRACKING', const HomeVisitTrackingPage()),
                _navItem(context, Icons.description_outlined,
                    'REFER LETTER GENERATOR', const ReferLetterGeneratorPage()),
                _navItem(
                    context,
                    Icons.calendar_today_outlined,
                    'APPOINTMENT SCHEDULING',
                    const AppointmentSchedulingPage()),
                _navItem(context, Icons.child_care_outlined,
                    'MATERNAL AND CHILD CARE', const MaternalChildCarePage()),

               
                _navItem(context, Icons.people_outline, 'PATIENT DETAILS',
                    const NurseHome1()),

                _navItem(context, Icons.notifications_none_outlined, 'REMINDER',
                    const ReminderPage()),
                _navItem(context, Icons.assessment_outlined, 'REPORT',
                    const ClinicReportPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context, IconData icon, String title, Widget destination) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
    );
  }

 
  Widget _navActiveItem(
      BuildContext context, IconData icon, String title, Widget destination) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => destination));
        },
      ),
    );
  }
}
