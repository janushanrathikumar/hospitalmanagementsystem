import 'package:flutter/material.dart';

class PharmacannHome extends StatelessWidget {
  const PharmacannHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacann Home')),
      body: const Center(child: Text('Welcome, Pharmacann')),
    );
  }
}
