import 'dart:convert';
import 'package:employee/comon.dart';
import 'package:employee/pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<Map<String, dynamic>?> _getEmployee(String email) async {
    final url = Uri.parse('$baseurl/business/general/employees/email?email=$email');
    
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      print('Requesting: $url'); // Debugging request URL

      if (response.statusCode == 200) {
        final Map<String, dynamic> employee = jsonDecode(response.body);
        print('Full API Response: ${response.body}'); // Debugging API response

        // Extract employee and business data
        String employeeId = employee['id']?.toString() ?? 'Missing employee_id';
        String email = employee['email']?.toString() ?? 'Missing email';
        String businessId = employee['business_id']?.toString() ?? 'Missing business_id';
        String businessName = employee['business']?['name'] ?? 'No Business';

        print('Fetched Employee ID: $employeeId'); 
        print('Fetched Business ID: $businessId');
        print('Business Name: $businessName');

        return {
          'id': employeeId,
          'email':email
        };
      } else {
        print("Failed to fetch employee: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching employee: $e");
      return null;
    }
  }

  Future<void> _saveCredentials(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both email and password.")),
      );
      return;
    }

    Map<String, dynamic>? employeeData = await _getEmployee(email);

    if (employeeData != null && employeeData['id'] != 'Missing employee_id') {
      await _storage.write(key: 'id', value: employeeData['id']);
      await _storage.write(key: 'email', value: email);
      print(email);
      await _storage.write(key: 'password', value: password);
      await _storage.write(key: 'business_id', value: employeeData['business_id']);
      await _storage.write(key: 'business_name', value: employeeData['business_name']); 

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Dashboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or business ID.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Login",
              style: TextStyle(fontSize: 20.0),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Your Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Your Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _saveCredentials(context),
              child: const Text("Next Step"),
            ),
          ],
        ),
      ),
    );
  }
}
