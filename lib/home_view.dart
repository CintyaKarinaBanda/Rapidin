import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

import 'ble_module/screens/distance_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';

class HomeView extends StatelessWidget {
  final String email;

  const HomeView({Key? key, required this.email}) : super(key: key);

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

            // Cart icon
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
                        constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          cart.itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white, fontSize: 12),
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

      // BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('dishes').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No hay platillos disponibles"));
            }

            final docs = snapshot.data!.docs;

            return GridView.builder(
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;

                final item = {
                  'name': data['name'] ?? 'Sin nombre',
                  'price': (data['price'] ?? 0).toDouble(),
                  'description': data['available'] == true ? "Disponible" : "No disponible",
                };


                return _buildMenuCard(context, item);
              },
            );
          },
        ),
      ),
    );
  }

  // --- CARD WIDGET ---
  Widget _buildMenuCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: item),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'],
                style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              Expanded(
                child: Text(
                  item['description'],
                  style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${item['price'].toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    color: Colors.orange,
                    iconSize: 28,
                    icon: const Icon(Icons.add_circle),
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false)
                      .addItem(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 1),
                          content: Text('${item['name']} agregado al carrito'),
                        ),
                      );
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
