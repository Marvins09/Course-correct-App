import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart'; // ✅ Animation Package
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

  /// ✅ Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;
        });
      }
    }
  }

  /// ✅ Logout function with loading indicator (Fixed)
  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await AuthService().signOut();

    if (!mounted) return; // ✅ Prevents using context after async

    Navigator.pushReplacementNamed(context, '/login');
  }

  /// ✅ Confirm account deletion
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder:
          (context) => FadeIn(
            child: AlertDialog(
              title: const Text("Delete Account"),
              content: const Text(
                "Are you sure you want to delete your account? This action cannot be undone.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteAccount();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Delete"),
                ),
              ],
            ),
          ),
    );
  }

  /// ✅ Delete account with loading animation (Fixed)
  Future<void> _deleteAccount() async {
    if (_user != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await _firestore.collection('users').doc(_user!.uid).delete();
        await _user!.delete();
        await AuthService().signOut();

        if (!mounted) return; // ✅ Prevents crash if screen was removed

        Navigator.pushReplacementNamed(context, '/login');
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
        title: const Text("My Account"),
        backgroundColor: Colors.teal[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FadeInDown(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    _userData?['profile_picture'] != null &&
                            _userData!['profile_picture'].isNotEmpty
                        ? NetworkImage(_userData!['profile_picture'])
                        : null,
                child:
                    _userData?['profile_picture'] == null ||
                            _userData!['profile_picture'].isEmpty
                        ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 20),
            if (_userData != null) ...[
              FadeInUp(
                child: Column(
                  children: [
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
                  ],
                ),
              ),
              _buildInfoCard(
                Icons.phone,
                "Phone",
                _userData!['phone'] ?? 'Not set',
              ),
              _buildInfoCard(
                Icons.person,
                "Gender",
                _userData!['gender'] ?? 'Not set',
              ),
              _buildInfoCard(
                Icons.location_on,
                "Country",
                _userData!['country'] ?? 'Not set',
              ),
              _buildInfoCard(
                Icons.access_time,
                "Last Active",
                _userData?['last_active'] != null
                    ? (_userData!['last_active'] as Timestamp)
                        .toDate()
                        .toLocal()
                        .toString()
                    : 'Unknown',
              ),
              const SizedBox(height: 30),
            ] else ...[
              const Center(child: CircularProgressIndicator()),
            ],
            BounceInDown(
              child: ElevatedButton(
                onPressed: _logout, // ✅ Fixed Argument Error
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[900],
                ),
                child: const Text("Logout"),
              ),
            ),
            const SizedBox(height: 20),
            BounceInUp(
              child: ElevatedButton(
                onPressed: _confirmDeleteAccount,
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

  /// ✅ **Reusable Info Card Widget**
  Widget _buildInfoCard(IconData icon, String title, String info) {
    return FadeInLeft(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Icon(icon, color: Colors.teal[900]),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(info),
        ),
      ),
    );
  }
}
