import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firestream/features/authentication/screens/reset_password_screen.dart';
import 'package:firestream/features/authentication/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _photoURL;
  late String _username;
  late String _email;
  final _usernameController = TextEditingController();
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;

    if (user != null) {
      setState(() {
        _photoURL = prefs.getString('userPhoto') ?? '';
        _username = prefs.getString('userName') ?? '';
        _email = prefs.getString('userEmail') ?? '';
        _usernameController.text = _username;
        _isLoading = false; // Set loading to false after loading data
      });
    }
  }

  // Update username in Firestore and SharedPreferences
  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_email)
        .update({'username': newUsername});

    await prefs.setString('userName', newUsername);

    setState(() {
      _username = newUsername;
    });
  }

  Future<void> _updateProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true; // Set loading to true while uploading
      });

      final prefs = await SharedPreferences.getInstance();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${"$_email profile_pic"}.jpg');

      await storageRef.putFile(File(pickedFile.path));

      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_email)
          .update({'profilePic': downloadUrl});

      await prefs.setString('userPhoto', downloadUrl);

      setState(() {
        _photoURL = downloadUrl; // Use the download URL
        _isLoading = false; // Set loading to false after upload
      });
    }
  }

  Future<void> _updatePassword() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear shared preferences
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoading
                    ? const CircularProgressIndicator() // Show loading indicator if loading
                    : CircleAvatar(
                        backgroundImage: NetworkImage(_photoURL),
                        radius: 40, // Adjust the radius as needed
                      ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _updateProfilePic(); // Call the updated function for profile pic upload
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              _email,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Edit Username'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Edit Username'),
                          content: TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'New Username',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                _updateUsername();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Update'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Edit Password'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _updatePassword();
                    },
                  ),
                  ListTile(
                    title: const Text('Logout'),
                    trailing: const Icon(Icons.logout),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
