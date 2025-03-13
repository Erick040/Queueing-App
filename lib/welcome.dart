import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:group_lab1/admin_signup.dart';
import 'signin_page.dart'; // Import the SignIn page


class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool isLoading = false;

  void _navigateToPage(Widget page) async {
    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 1)); // Simulating a delay

    if (mounted) {
      setState(() => isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to light gray
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/welcomepage.png',
              width: 350,
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Your Que'",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const Text(
              'We are glad to have you here.',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator(color: Colors.amber)
                : SizedBox(
                    width: 300,
                    height: 40,
                    child: ElevatedButton(
                      onPressed:
                          isLoading ? null : () => _navigateToPage(LoginPage()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
            const SizedBox(height: 40),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 18, color: Colors.white),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: "Sign up",
                    style: const TextStyle(
                      color: Colors.amber,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = isLoading
                          ? null
                          : () => _navigateToPage(SignUpPage()),
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
