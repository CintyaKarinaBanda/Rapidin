// ignore_for_file: use_build_context_synchronously
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
        title: const Text('Rapidin - Cocina'),
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

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
        .collection("orders")
        .orderBy("createdAt", descending: true)
        .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error al cargar pedidos: ${snapshot.error}",
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay pedidos aún.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;

              final table = data["tableNumber"] ?? "-";
              final status = data["status"] ?? "unknown";
              final total = (data["total"] ?? 0).toDouble();
              final createdAt = (data["createdAt"] as Timestamp?)?.toDate();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mesa $table",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      if (createdAt != null)
                        Text("Fecha: ${_formatDate(createdAt)}"),

                        Text("Total: \$${total.toStringAsFixed(2)}"),

                        const SizedBox(height: 8),

                        Text(
                          "Estado actual: ${_statusText(status)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _statusColor(status),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Show buttons only if order is not cancelled or delivered
                        if (status != "cancelled" && status != "delivered")
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Cancel button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                _updateStatus(doc.id, "cancelled", context),
                                child: const Text("Cancelar"),
                              ),

                              // Preparing
                              if (status == "pending")
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                  _updateStatus(doc.id, "preparing", context),
                                  child: const Text("En proceso"),
                                ),

                              // In transit
                              if (status == "preparing")
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                  _updateStatus(doc.id, "in_transit", context),
                                  child: const Text("En camino"),
                                ),

                              // Delivered
                              if (status == "in_transit")
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                  _updateStatus(doc.id, "delivered", context),
                                  child: const Text("Entregado"),
                                ),
                            ],
                          ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Format date to readable format
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // Translate status to Spanish
  String _statusText(String status) {
    switch (status) {
      case "pending":
        return "Pendiente";
      case "preparing":
        return "En preparación";
      case "in_transit":
        return "En camino";
      case "delivered":
        return "Entregado";
      case "cancelled":
        return "Cancelado";
      default:
        return "Desconocido";
    }
  }

  // Firestore status update
  Future<void> _updateStatus(
    String orderId, String newStatus, BuildContext context) async {
      try {
        await FirebaseFirestore.instance
        .collection("orders")
        .doc(orderId)
        .update({"status": newStatus});

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Estado actualizado a: ${_statusText(newStatus)}"),
            backgroundColor: _statusColor(newStatus),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar estado: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Color logic
    Color _statusColor(String status) {
      switch (status) {
        case "pending":
          return Colors.orange;
        case "preparing":
          return Colors.blue;
        case "in_transit":
          return Colors.green;
        case "delivered":
          return Colors.grey;
        case "cancelled":
          return Colors.red;
        default:
          return Colors.black;
      }
    }
}
