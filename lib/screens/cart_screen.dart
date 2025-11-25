// ignore_for_file: all
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_status_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Timer? _statusChecker;
  String? _lastKnownStatus;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _startStatusPolling();
  }

  // ======================================================
  // INITIALIZE NOTIFICATIONS (token saving + listeners)
  // ======================================================
  Future<void> _initializeNotifications() async {
    try {
      // Request permission (CRITICAL for iOS and Android 13+)
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Save token and listen for changes
        await _saveUserFCMToken();
        _listenForTokenRefresh();
        _listenForNotifications();
        _setupInteractedMessage();
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _saveUserFCMToken();
        _listenForTokenRefresh();
        _listenForNotifications();
      } else {
        // User declined or has not accepted permission
        // still start polling (notifications will be local)
      }
    } catch (e) {
      print("Notification init error: $e");
    }
  }

  // ======================================================
  // SAVE USER'S FCM TOKEN
  // ======================================================
  Future<void> _saveUserFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in (FCM token not saved)');
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('FCM token is null');
        return;
      }

      print('FCM Token: $token');

      await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .set({
        "fcmToken": token,
        "tokenUpdatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Token saved successfully to Firestore');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // ======================================================
  // LISTEN FOR TOKEN REFRESH
  // ======================================================
  void _listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({
          "fcmToken": newToken,
          "tokenUpdatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Refreshed token saved successfully');
      } catch (e) {
        print('Error saving refreshed token: $e');
      }
    });
  }

  // ======================================================
  // LISTEN FOR FOREGROUND PUSH NOTIFICATIONS (FCM)
  // ======================================================
  void _listenForNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      if (!mounted) return;

      final notif = message.notification;
      if (notif == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${notif.title ?? 'Notificación'}\n${notif.body ?? ''}",
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () {
              _handleNotificationTap(message);
            },
          ),
        ),
      );
    });
  }

  // ======================================================
  // SETUP NOTIFICATION TAP HANDLER (BACKGROUND/TERMINATED)
  // ======================================================
  Future<void> _setupInteractedMessage() async {
    // Handle notification tap when app was terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state by notification');
      _handleNotificationTap(initialMessage);
    }

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background by notification');
      _handleNotificationTap(message);
    });
  }

  // ======================================================
  // HANDLE NOTIFICATION TAP
  // ======================================================
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');

    // Navigate based on notification data
    if (message.data['type'] == 'order_update') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OrderStatusScreen(),
        ),
      );
    }
  }

  // ======================================================
  // POLLING: check the most recent order every 3 seconds
  // ======================================================
  void _startStatusPolling() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in — polling not started");
      return;
    }

    // Immediately run once to initialize last status
    _checkLatestOrderStatusOnce();

    // Start periodic polling every 3 seconds
    _statusChecker = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkLatestOrderStatusOnce();
    });
  }

  Future<void> _checkLatestOrderStatusOnce() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
      .collection("orders")
      .where("clientID", isEqualTo: user.uid)
      .orderBy("createdAt", descending: true)
      .limit(1)
      .get();

      if (snap.docs.isEmpty) {
        // No orders yet — reset last known status
        if (_lastKnownStatus != null) {
          _lastKnownStatus = null;
        }
        return;
      }

      final doc = snap.docs.first;
      final data = doc.data();

      // Safely read status as String?
      final dynamic statusField = data['status'];
      final String status = statusField == null ? 'unknown' : statusField.toString();

      // First poll: initialize
      if (_lastKnownStatus == null) {
        _lastKnownStatus = status;
        print("Initialized lastKnownStatus = $_lastKnownStatus");
        return;
      }

      // Compare
      if (status != _lastKnownStatus) {
        print("STATUS CHANGED: $_lastKnownStatus -> $status");
        final previous = _lastKnownStatus;
        _lastKnownStatus = status;

        // Show local in-app notification (SnackBar)
        _showLocalNotification(
          title: "Actualización de tu pedido",
          body: "Estado: $status",
        );

        // Optionally navigate to order screen when user taps the action.
        // (We already show a 'Ver' action in the SnackBar)
        // If you also want to send a remote push, keep Cloud Function active.
      }
    } catch (e) {
      print("Error checking latest order status: $e");
    }
  }

  // ======================================================
  // SHOW LOCAL IN-APP NOTIFICATION (SnackBar)
  // ======================================================
  void _showLocalNotification({required String title, required String body}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title\n$body"),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrderStatusScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ======================================================
  // UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
          actions: [
            Consumer<CartProvider>(
              builder: (context, cart, child) => cart.items.isNotEmpty
              ? IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _showClearCartDialog(context),
                tooltip: 'Vaciar carrito',
              )
              : const SizedBox(),
            ),
          ],
      ),

      // ===========================
      // BODY WITH PENDING ORDER CHECK
      // ===========================
      body: Column(
        children: [
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tu carrito está vacío',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Agrega algunos productos para continuar',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Product Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${item.price.toStringAsFixed(2)} c/u',
                                          style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Total: \$${item.totalPrice.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quantity Controls
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () => cart.updateQuantity(
                                              item.name, item.quantity - 1),
                                              icon: const Icon(Icons.remove_circle_outline),
                                              color: Colors.orange,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.orange),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item.quantity.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              ),
                                          ),
                                          IconButton(
                                            onPressed: () => cart.updateQuantity(
                                              item.name, item.quantity + 1),
                                              icon: const Icon(Icons.add_circle_outline),
                                              color: Colors.orange,
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                        cart.removeItem(item.name),
                                        child: const Text(
                                          'Eliminar',
                                          style: TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total (${cart.itemCount} productos):',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '\$${cart.totalAmount.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showOrderConfirmation(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                              ),
                              child: const Text(
                                'Realizar Pedido',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ===============================
          //     PENDING ORDER BUTTON
          // ===============================
          if (user != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
              .collection("orders")
              .where("clientID", isEqualTo: user.uid)
              .where("status", isEqualTo: "pending")
              .limit(1)
              .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox();
                }

                return Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderStatusScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Ver mi pedido pendiente",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ======================================================
  // DIALOGS + ORDER CREATION
  // ======================================================

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar Carrito'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los productos del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.pop(context);
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOrderConfirmation(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final TextEditingController tableController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: \$${cart.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: tableController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Número de mesa",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (tableController.text.isEmpty) return;

              await _createOrderInFirebase(
                context,
                tableNumber: tableController.text.trim(),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrderInFirebase(
    BuildContext context, {
      required String tableNumber,
    }) async {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes iniciar sesión para hacer un pedido")),
        );
        return;
      }

      try {
        List<Map<String, dynamic>> cartItems = cart.items.map((item) {
          return {
            "name": item.name,
            "price": item.price,
            "quantity": item.quantity,
            "total": item.totalPrice,
          };
        }).toList();

        await FirebaseFirestore.instance.collection("orders").add({
          "clientID": user.uid,
          "createdAt": FieldValue.serverTimestamp(),
          "status": "pending",
          "tableNumber": tableNumber,
          "items": cartItems,
          "total": cart.totalAmount,
        });

        if (!context.mounted) return;

        Navigator.pop(context);
        cart.clearCart();

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Pedido Realizado"),
            content: const Text("Tu pedido fue enviado correctamente."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );

        if (!context.mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OrderStatusScreen(),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar pedido: $e")),
        );
      }
    }

    @override
    void dispose() {
      _statusChecker?.cancel();
      super.dispose();
    }
}
