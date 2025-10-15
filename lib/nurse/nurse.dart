import 'package:flutter/material.dart';

class NursePage extends StatelessWidget {
  const NursePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nurse Dashboard')),
      body: const Center(child: Text('Welcome, Nurse')),
    );
  }
}
