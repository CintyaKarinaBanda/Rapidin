import 'package:flutter/material.dart';
import 'dart:async';
import '../services/ble_service.dart';

class BleScreen extends StatefulWidget {
  const BleScreen({Key? key}) : super(key: key);

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  final BleService _bleService = BleService();
  StreamSubscription<BeaconSignal>? _signalSubscription;

  BeaconSignal? _lastSignal;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _autoConnect();
  }

  Future<void> _autoConnect() async {
    final initialized = await _bleService.initialize();
    if (initialized) {
      await _bleService.startScanning();

      _signalSubscription = _bleService.signalStream.listen((signal) {
        setState(() {
          _lastSignal = signal;
          _isConnected = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _signalSubscription?.cancel();
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distancia Pedido'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _lastSignal != null ? _buildDistanceCard() : _buildSearching(),
        ),
      ),
    );
  }

  Widget _buildSearching() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.orange),
        const SizedBox(height: 16),
        Text(
          'Buscando pedido_1...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildDistanceCard() {
    final signal = _lastSignal!;
    final distance = signal.distance;
    final rssi = signal.rssi;
    final time = signal.timestamp.toString().substring(11, 19);

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 64,
              color: distance < 1.0
                  ? Colors.green
                  : distance < 3.0
                      ? Colors.orange
                      : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '${distance.toStringAsFixed(1)}m',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'RSSI: ${rssi} dBm',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'Actualizado: $time',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              distance < 1.0
                  ? 'MUY CERCA'
                  : distance < 3.0
                      ? 'CERCA'
                      : 'LEJOS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: distance < 1.0
                    ? Colors.green
                    : distance < 3.0
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
