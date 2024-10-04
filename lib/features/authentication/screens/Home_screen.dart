import 'package:firestream/features/authentication/screens/ProfileScreen.dart';
import 'package:firestream/features/chat/screens/startScreen.dart';
import 'package:firestream/features/cloudStorage/screens/startscreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// RouteObserver to listen for navigation events
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _loadUserPhoto(); // Load the profile picture initially
  }

  // This method is called whenever the route becomes active again (e.g., after navigating back)
  @override
  void didPopNext() {
    _loadUserPhoto(); // Reload the profile picture when coming back to HomeScreen
  }

  // Load the profile picture from SharedPreferences
  Future<void> _loadUserPhoto() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? photoURL = prefs.getString('userPhoto');
    setState(() {
      _photoURL = photoURL;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes when the screen is loaded
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
  }

  @override
  void dispose() {
    // Unsubscribe from the route observer when the widget is disposed
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false, // This hides the back arrow
        backgroundColor: Colors.blue[900], // AppBar background color
        actions: [
          if (_photoURL != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  // Navigate to profile screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: _photoURL == null
                    ? const CircularProgressIndicator(
                        color: Color.fromARGB(0, 43, 9, 122),
                      ) // Show loading indicator if _photoURL is null
                    : CircleAvatar(
                        backgroundImage: NetworkImage(_photoURL!),
                        radius: 20, // Adjust the radius as needed
                      ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Top space for better alignment
              Text(
                'Welcome to FireStream!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const StartScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange[400],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Real-Time Chat',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate to cloud storage and file management screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const CloudStartScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange[400],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cloud Storage',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
