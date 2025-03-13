import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome.dart';
import 'reset_password_page.dart';
import 'home_page.dart'; // Ensure this import is added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ilykfrtpklabqvbfewos.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlseWtmcnRwa2xhYnF2YmZld29zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk4ODAyMTAsImV4cCI6MjA1NTQ1NjIxMH0.z9Ioc1tOvmdxOL1mojDRD9bP5z0fIkSz9G9LsRasJdI',
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    // Check the initial authentication state
    _checkAuthState();

    // Listen for authentication state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        setState(() {
          _isLoggedIn = true;
          _isLoading = false;
        });
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      } else if (event == AuthChangeEvent.passwordRecovery) {
        // Navigate to Reset Password Page when password recovery is detected
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResetPasswordPage()),
        );
      }
    });
  }

  // Check the initial authentication state
  Future<void> _checkAuthState() async {
    final session = supabase.auth.currentSession;
    setState(() {
      _isLoggedIn = session != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a loading indicator while checking the auth state
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      home: _isLoggedIn ? HomePage() : WelcomePage(), // Redirect based on auth state
      debugShowCheckedModeBanner: false,
    );
  }
}