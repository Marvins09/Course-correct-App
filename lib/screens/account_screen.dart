import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        if (mounted) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _deleteAccount() async {
    if (_user != null) {
      try {
        await _firestore.collection('users').doc(_user!.uid).delete();
        await _user!.delete();
        await AuthService().signOut();
        if (mounted) {
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting account: ${e.toString()}")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        backgroundColor: Colors.teal[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  _userData?['profilePic'] != null
                      ? NetworkImage(_userData!['profilePic'])
                      : null,
              child:
                  _userData?['profilePic'] == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
            ),
            const SizedBox(height: 20),
            if (_userData != null) ...[
              Text(
                _userData!['fullName'] ?? 'Not set',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _userData!['email'] ?? 'Not set',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildInfoCard(Icons.phone, _userData!['phone'] ?? 'Not set'),
              _buildInfoCard(Icons.person, _userData!['gender'] ?? 'Not set'),
              _buildInfoCard(
                Icons.location_on,
                _userData!['country'] ?? 'Not set',
              ),
              const SizedBox(height: 30),
            ] else ...[
              const Center(child: CircularProgressIndicator()),
            ],
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[900],
              ),
              child: const Text("Logout"),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                ),
                child: const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String info) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal[900]),
        title: Text(info),
      ),
    );
  }
}
