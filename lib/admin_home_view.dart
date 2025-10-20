import 'package:flutter/material.dart';

class AdminHomeView extends StatelessWidget {
  final String email;

  const AdminHomeView({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Center(
        child: Text('Welcome, admin $email!'),
      ),
    );
  }
}
