import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'admin/admin.dart';
import 'doctor/doctor_home.dart';
import 'nurse/nurse_home.dart';
import 'pharmacann/pharmacann_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hospital Management System',
      home: const AuthGate(),
    );
  }
}

/// Checks if user already logged in and directs accordingly
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getStartPage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPage();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return const LoginPage();

    final role = doc['role'];
    switch (role) {
      case 'admin':
        return const AdminPage();
      case 'nurse':
        return const NurseHome();
      case 'doctor':
        return const DoctorHome();
      case 'pharmacann':
        return const PharmacannHome();
      default:
        return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getStartPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error loading app')),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
