class CartItem {
  final String name;
  final double price;
  final String image;
  final String description;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'image': image,
      'description': description,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      image: map['image'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] as int?) ?? 1,
    );
  }
}
