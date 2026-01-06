import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospitalmanagementsystem/admin/admin.dart';
import 'package:hospitalmanagementsystem/doctor/doctor_home.dart';
import 'package:hospitalmanagementsystem/nurse/dash.dart';
import 'package:hospitalmanagementsystem/nurse/nurse_home1.dart';
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
  bool _rememberMe = false;
  bool _loading = false;

  static const Color darkPurple = Color(0xFF703370); 
  static const Color accentPink = Color(0xFFC576C5);

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
     
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
        }
      } else {
        final role = doc['role']; 
        if (mounted) {
          switch (role) {
            case 'admin':
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
              break;
            case 'nurse':
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NurseDash()));
              break;
            case 'pharmacann':
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacannHome()));
              break;
            case 'doctor':
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorHome()));
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unknown role')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, 
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'CLINIC INFORMATION SYSTEM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B3D2F),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: _buildIllustration()),
                          const SizedBox(width: 40),
                          _buildLoginCard(),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildIllustration(),
                          const SizedBox(height: 20),
                          _buildLoginCard(),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Image.asset(
        'assets/health_login.png', 
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: darkPurple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("Email"),
          _Field(controller: _email, hint: 'Email', icon: Icons.email_outlined),
          const SizedBox(height: 20),
          _label("Password"),
          _Field(controller: _password, hint: 'Password', icon: Icons.lock_outline, obscure: true),
          
          const SizedBox(height: 10),
          
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Theme(
                  data: ThemeData(unselectedWidgetColor: Colors.white),
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: accentPink,
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    onChanged: (val) => setState(() => _rememberMe = val!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Remember Me",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          
          _loading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _login, 
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'LOG IN',
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  const _Field({required this.controller, required this.hint, required this.icon, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}