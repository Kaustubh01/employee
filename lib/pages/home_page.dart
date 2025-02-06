import 'package:employee/pages/dashboard.dart';
import 'package:employee/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _isUSerLoggedIn = false;
  @override
  void initState(){
    super.initState();
    _checkLoginStatus();
  }

  _checkLoginStatus() async {
    String? email = await _storage.read(key:  'email');
    if(email != null){
      setState(() {
        _isUSerLoggedIn = true;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return _isUSerLoggedIn ? Dashboard() : Signup();
  }
}