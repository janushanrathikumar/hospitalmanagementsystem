import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adminappbar.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();

  String _selectedRole = 'nurse';
  bool _loading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'user_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'role': _selectedRole,
        'uid': cred.user!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User registered successfully')),
      );

      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _addressController.clear();
      _mobileController.clear();
      setState(() => _selectedRole = 'nurse');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('User updated')));
  }

  Future<void> _deleteUser(String uid, String email) async {
    await _firestore.collection('users').doc(uid).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Deleted $email')));
  }

  void _showEditDialog(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['user_name']);
    final addrCtrl = TextEditingController(text: user['address']);
    final mobCtrl = TextEditingController(text: user['mobile']);
    String role = user['role'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Address')),
              TextField(
                  controller: mobCtrl,
                  decoration: const InputDecoration(labelText: 'Mobile')),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                ],
                onChanged: (val) => role = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2CBF)),
            onPressed: () {
              Navigator.pop(context);
              _updateUser(user['uid'], {
                'user_name': nameCtrl.text.trim(),
                'address': addrCtrl.text.trim(),
                'mobile': mobCtrl.text.trim(),
                'role': role,
              });
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B2CBF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const AdminAppBar(),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add or Manage Users',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: purple,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter address' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter mobile' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                        DropdownMenuItem(
                            value: 'pharmacann', child: Text('Pharmacann')),
                        DropdownMenuItem(
                            value: 'doctor', child: Text('Doctor')),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 20),
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _registerUser,
                            icon: const Icon(Icons.person_add),
                            label: const Text(
                              'Register User',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Registered Users',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: purple),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snap.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading:
                            const Icon(Icons.person, color: Color(0xFF7B2CBF)),
                        title: Text(
                            '${user['user_name']} (${user['role'] ?? ''})'),
                        subtitle: Text('${user['email']}\n${user['mobile']}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteUser(user['uid'], user['email']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
