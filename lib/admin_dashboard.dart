import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_editprofile.dart';
import 'admin_login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  int animalBiteCounter = 0;
  int healthCareCounter = 0;
  int otherServicesCounter = 0;

  Future<void> _updateQueueCount(String service, int count) async {
  try {
    print('Updating $service count to $count'); // Debugging
    await supabase
        .from('queue_counts')
        .upsert(
          {'service_name': service, 'count': count},
          onConflict: 'service_name', // Specify the unique column
        );
    print('$service count updated successfully'); // Debugging
  } catch (error) {
    print('Error updating $service count: $error'); // Debugging
  }
}

 void _incrementCounter(String service) async {
  print('Incrementing $service'); // Debugging
  setState(() {
    if (service == "Animal Bite") {
      animalBiteCounter++;
    } else if (service == "Health Care Check-up") {
      healthCareCounter++;
    } else if (service == "Other Services") {
      otherServicesCounter++;
    }
  });

  try {
    // Update the queue count in Supabase
    await _updateQueueCount(service, service == "Animal Bite" ? animalBiteCounter : service == "Health Care Check-up" ? healthCareCounter : otherServicesCounter);

    // Update the status of user queues
    await supabase
        .from('user_queues')
        .update({'status': 'done'})
        .eq('service_name', service)
        .eq('queue_number', animalBiteCounter.toString()); // Use the correct counter based on the service

    print('$service count updated in Supabase'); // Debugging
  } catch (error) {
    print('Error updating $service count: $error'); // Debugging
  }
}

  void _resetCounters() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Reset"),
          content: const Text("Are you sure you want to reset all queues? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog first
                setState(() {
                  animalBiteCounter = 0;
                  healthCareCounter = 0;
                  otherServicesCounter = 0;
                });
                await _updateQueueCount("Animal Bite", 0);
                await _updateQueueCount("Health Care Check-up", 0);
                await _updateQueueCount("Other Services", 0);
              },
              child: const Text("Reset", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text(
          "YOUR QUE`",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          _profileButton(context),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "NOW SERVING",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _queueItem(animalBiteCounter, "Animal Bite"),
              _queueItem(healthCareCounter, "Health Care Check-up"),
              _queueItem(otherServicesCounter, "Other Services"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetCounters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Reset Queues"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _queueItem(int number, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _button("Next", Icons.chevron_right, () => _incrementCounter(title)),
              const SizedBox(height: 8),
              _button("Notify", Icons.notifications, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _button(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.black),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _profileButton(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.person, color: Colors.black),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: 0,
          child: Column(
            children: [
              const Text(
                "Admin 1",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Divider(),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: _menuItem("Edit Profile", Icons.edit),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: _menuItem("Logout", Icons.logout),
        ),
      ],
      onSelected: (value) {
        if (value == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UpdateAdminSignUpPage()),
          );
        } else if (value == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminLogin()),
          );
        }
      },
    );
  }

  Widget _menuItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.black),
        const SizedBox(width: 10),
        Text(text),
      ],
    );
  }
}