// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is null before building
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mis Pedidos"),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            "Debes iniciar sesión para ver tus pedidos.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Pedidos"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
        .collection("orders")
        .where("clientID", isEqualTo: user.uid)
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
                "No tienes pedidos aún.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          // Sort orders by createdAt in code instead of query
          orders.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)["createdAt"] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)["createdAt"] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime); // descending order
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final status = data["status"] ?? "unknown";
              final table = data["tableNumber"] ?? "-";
              final total = (data["total"] ?? 0).toDouble();
              final createdAt = (data["createdAt"] as Timestamp?)?.toDate();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    "Mesa $table",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (createdAt != null)
                        Text("Fecha: ${_formatDate(createdAt)}"),
                        Text("Total: \$${total.toStringAsFixed(2)}"),
                        const SizedBox(height: 4),
                        Text(
                          "Estado: ${_statusText(status)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _statusColor(status),
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
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
      case "ready":
        return "Listo";
      case "delivered":
        return "Entregado";
      case "cancelled":
        return "Cancelado";
      default:
        return "Desconocido";
    }
  }

  // Colors based on status
  Color _statusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "preparing":
        return Colors.blue;
      case "ready":
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
