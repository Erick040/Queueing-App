import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'edit_profile_page.dart';
import 'welcome.dart';
import 'main.dart';

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

class _QueueDashboardState extends State<QueueDashboard> {
  int _selectedIndex = 0;
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> queues = [];
  late StreamSubscription<List<Map<String, dynamic>>> _queueStream;

  @override
  void initState() {
    super.initState();
    _fetchQueueCounts();
    _subscribeToQueueUpdates();
  }

  @override
  void dispose() {
    _queueStream.cancel(); // Cancel the stream when the widget is disposed
    super.dispose();
  }

  Future<void> _fetchQueueCounts() async {
    final response = await supabase.from('queue_counts').select();
    setState(() {
      queues = List<Map<String, dynamic>>.from(response);
    });
  }

  void _subscribeToQueueUpdates() {
    _queueStream = supabase
        .from('queue_counts')
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
      setState(() {
        queues = data;
      });
    });
  }

  Future<void> _getQueue(String queueName) async {
    try {
      final date = DateFormat('MM/dd/yyyy').format(DateTime.now());
      final time = DateFormat('hh:mm a').format(DateTime.now());
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check if the user has already queued for this service
      final existingQueueResponse = await supabase
          .from('user_queues')
          .select()
          .eq('user_id', user.id)
          .eq('service_name', queueName)
          .maybeSingle();

      if (existingQueueResponse != null) {
        // Fetch the current serving numbers for all services
        final queueCounts = await supabase.from('queue_counts').select();

        // Map service names to their serving numbers
        final servingNumbers = {
          for (var count in queueCounts) count['service_name']: count['count']
        };

        // Determine the status of the existing queue
        final existingQueueNumber =
            int.parse(existingQueueResponse['queue_number']);
        final servingNumber = servingNumbers[queueName] ?? 0;
        final status = existingQueueNumber < servingNumber
            ? 'done'
            : existingQueueNumber == servingNumber
                ? 'serving'
                : 'pending';

        // Allow re-queuing only if the status is 'done'
        if (status != 'done') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have already queued for $queueName.')),
          );
          return;
        }
      }

      // Fetch the latest queue number for the service
      final queueNumberResponse = await supabase
          .from('user_queues')
          .select('queue_number')
          .eq('service_name', queueName)
          .order('queue_number', ascending: false)
          .limit(1)
          .maybeSingle();

      int nextQueueNumber =
          1; // Start from 1 if no queues exist for this service
      if (queueNumberResponse != null) {
        nextQueueNumber = int.parse(queueNumberResponse['queue_number']) + 1;
      }

      // Insert into user_queues table
      final response = await supabase
          .from('user_queues')
          .insert({
            'service_name': queueName,
            'queue_number':
                nextQueueNumber.toString(), // Service-specific queue number
            'date': date,
            'time': time,
            'user_id': user.id,
          })
          .select()
          .single();

      final queueNumber = response['queue_number'].toString();
      _showQueueDialog(context, queueNumber, queueName, date, time);
    } catch (error) {
      print("Error inserting queue: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get queue: $error')),
      );
    }
  }

  void _showQueueDialog(BuildContext context, String queueNumber,
      String queueName, String date, String time) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(queueNumber,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(queueName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Date: $date"),
              Text("Time: $time"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserQueues() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final response =
        await supabase.from('user_queues').select().eq('user_id', user.id);

    // Fetch the current serving numbers for all services
    final queueCounts = await supabase.from('queue_counts').select();

    // Map service names to their serving numbers
    final servingNumbers = {
      for (var count in queueCounts) count['service_name']: count['count']
    };

    // Add status to each queue
    final queuesWithStatus = response.map((queue) {
      final servingNumber = servingNumbers[queue['service_name']] ?? 0;
      final queueNumber = int.parse(queue['queue_number']);
      final status = queueNumber < servingNumber
          ? 'done'
          : queueNumber == servingNumber
              ? 'serving'
              : 'pending';
      return {...queue, 'status': status};
    }).toList();

    return queuesWithStatus;
  }

  Map<String, dynamic> _fetchUserProfile() {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    return {
      'email': user.email,
      'username': user.userMetadata?['username'] ??
          'No Username', // Fetch username from metadata
    };
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      // Home Page
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: queues.length,
                itemBuilder: (context, index) {
                  final queue = queues[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(queue['count'].toString(),
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(height: 8),
                        Text('Serving',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        SizedBox(height: 8),
                        Text('${queue['service_name']} (Serving)',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            textStyle: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _getQueue(queue['service_name']),
                          child: Text('Get Que',
                              style: TextStyle(color: Colors.amber)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Queues Page
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserQueues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return QueueDetailsPage(userQueues: snapshot.data!);
          }
        },
      ),
      // Profile Page
      Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: Future.value(
              _fetchUserProfile()), // Use Future.value to wrap the synchronous method
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // Show a loading spinner
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData) {
              return Text('No user data found.');
            } else {
              final userProfile = snapshot.data!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: AssetImage('assets/profile.jpg'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userProfile['username'],
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    userProfile['email'],
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditProfilePage()),
                      );
                    },
                    child: Text("Edit Profile"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => WelcomePage()),
                      );
                    },
                    child:
                        Text("Log Out", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }
          },
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Your Que'",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
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
}

class QueueDetailsPage extends StatelessWidget {
  final List<Map<String, dynamic>> userQueues;

  const QueueDetailsPage({super.key, required this.userQueues});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: userQueues.length,
        itemBuilder: (context, index) {
          final queue = userQueues[index];
          return Card(
            margin: EdgeInsets.all(8),
            color: Colors.amber,
            child: ListTile(
              title: Text(
                'Queue Number: ${queue['queue_number']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service: ${queue['service_name']}'),
                  Text('Date: ${queue['date']}'),
                  Text('Time: ${queue['time']}'),
                  Text('Status: ${queue['status']}'), // Display the status
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
