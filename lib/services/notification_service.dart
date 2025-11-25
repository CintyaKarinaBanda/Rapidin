import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _serverKey = 'TU_SERVER_KEY_AQUI';
  
  static Future<void> initialize() async {
    await _messaging.requestPermission();
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
    
    FirebaseMessaging.onMessage.listen((message) {
      print('Push recibido: ${message.notification?.title}');
    });
  }
  
  static Future<void> sendPushNotification(String token, String title, String body) async {
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {'title': title, 'body': body},
      }),
    );
  }
}