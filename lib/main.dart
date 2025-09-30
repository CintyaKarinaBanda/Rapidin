import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated file
import 'login_view.dart';
import 'auth_manager.dart';
import 'home_view.dart';

void main() async {
  // Ensure Flutter is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Check if user is already logged in
      home: StreamBuilder(
        stream: AuthManager().authStateChanges,
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // If user is logged in, go to home
          if (snapshot.hasData) {
            final user = AuthManager().currentUser;
            return HomeView(email: user?.email ?? '');
          }

          // Otherwise show login
          return const LoginView();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}


