import 'package:firestream/features/chat/screens/ChatListScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validators/validators.dart';

class AddNewChatScreen extends StatefulWidget {
  const AddNewChatScreen({super.key});

  @override
  _AddNewChatScreenState createState() => _AddNewChatScreenState();
}

class _AddNewChatScreenState extends State<AddNewChatScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _searchResult = "";
  String _currentUserEmail = "";

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _emailController.addListener(_searchUser);
  }

  @override
  void dispose() {
    _emailController.removeListener(_searchUser);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('userEmail') ?? '';
    });
  }

  void _searchUser() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _searchResult = "";
      });
      return;
    }

    if (!isEmail(email)) {
      setState(() {
        _searchResult = "Invalid email format";
      });
      return;
    }

    if (email == _currentUserEmail) {
      setState(() {
        _searchResult = "You cannot chat with yourself";
      });
      return;
    }

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(email).get();

    if (userDoc.exists) {
      setState(() {
        _searchResult = "User found: ${userDoc['username']}";
      });
      // Create a chat between the current user and the found user
      String chatId = await createChat(_currentUserEmail, email);
      if (chatId.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
      } else {
        setState(() {
          _searchResult = "Failed to create chat";
        });
      }
    } else {
      setState(() {
        _searchResult = "No user found with that email";
      });
    }
  }

  Future<String> createChat(String email1, String email2) async {
    // Check for existing chat documents with the participants
    var chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContainsAny: [email1, email2]).get();

    if (chatSnapshot.docs.isEmpty) {
      // Create a new chat if no existing chat is found
      DocumentReference chatRef =
          await FirebaseFirestore.instance.collection('chats').add({
        'participants': [email1, email2],
        'lastMessage': '',
        'chatType': 'individual',
        'timestamp': FieldValue.serverTimestamp(),
        'deletedBy': [], // Initialize deletedBy as an empty list
      });
      return chatRef.id;
    } else {
      // Check if the current user has deleted the existing chat
      var existingChatDoc = chatSnapshot.docs.first;
      List<dynamic> deletedBy = existingChatDoc['deletedBy'] ?? [];

      // If only the current user has deleted the chat, allow chat recreation
      if (deletedBy.contains(_currentUserEmail) && deletedBy.length < 2) {
        // Remove the current user's email from deletedBy
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(existingChatDoc.id)
            .update({
          'deletedBy': FieldValue.arrayRemove([_currentUserEmail]),
        });
        return existingChatDoc.id; // Return the existing chat ID
      }

      // If both users have deleted the chat, allow chat recreation
      if (deletedBy.contains(_currentUserEmail) && deletedBy.length == 2) {
        // Remove the current user's email from deletedBy
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(existingChatDoc.id)
            .update({
          'deletedBy': FieldValue.arrayRemove([_currentUserEmail]),
        });
        return existingChatDoc.id; // Return the existing chat ID
      }

      // Return the existing chat ID if not deleted by the current user
      return existingChatDoc.id;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Chat"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Enter Email",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchUser,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_searchResult.isNotEmpty)
              Card(
                color: _searchResult.contains('found')
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _searchResult,
                    style: TextStyle(
                      color: _searchResult.contains('found')
                          ? Colors.green
                          : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
