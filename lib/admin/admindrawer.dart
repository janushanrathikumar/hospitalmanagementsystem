// import 'package:flutter/material.dart';
// import 'admin.dart';
// import 'add_nurse.dart';
// import 'appointment.dart';

// class AdminDrawer extends StatelessWidget {
//   const AdminDrawer({super.key});

//   Widget _drawerItem({
//     required BuildContext context,
//     required IconData icon,
//     required String label,
//     required Widget page,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.red[700]),
//       title: Text(
//         label,
//         style: const TextStyle(fontSize: 15, color: Colors.black87),
//       ),
//       onTap: () {
//         Navigator.pop(context);
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => page),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: Container(
//         color: Colors.white,
//         child: SafeArea(
//           child: Column(
//             children: [
//               Container(
//                 width: double.infinity,
//                 color: Colors.red[800],
//                 padding: const EdgeInsets.symmetric(vertical: 24),
//                 child: const Column(
//                   children: [
//                     Icon(Icons.admin_panel_settings,
//                         size: 60, color: Colors.white),
//                     SizedBox(height: 8),
//                     Text(
//                       'Hospital Admin Panel',
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               _drawerItem(
//                 context: context,
//                 icon: Icons.home,
//                 label: 'Home',
//                 page: const AdminPage(),
//               ),
//               _drawerItem(
//                 context: context,
//                 icon: Icons.person_add,
//                 label: 'Add User',
//                 page: const AddUserPage(),
//               ),
//               _drawerItem(
//                 context: context,
//                 icon: Icons.calendar_month,
//                 label: 'View Appointments',
//                 page: const AppointmentPage(),
//               ),
//               const Spacer(),
//               const Divider(),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text(
//                   '© 2025 Hospital Management System',
//                   style: TextStyle(color: Colors.grey[600], fontSize: 11),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
