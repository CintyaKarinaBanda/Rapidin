import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Generated file
import 'screens/login_screen.dart';
import 'home_view.dart';
import 'admin_home_view.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Rapidin - Gestión de Pedidos',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // If not authenticated, show login screen
            if (!authProvider.isAuthenticated) {
              return const LoginScreen();
            }

            // User is authenticated, check role in Firestore
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(authProvider.user!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  // User not found in Firestore, create default user document
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(authProvider.user!.uid)
                      .set({
                    'email': authProvider.user!.email,
                    'role': 'user',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  return HomeView(email: authProvider.user!.email);
                }

                if (userSnapshot.hasError) {
                  // Error accessing Firestore, default to user role
                  return HomeView(email: authProvider.user!.email);
                }

                final role = userSnapshot.data!['role'] ?? 'user';

                if (role == 'admin') {
                  return AdminHomeView(email: authProvider.user!.email);
                } else {
                  return HomeView(email: authProvider.user!.email);
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


