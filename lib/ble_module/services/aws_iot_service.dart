import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/ble_device_model.dart';

class AwsIotService {
  static final AwsIotService _instance = AwsIotService._internal();
  factory AwsIotService() => _instance;
  AwsIotService._internal();

  MqttServerClient? _client;
  bool _isConnected = false;
  
  // AWS IoT Configuration - Replace with your values
  static const String _endpoint = 'your-iot-endpoint.iot.region.amazonaws.com';
  static const String _clientId = 'rapidin-mobile-client';
  static const String _topicPrefix = 'rapidin/ble';

  Future<bool> initialize({
    required String endpoint,
    required String clientId,
    String? certificatePath,
    String? privateKeyPath,
    String? caCertPath,
  }) async {
    try {
      _client = MqttServerClient.withPort(
        endpoint.isNotEmpty ? endpoint : _endpoint,
        clientId.isNotEmpty ? clientId : _clientId,
        8883,
      );

      _client!.logging(on: true);
      _client!.secure = true;
      _client!.keepAlivePeriod = 60;
      _client!.connectTimeoutPeriod = 5000;

      // Set up SSL context if certificates are provided
      if (certificatePath != null && privateKeyPath != null) {
        final context = SecurityContext.defaultContext;
        if (caCertPath != null) {
          context.setTrustedCertificates(caCertPath);
        }
        context.useCertificateChain(certificatePath);
        context.usePrivateKey(privateKeyPath);
        _client!.securityContext = context;
      }

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId.isNotEmpty ? clientId : _clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      
      _client!.connectionMessage = connMessage;

      await _client!.connect();
      
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _isConnected = true;
        print('AWS IoT connected successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      print('AWS IoT connection error: $e');
      return false;
    }
  }

  Future<void> publishDeviceData(BleDeviceModel device) async {
    if (!_isConnected || _client == null) {
      print('AWS IoT not connected');
      return;
    }

    try {
      final topic = '$_topicPrefix/device_data';
      final payload = jsonEncode({
        ...device.toJson(),
        'mobile_client_id': _clientId,
        'event_type': 'distance_measurement',
      });

      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      _client!.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('Published to AWS IoT: $payload');
    } catch (e) {
      print('Error publishing to AWS IoT: $e');
    }
  }

  Future<void> publishProximityEvent({
    required String deviceId,
    required String eventType, // 'entered', 'exited'
    required double distance,
    required double threshold,
  }) async {
    if (!_isConnected || _client == null) return;

    try {
      final topic = '$_topicPrefix/proximity_events';
      final payload = jsonEncode({
        'device_id': deviceId,
        'event_type': eventType,
        'distance': distance,
        'threshold': threshold,
        'timestamp': DateTime.now().toIso8601String(),
        'mobile_client_id': _clientId,
      });

      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      _client!.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('Proximity event published: $eventType for device $deviceId');
    } catch (e) {
      print('Error publishing proximity event: $e');
    }
  }

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}