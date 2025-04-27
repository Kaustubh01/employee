import 'dart:convert';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'signup.dart';
import 'record_attendance.dart';
import '../comon.dart'; // your baseurl file

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic> employee = {};
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    String? email = await _storage.read(key: 'email');
    if (email != null) {
      await _getEmployeeUsingEmail(email);
      await _getTasks(employee['id'].toString());
    } else {
      debugPrint("User email not found in secure storage");
    }
  }

  Future<void> _getEmployeeUsingEmail(String email) async {
    final url = Uri.parse('$baseurl/business/general/employees/email?email=$email');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          employee = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching employee: $e");
    }
  }

  Future<void> _getTasks(String id) async {
    final url = Uri.parse('$baseurl/tasks?employeeId=$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          tasks = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      debugPrint("Error loading tasks: $e");
    }
  }

  Future<void> _updateTaskStatus(int taskId, String status) async {
    final url = Uri.parse('$baseurl/tasks/update-status');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'taskId': taskId, 'status': status}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task status updated to "$status"')),
        );
        await _getTasks(employee['id'].toString());
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update task status')),
        );
      }
    } catch (e) {
      debugPrint("Error updating task status: $e");
    }
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Signup()),
      );
    }
  }

  Future<void> _openRequestForm() async {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final String subject = subjectController.text;
                final String body = bodyController.text;
                final String email = 'admin@example.com'; // Change to your admin email

                final AndroidIntent intent = AndroidIntent(
                  action: 'android.intent.action.SENDTO',
                  data: Uri.encodeFull('mailto:$email?subject=$subject&body=$body'),
                  flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                );

                try {
                  await intent.launch();
                } catch (e) {
                  // fallback if no app found
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No email app found to send request.')),
                  );
                }

                Navigator.pop(context); // close dialog after send
              },
              child: const Text('Send'),
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
        title: const Text("Dashboard"),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Map<String, dynamic> qrData = {
                'employeeId': employee['id'],
                'name': employee['name'],
                'email': employee['email'],
              };
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordAttendance(qrData: qrData),
                ),
              );
            },
            icon: const Icon(Icons.qr_code),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      employee['name']?.toUpperCase() ?? "Loading...",
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      employee['email'] ?? "Loading...",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.request_page, color: Colors.white),
                title: const Text("Requests", style: TextStyle(color: Colors.white)),
                onTap: _openRequestForm,
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text("Logout", style: TextStyle(color: Colors.white)),
                  onTap: _logout,
                ),
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          _buildEmployeeCard(),
          const Divider(color: Colors.grey),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            employee['name']?.toUpperCase() ?? "Loading...",
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            "Email Address: ${employee['email']}" ?? "Loading...",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Department: ${employee['department'] ?? 'N/A'}",
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            "Role: ${employee['role'] ?? 'N/A'}",
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tasks",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('No tasks assigned yet.'))
                  : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  var task = tasks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: ListTile(
                        title: Text(
                          task['title'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          task['description'] ?? "No description",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () => _showTaskDetails(task),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            task['title'],
            style: const TextStyle(color: Colors.orange),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task['description'] ?? "No description"),
              if (task['dueDate'] != null)
                Text("Due: ${task['dueDate'].split("T")[0]}"),
              const SizedBox(height: 10),
              Text("Current Status: ${task['status']}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _updateTaskStatus(task['id'], "ongoing"),
              child: const Text("Ongoing", style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => _updateTaskStatus(task['id'], "completed"),
              child: const Text("Completed", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }
}
