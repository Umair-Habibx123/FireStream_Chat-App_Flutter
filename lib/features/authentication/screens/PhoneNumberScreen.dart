import 'package:firebase_auth/firebase_auth.dart';
import 'package:firestream/features/authentication/screens/home_screen.dart';
import 'package:firestream/features/authentication/screens/otp_screen.dart';
import 'package:flutter/material.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  _PhoneNumberScreenState createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  String _selectedCountryCode = '+92'; // Default country code
  bool _isLoading = false; // Variable to track loading state
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _isPhoneNumberValid = false;

  @override
  void initState() {
    super.initState();
    _phoneNumberController.addListener(() {
      setState(() {
        _isPhoneNumberValid = _phoneNumberController.text.length >=
            10; // Basic validation for phone number length
      });
    });
  }

  Future<void> _sendVerificationCode() async {
    final phoneNumber =
        _selectedCountryCode + _phoneNumberController.text.trim();
    // Show the entered phone number in SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Phone number entered: $phoneNumber')),
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError(e.message ?? 'Phone number verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                  verificationId: verificationId, phoneNumber: phoneNumber),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timed out
        },
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Number Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            const Text(
                'Enter your phone number to receive a verification code.'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCountryCode,
                      underline: const SizedBox(),
                      items: <String>[
                        '+92',
                        '+1',
                        '+93'
                      ] // Add other country codes as needed
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCountryCode = newValue!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Phone Number',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isPhoneNumberValid && !_isLoading
                  ? _sendVerificationCode
                  : null,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Code'),
            ),
          ],
        ),
      ),
    );
  }
}
