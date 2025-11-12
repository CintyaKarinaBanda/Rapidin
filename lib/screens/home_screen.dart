// ignore_for_file: all
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../home_view.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userEmail = authProvider.user?.email ?? "";

    return HomeView(email: userEmail);
  }
}
