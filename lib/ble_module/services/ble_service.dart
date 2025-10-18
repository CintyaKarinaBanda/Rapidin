import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  final StreamController<BeaconSignal> _signalController = 
      StreamController<BeaconSignal>.broadcast();
  
  Stream<BeaconSignal> get signalStream => _signalController.stream;
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _restartTimer;
  bool _isScanning = false;

  Future<bool> initialize() async {
    try {
      if (!await FlutterBluePlus.isSupported) return false;
      await _requestPermissions();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
  }

  Future<void> startScanning() async {
    if (_isScanning) return;
    _isScanning = true;
    _startContinuousScanning();
  }

  void _startContinuousScanning() async {
    if (!_isScanning) return;

    try {
      print("Flutter: Iniciando escaneo continuo...");
      await FlutterBluePlus.startScan();
      
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final name = result.device.platformName;
          if (name == 'pedido_1') {
            final signal = BeaconSignal(
              name: name,
              rssi: result.rssi,
              distance: _calculateDistance(result.rssi),
              timestamp: DateTime.now(),
            );
            print("Flutter: RSSI: ${signal.rssi}, Distancia: ${signal.distance}m");
            _signalController.add(signal);
          }
        }
      });
      
    } catch (e) {
      print("Flutter: Error: $e");
      if (_isScanning) {
        Timer(const Duration(seconds: 2), _startContinuousScanning);
      }
    }
  }

  double _calculateDistance(int rssi) {
    if (rssi >= -30) return 0.03; // Pegado al dispositivo
    if (rssi >= -35) return 0.08; // 8cm
    if (rssi >= -40) return 0.15; // 15cm
    if (rssi >= -45) return 0.25; // 25cm
    if (rssi >= -50) return 0.4;  // 40cm
    if (rssi >= -55) return 0.6;  // 60cm
    if (rssi >= -60) return 0.9;  // 90cm
    if (rssi >= -65) return 1.3;  // 1.3m
    if (rssi >= -70) return 1.8;  // 1.8m
    if (rssi >= -75) return 2.5;  // 2.5m
    if (rssi >= -80) return 3.5;  // 3.5m
    if (rssi >= -85) return 5.0;  // 5m
    if (rssi >= -90) return 7.0;  // 7m
    if (rssi >= -95) return 10.0; // 10m
    return 15.0;                  // >15m
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    _restartTimer?.cancel();
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
  }

  void dispose() {
    stopScanning();
    _signalController.close();
  }
}

class BeaconSignal {
  final String name;
  final int rssi;
  final double distance;
  final DateTime timestamp;

  BeaconSignal({
    required this.name,
    required this.rssi,
    required this.distance,
    required this.timestamp,
  });
}