// ignore_for_file: all
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminHomeView extends StatelessWidget {
  final String email;

  const AdminHomeView({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to the "orders" collection, ordered by creation date (latest first)
        stream: FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading orders: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No orders found.'),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;

              final customerEmail = data['customerEmail'] ?? 'Unknown';
          final total = data['total'] ?? 0.0;
          final status = data['status'] ?? 'unknown';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          final formattedDate = createdAt != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt)
          : 'No date';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 2,
            child: ListTile(
              title: Text('Order from $customerEmail'),
              subtitle: Text('Status: $status\nDate: $formattedDate'),
              trailing: Text('\$${total.toStringAsFixed(2)}'),
              onTap: () {
                // Optionally show more order details in a dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Order details'),
                    content: Text(data.toString()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
            },
          );
        },
      ),
    );
  }
}
