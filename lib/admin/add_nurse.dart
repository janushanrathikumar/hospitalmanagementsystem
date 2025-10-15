import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adminappbar.dart';
import 'admindrawer.dart';

class AddNursePage extends StatefulWidget {
  const AddNursePage({super.key});

  @override
  State<AddNursePage> createState() => _AddNursePageState();
}

class _AddNursePageState extends State<AddNursePage> {
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

  // Register a new user
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // Create user in Authentication
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = cred.user!.uid;

      // Add user details to Firestore
      await _firestore.collection('users').doc(uid).set({
        'user_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'roll': _selectedRole,
        'uid': uid,
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
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // Update Firestore user data
  Future<void> _updateUser(String uid, Map<String, dynamic> newData) async {
    await _firestore.collection('users').doc(uid).update(newData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User updated successfully')),
    );
  }

  // Delete Firestore record and (optionally) auth user
  Future<void> _deleteUser(String uid, String email) async {
    await _firestore.collection('users').doc(uid).delete();

    // ⚠️ Note: You cannot delete another user’s Auth account directly from client-side.
    // To delete from Authentication as well, you must call a Cloud Function with Admin privileges.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted $email from Firestore')),
    );
  }

  // Show edit dialog
  void _showEditDialog(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['user_name']);
    final addrCtrl = TextEditingController(text: user['address']);
    final mobCtrl = TextEditingController(text: user['mobile']);
    String role = user['roll'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: mobCtrl,
                decoration: const InputDecoration(labelText: 'Mobile'),
              ),
              DropdownButtonFormField<String>(
                value: role,
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
            onPressed: () {
              Navigator.pop(context);
              _updateUser(user['uid'], {
                'user_name': nameCtrl.text.trim(),
                'address': addrCtrl.text.trim(),
                'mobile': mobCtrl.text.trim(),
                'roll': role,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Form section
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'Register Nurse/Admin',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter email' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.length < 6 ? 'Minimum 6 characters' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter address' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter mobile number' : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 25),
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[800],
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _registerUser,
                            icon: const Icon(Icons.person_add),
                            label: const Text(
                              'Register',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            // User List
            const Text(
              'Registered Users',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final users = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.red),
                        title: Text('${user['user_name']} (${user['roll']})'),
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
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
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
