import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addItem(Map<String, dynamic> product) {
    final existingIndex =
        _items.indexWhere((item) => item.name == product['name']);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      final productWithQuantity = Map<String, dynamic>.from(product);
      productWithQuantity['quantity'] = 1;
      _items.add(CartItem.fromMap(productWithQuantity));
    }
    notifyListeners();
  }

  void removeItem(String productName) {
    if (productName.isEmpty) return;

    _items.removeWhere((item) => item.name == productName);
    notifyListeners();
  }

  void updateQuantity(String productName, int quantity) {
    if (productName.isEmpty) return;

    final index = _items.indexWhere((item) => item.name == productName);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
