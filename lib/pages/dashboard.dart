import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:employee/pages/record_attendance.dart';
import 'package:http/http.dart' as http;
import 'package:employee/comon.dart';
import 'signup.dart';

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
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
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

  Future<void> _logout() async {
    await _storage.deleteAll();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Signup()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: () {
              // Create the QR data (it could be dynamic based on your logic)
              Map<String, dynamic> qrData = {
                'employeeId': employee['id'],
                'name': employee['name'],
                'email': employee['email'],
              };

              // Navigate to RecordAttendance page and pass the QR data
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildEmployeeCard(),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employee['name']?.toUpperCase() ?? "Loading...",
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Text(employee['email'] ?? "Loading..."),
            const SizedBox(height: 10),
            Text("Department: ${employee['department'] ?? 'N/A'}"),
            Text("Role: ${employee['role'] ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                "Tasks",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  var task = tasks[index];
                  return ListTile(
                    title: Text(task['title']),
                    subtitle: Text(task['description'] ?? "No description"),
                    onTap: () => _showTaskDetails(task),
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
          title: Text(task['title']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task['description'] ?? "No description"),
              if (task['dueDate'] != null)
                Text("Due: ${task['dueDate'].split("T")[0]}")
            ],
          ),
          actions: [
            TextButton(onPressed: () {}, child: const Text("Ongoing")),
            TextButton(onPressed: () {}, child: const Text("Completed")),
          ],
        );
      },
    );
  }
}

