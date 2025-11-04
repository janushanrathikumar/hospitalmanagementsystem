import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospitalmanagementsystem/admin/admin.dart';
import 'package:hospitalmanagementsystem/doctor/doctor_home.dart';
import 'package:hospitalmanagementsystem/nurse/nurse_home.dart';
import 'package:hospitalmanagementsystem/pharmacann/pharmacann_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = cred.user!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User not found')));
      } else {
        final role = doc['role']; // corrected key spelling
        switch (role) {
          case 'admin':
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const AdminPage()));
            break;
          case 'nurse':
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const NurseHome()));
            break;
          case 'pharmacann':
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const PharmacannHome()));
            break;
          case 'doctor':
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const DoctorHome()));
            break;
          default:
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Unknown role')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B2CBF); // card
    const purpleLight = Color(0xFFB983FF); // button

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900;

          final loginCard = Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: purple,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _Field(
                      controller: _email,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 14),
                    const Text('Password',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _Field(
                      controller: _password,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: true,
                    ),
                    const SizedBox(height: 18),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            height: 44,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: purpleLight,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'LOG IN',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     // TextButton(
                    //     //   onPressed: () {},
                    //     //   child: const Text('Forgot Password?',
                    //     //       style: TextStyle(color: Colors.white)),
                    //     // ),

                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          );

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'HEALTH INFORMATION SYSTEM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xFF10211A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Image.asset(
                                  'assets/health_login.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 420, child: loginCard),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Image.asset(
                                'assets/health_login.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            loginCard,
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        prefixIcon: Icon(icon),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
        ),
      ),
    );
  }
}
