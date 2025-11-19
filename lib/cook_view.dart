import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

import 'ble_module/screens/distance_screen.dart';
import 'screens/cart_screen.dart';

class CookView extends StatelessWidget {
  final String email;

  const CookView({Key? key, required this.email}) : super(key: key);

  void _handleLogout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapidin - Menú'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.bluetooth),
              tooltip: 'BLE Monitor',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DistanceScreen()),
              ),
            ),

            // Cart icon (kept for UI consistency)
            Consumer<CartProvider>(
              builder: (context, cart, child) => Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: 'Carrito',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cart.itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => _handleLogout(context),
            ),
          ],
      ),

      // --- BODY REPLACED WITH ONLY "Cook View" ---
      body: const Center(
        child: Text(
          "Cook View",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }
}
