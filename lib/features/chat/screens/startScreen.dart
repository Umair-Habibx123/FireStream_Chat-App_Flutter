import 'package:firestream/features/chat/screens/ChatListScreen.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

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
              const Text.rich(
                TextSpan(
                  text: 'Enjoy Your Communication\nWith ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Chatee',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // 'Chatee' bubbles scattered
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 10.0, // Space between bubbles
                    runSpacing: 10.0, // Space between lines of bubbles
                    children: List.generate(12, (index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 20.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        child: Text(
                          'Chatee',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
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
                    // Add button functionality here
                    Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const ChatListScreen()),
                  );
                  },
                  child: const Text(
                    "Let's Started",
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
