import 'package:flutter/material.dart';
import 'package:group_lab1/main.dart';
import 'package:group_lab1/edit_profile_page.dart';
import 'package:group_lab1/welcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  runApp(MyApp());
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QueueDashboard(),
    );
  }
}

class QueueDashboard extends StatefulWidget {
  const QueueDashboard({super.key});

  @override
  _QueueDashboardState createState() => _QueueDashboardState();
}
Widget buildHomePage(BuildContext context) {
  return Center(
    child: Text("Home Page", style: TextStyle(color: Colors.white, fontSize: 24)),
  );
}

Widget buildQueuesPage(BuildContext context) {
  return Center(
    child: Text("Queues Page", style: TextStyle(color: Colors.white, fontSize: 24)),
  );
}
class _QueueDashboardState extends State<QueueDashboard> {
  int _selectedIndex = 0; 
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('user_id', user.id)
          .maybeSingle(); // Avoid crashing if no data is found

      setState(() {
        userProfile = response;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      buildHomePage(context),
      buildQueuesPage(context),
      buildProfilePage(context),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Your Que'", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Queues'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget buildProfilePage(BuildContext context) {
    if (userProfile == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundImage: AssetImage('assets/profile.jpg'),
          ),
          SizedBox(height: 10),
          Text(userProfile?['username'] ?? 'No Username',
              style: TextStyle(fontSize: 24, color: Colors.white)),
          SizedBox(height: 5),
          Text(userProfile?['email'] ?? 'No Email',
              style: TextStyle(fontSize: 16, color: Colors.white70)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage()),
              ).then((_) => _fetchUserProfile());
            },
            child: Text("Edit Profile"),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WelcomePage()),
              );
            },
            child: Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
