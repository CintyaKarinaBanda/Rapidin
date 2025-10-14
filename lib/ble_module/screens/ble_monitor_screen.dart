import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ble_device_model.dart';
import '../services/proximity_manager.dart';
import '../services/aws_iot_service.dart';

class BleMonitorScreen extends StatefulWidget {
  const BleMonitorScreen({Key? key}) : super(key: key);

  @override
  State<BleMonitorScreen> createState() => _BleMonitorScreenState();
}

class _BleMonitorScreenState extends State<BleMonitorScreen> {
  final ProximityManager _proximityManager = ProximityManager();
  final AwsIotService _awsIotService = AwsIotService();
  
  final TextEditingController _targetDeviceController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _clientIdController = TextEditingController();
  
  bool _isMonitoring = false;
  bool _isAwsConnected = false;
  List<BleDeviceModel> _nearbyDevices = [];
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _targetDeviceController.text = 'pedido_1';
    _clientIdController.text = 'rapidin-mobile-${DateTime.now().millisecondsSinceEpoch}';
    
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isMonitoring) {
        setState(() {
          _nearbyDevices = _proximityManager.nearbyDevices;
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _proximityManager.stopMonitoring();
    _awsIotService.disconnect();
    super.dispose();
  }

  Future<void> _connectToAws() async {
    if (_endpointController.text.isEmpty) {
      _showSnackBar('Please enter AWS IoT endpoint', Colors.red);
      return;
    }

    final success = await _awsIotService.initialize(
      endpoint: _endpointController.text,
      clientId: _clientIdController.text,
    );

    setState(() {
      _isAwsConnected = success;
    });

    _showSnackBar(
      success ? 'Connected to AWS IoT' : 'Failed to connect to AWS IoT',
      success ? Colors.green : Colors.red,
    );
  }

  Future<void> _startMonitoring() async {
    if (_targetDeviceController.text.isEmpty) {
      _showSnackBar('Please enter target device ID', Colors.red);
      return;
    }

    try {
      await _proximityManager.startMonitoring(
        targetDeviceId: _targetDeviceController.text,
        threshold: 2.0,
        interval: const Duration(seconds: 5),
      );

      setState(() {
        _isMonitoring = true;
      });

      _showSnackBar('BLE monitoring started', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to start monitoring: $e', Colors.red);
    }
  }

  Future<void> _stopMonitoring() async {
    await _proximityManager.stopMonitoring();
    setState(() {
      _isMonitoring = false;
      _nearbyDevices.clear();
    });
    _showSnackBar('BLE monitoring stopped', Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Monitor'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConfigSection(),
            const SizedBox(height: 20),
            _buildControlSection(),
            const SizedBox(height: 20),
            _buildStatusSection(),
            const SizedBox(height: 20),
            _buildDevicesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetDeviceController,
              decoration: const InputDecoration(
                labelText: 'Target Device ID',
                hintText: 'e.g., pedido_1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'AWS IoT Endpoint',
                hintText: 'your-endpoint.iot.region.amazonaws.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _clientIdController,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAwsConnected ? null : _connectToAws,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAwsConnected ? Colors.green : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isAwsConnected ? 'AWS Connected' : 'Connect AWS'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMonitoring ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isMonitoring ? 'Stop Monitor' : 'Start Monitor'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isAwsConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isAwsConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text('AWS IoT: ${_isAwsConnected ? 'Connected' : 'Disconnected'}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _isMonitoring ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                  color: _isMonitoring ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text('BLE Monitor: ${_isMonitoring ? 'Active' : 'Inactive'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nearby Devices (${_nearbyDevices.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _nearbyDevices.isEmpty
                    ? const Center(
                        child: Text(
                          'No devices found\nStart monitoring to scan for BLE devices',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _nearbyDevices.length,
                        itemBuilder: (context, index) {
                          final device = _nearbyDevices[index];
                          return _buildDeviceCard(device);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BleDeviceModel device) {
    final isClose = device.estimatedDistance <= 1.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.bluetooth,
          color: isClose ? Colors.green : Colors.blue,
        ),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${device.estimatedDistance.toStringAsFixed(2)}m'),
            Text('RSSI: ${device.rssi} dBm'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isClose ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isClose ? 'CLOSE' : 'FAR',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}