import 'package:flutter/material.dart';
import 'auth_manager.dart';

class HomeView extends StatelessWidget {
  final String email;

  const HomeView({Key? key, required this.email}) : super(key: key);

  void _handleLogout(BuildContext context) async {
    await AuthManager().signOut();
  }

  final List<Map<String, dynamic>> _menuItems = const [
    {
      'name': 'Pizza Margherita',
      'price': 12.99,
      'image': '🍕',
      'description': 'Tomate, mozzarella y albahaca fresca'
    },
    {
      'name': 'Hamburguesa Clásica',
      'price': 9.99,
      'image': '🍔',
      'description': 'Carne, lechuga, tomate y queso'
    },
    {
      'name': 'Tacos al Pastor',
      'price': 8.50,
      'image': '🌮',
      'description': 'Carne al pastor con piña y cebolla'
    },
    {
      'name': 'Sushi Roll',
      'price': 15.99,
      'image': '🍣',
      'description': 'Salmón, aguacate y pepino'
    },
    {
      'name': 'Pasta Carbonara',
      'price': 11.50,
      'image': '🍝',
      'description': 'Pasta con bacon, huevo y parmesano'
    },
    {
      'name': 'Ensalada César',
      'price': 7.99,
      'image': '🥗',
      'description': 'Lechuga , Jitomate, pollo, crutones y aderezo'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapidin - Menú'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {},
            tooltip: 'Carrito',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Elige tus platillos favoritos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return _buildMenuCard(context, item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showItemDetails(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Center(
                child: Text(
                  item['image'],
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 8),
              
              // Name
              Text(
                item['name'],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Description
              Text(
                item['description'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              
              // Price and Add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${item['price'].toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _addToCart(context, item),
                    icon: const Icon(Icons.add_circle),
                    color: Colors.orange,
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item['image'],
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(item['description']),
            const SizedBox(height: 16),
            Text(
              'Precio: \$${item['price'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addToCart(context, item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar al carrito'),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} agregado al carrito'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}