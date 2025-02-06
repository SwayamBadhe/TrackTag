import 'package:flutter/material.dart';
import 'package:track_tag/helpers/google_signin_helper.dart';
import 'package:track_tag/screens/homepage.dart'; 

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignInHelper _googleSignInHelper = GoogleSignInHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _signInWithGoogle,
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    final user = await _googleSignInHelper.signInWithGoogle();

    if (user != null) {
      // After successful sign-in, navigate to the HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(devices: []), // Placeholder for devices
        ),
      );
    } else {
      // Handle sign-in error or cancellation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Sign-In failed.")));
    }
  }
}
