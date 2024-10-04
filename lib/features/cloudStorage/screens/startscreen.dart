import 'package:firestream/features/cloudStorage/screens/home.dart';
import 'package:flutter/material.dart';

class CloudStartScreen extends StatelessWidget {
  const CloudStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Heading
              const Text(
                'Welcome to Cloud Storage!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center, // Correctly use textAlign here
              ),
              const SizedBox(height: 20),
              const Text(
                'Manage and store your files easily. Upload documents, images, videos, and more with just a few taps.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center, // Correctly use textAlign here
              ),
              const SizedBox(height: 30),
              // Cloud Storage Visual
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 60,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Upload and Manage Files',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                          textAlign: TextAlign.center, // Correctly use textAlign here
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Create folders, upload your files, and access them anytime, anywhere.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                          textAlign: TextAlign.center, // Correctly use textAlign here
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Button at the bottom
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    backgroundColor: Colors.blue, // Button color
                  ),
                  onPressed: () {
                    // Navigate to the HomeCloudScreen
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomeCloudScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
