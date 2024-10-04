import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderScreen extends StatefulWidget {
  final String folderId;

  const FolderScreen({super.key, required this.folderId});

  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  bool _isUploading = false;
  double _downloadProgress = 0.0; // State variable for download progress

  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? '';
  }

  Future<void> _uploadFile() async {
    setState(() {
      _isUploading = true; // Set loading state to true
    });

    final userEmail = await _getUserEmail();
    final result = await FilePicker.platform.pickFiles();
    if (result == null) {
      setState(() {
        _isUploading = false; // Reset loading state
      });
      return;
    }

    final file = result.files.single;
    final filePath = file.path;
    final fileName = file.name;

    if (filePath != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$userEmail/folders/${widget.folderId}/$fileName');
      await ref.putFile(File(filePath));
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('folders')
          .doc(widget.folderId)
          .collection('files')
          .add({
        'name': fileName,
        'url': await ref.getDownloadURL(),
        'type': path.extension(fileName).toLowerCase(),
      });
    }

    setState(() {
      _isUploading = false; // Reset loading state after upload
    });
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image;
      case '.mp4':
      case '.mov':
        return Icons.video_library;
      case '.mp3':
        return Icons.music_note;
      default:
        return Icons.file_copy;
    }
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (status.isGranted) {
        // Get the path to the external storage directory
        final externalStorageDir = await getExternalStorageDirectory();

        // Define the specific folder path
        final specificFolder =
            Directory('${externalStorageDir!.parent.path}/FireStreamDownload');

        // Create the folder if it doesn't exist
        if (!(await specificFolder.exists())) {
          await specificFolder.create(recursive: true);
        }

        // Set the file path for the downloaded file
        final filePath = '${specificFolder.path}/$fileName';

        // Create Dio instance
        final dio = Dio();

        // Show the dialog before starting the download
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Downloading"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: _downloadProgress),
                  const SizedBox(height: 10),
                  Text('${(_downloadProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    dio.close(); // Cancel the download if needed
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );

        // Download the file
        await dio.download(
          fileUrl,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _downloadProgress = received / total; // Update progress
              });
              print(
                  'Download Progress: ${(_downloadProgress * 100).toStringAsFixed(0)}%');
            }
          },
        );

        // Close the dialog after the download is complete
        Navigator.of(context).pop();

        // Notify the user that the file has been downloaded
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("File downloaded to '$filePath' successfully."),
            duration: const Duration(seconds: 5),
          ),
        );

        print('File downloaded to: $filePath');

        // Open the file after downloading
        final result = await OpenFile.open(filePath);
        print('File open result: ${result.message}');
      } else {
        print('Storage permission denied!');
      }
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    } finally {
      setState(() {
        _downloadProgress = 0.0; // Reset progress
      });
    }
  }

  Future<void> _deleteFile(String fileId, String fileUrl) async {
    try {
      final userEmail = await _getUserEmail();

      // Delete file from Firebase Storage
      final ref = FirebaseStorage.instance.refFromURL(fileUrl);
      await ref.delete();

      // Delete file document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('folders')
          .doc(widget.folderId)
          .collection('files')
          .doc(fileId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder'),
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
                .doc(widget.folderId)
                .collection('files')
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
                    child: Text('No files available.',
                        style: TextStyle(fontSize: 18, color: Colors.grey)));
              }

              final files = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      leading: Icon(
                        _getFileIcon(file['type']),
                        size: 40,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        file['name'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.download, color: Colors.green),
                            onPressed: () {
                              // Show a dialog to display the progress
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Downloading"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LinearProgressIndicator(
                                          value: _downloadProgress),
                                      SizedBox(height: 10),
                                      Text(
                                          '${(_downloadProgress * 100).toStringAsFixed(0)}%'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );

                              _downloadFile(file['url'], file['name']);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteFile(file.id, file['url']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFile,
        backgroundColor: Colors.blueAccent,
        child: _isUploading
            ? const CircularProgressIndicator(
                color: Colors.white) // Show loading indicator
            : const Icon(Icons.upload_file, size: 30),
      ),
    );
  }
}
