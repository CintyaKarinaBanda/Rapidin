import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Generated file
import 'login_view.dart';
import 'auth_manager.dart';
import 'home_view.dart';
import 'admin_home_view.dart';
import 'providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        title: 'Rapidin - Gestión de Pedidos',
        theme: ThemeData(
          primarySwatch: Colors.orange,
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

            // If not logged in, show login screen
            if (!snapshot.hasData) {
              return const LoginView();
            }

            // User is logged in → check Firestore for their role
            final user = AuthManager().currentUser;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const Scaffold(
                    body: Center(child: Text('User record not found in Firestore')),
                  );
                }

                final role = userSnapshot.data!['role'] ?? 'user';

            if (role == 'admin') {
              return AdminHomeView(email: user.email ?? '');
            } else {
              return HomeView(email: user.email ?? '');
            }
              },
            );
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


