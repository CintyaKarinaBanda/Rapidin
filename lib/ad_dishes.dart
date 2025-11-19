// ignore_for_file: all
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdDishesView extends StatelessWidget {
  const AdDishesView({Key? key}) : super(key: key);

  // ----------------------------------------------------------
  // Add or Edit Dish Dialog
  // ----------------------------------------------------------
  void _openDishDialog(BuildContext context, {String? docId, Map<String, dynamic>? data}) {
    final nameController = TextEditingController(text: data?['name'] ?? '');
    final priceController = TextEditingController(text: data?['price']?.toString() ?? '');
    final descriptionController = TextEditingController(text: data?['description'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(docId == null ? "Add New Dish" : "Edit Dish"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Dish name"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              final description = descriptionController.text.trim();

              if (name.isEmpty) return;

              if (docId == null) {
                // CREATE
                await FirebaseFirestore.instance.collection("dishes").add({
                  "name": name,
                  "price": price,
                  "description": description,
                  "createdAt": Timestamp.now(),
                });
              } else {
                // UPDATE
                await FirebaseFirestore.instance.collection("dishes").doc(docId).update({
                  "name": name,
                  "price": price,
                  "description": description,
                });
              }

              Navigator.pop(context);
            },
            child: Text(docId == null ? "Add" : "Save"),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Delete Dish
  // ----------------------------------------------------------
  void _deleteDish(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Dish"),
        content: const Text("Are you sure you want to delete this dish?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("dishes").doc(docId).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // MAIN UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dishes"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openDishDialog(context),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
        .collection("dishes")
        .orderBy("createdAt", descending: true)
        .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No dishes found."));
          }

          final dishes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              final data = dish.data() as Map<String, dynamic>;
              final docId = dish.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  title: Text(data["name"] ?? "Unnamed dish"),
                  subtitle: Text("Price: \$${data["price"]?.toStringAsFixed(2) ?? "0.00"}"
                  "\n${data['description'] ?? ''}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openDishDialog(context, docId: docId, data: data),
                      ),
                      // Delete
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteDish(context, docId),
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
}
