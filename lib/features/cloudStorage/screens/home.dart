import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestream/features/cloudStorage/screens/createFolderScreen.dart';
import 'package:firestream/features/cloudStorage/screens/folderScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeCloudScreen extends StatelessWidget {
  const HomeCloudScreen({super.key});

  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? '';
  }

Future<void> _deleteFolder(BuildContext context, String folderId) async {
  final userEmail = await _getUserEmail();
  // Show confirmation dialog
  final bool? confirmDelete = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
            'This folder contains items. Are you sure you want to delete it?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmDelete == true) {
    try {
      // Fetch all files in the folder
      final filesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('folders')
          .doc(folderId)
          .collection('files')
          .get();

      // Delete each file in Firebase Storage
      for (var file in filesSnapshot.docs) {
        final fileData = file.data();
        final fileUrl = fileData['url'];
        final ref = FirebaseStorage.instance.refFromURL(fileUrl);
        await ref.delete();
      }

      // Delete the 'files' sub-collection
      await _deleteCollection(
        FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('folders')
            .doc(folderId)
            .collection('files'),
      );

      // Finally, delete the folder document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('folders')
          .doc(folderId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting folder: $e')),
      );
    }
  }
}

// Helper method to delete all documents in a collection
Future<void> _deleteCollection(CollectionReference collection) async {
  final snapshot = await collection.get();
  for (var doc in snapshot.docs) {
    await doc.reference.delete(); // Delete each document
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Storage',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: FutureBuilder<String>(
        future: _getUserEmail(),
        builder: (context, emailSnapshot) {
          if (emailSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (emailSnapshot.hasError) {
            return Center(
                child: Text('Error: ${emailSnapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          final userEmail = emailSnapshot.data ?? '';

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userEmail)
                .collection('folders')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)));
              }
              if (!snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No folders available.',
                        style: TextStyle(fontSize: 18, color: Colors.grey)));
              }

              final folders = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      leading: const Icon(Icons.folder,
                          size: 40, color: Colors.blueAccent),
                      title: Text(
                        folder['name'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteFolder(context, folder.id),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FolderScreen(folderId: folder.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateFolderScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
