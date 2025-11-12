// ignore_for_file: all
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ble_device_model.dart';
import '../services/ble_service.dart';

class DistanceScreen extends StatefulWidget {
  const DistanceScreen({Key? key}) : super(key: key);

  @override
  State<DistanceScreen> createState() => _DistanceScreenState();
}

class _DistanceScreenState extends State<DistanceScreen> {
  final BleService _bleService = BleService();
  StreamSubscription<BleDeviceModel>? _deviceSubscription;
  
  BleDeviceModel? _targetDevice;
  bool _isScanning = false;
  String _status = 'Inicializando...';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _startContinuousMonitoring();
  }

  Future<void> _startContinuousMonitoring() async {
    print('[DistanceScreen] Starting continuous monitoring...');
    
    setState(() {
      _status = 'Inicializando BLE...';
    });

    print('[DistanceScreen] Initializing BLE service...');
    final initialized = await _bleService.initialize();
    if (!initialized) {
      print('[DistanceScreen] BLE initialization failed');
      setState(() {
        _status = 'Error: BLE no disponible';
      });
      return;
    }
    print('[DistanceScreen] BLE initialized successfully');

    setState(() {
      _status = 'Buscando pedido_1...';
      _isScanning = true;
    });

    print('[DistanceScreen] Starting scan for pedido_1...');
    await _bleService.startScanning(targetDeviceId: 'pedido_1');
    
    print('[DistanceScreen] Setting up device stream listener...');
    _deviceSubscription = _bleService.targetDeviceStream.listen(
      (device) {
        print('[DistanceScreen] ✅ Received device update - ${device.name} at ${device.estimatedDistance.toStringAsFixed(2)}m');
        setState(() {
          _targetDevice = device;
          _status = 'Conectado - Actualizando...';
        });
      },
      onError: (e) {
        print('[DistanceScreen] ❌ Stream error: $e');
        setState(() {
          _status = 'Error: $e';
        });
      },
    );
    print('[DistanceScreen] Stream listener set up, waiting for devices...');
  }

  Future<void> _refreshDistance() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
      _status = 'Actualizando distancia...';
    });
    
    print('[DistanceScreen] 🔄 Manual refresh requested');
    
    try {
      // Reiniciar el escaneo para obtener lectura fresca
      await _bleService.stopScanning();
      await Future.delayed(const Duration(milliseconds: 500));
      await _bleService.startScanning(targetDeviceId: 'pedido_1');
      
      // Esperar un momento para nueva lectura
      await Future.delayed(const Duration(seconds: 2));
      
      print('[DistanceScreen] ✅ Manual refresh completed');
    } catch (e) {
      print('[DistanceScreen] ❌ Refresh error: $e');
      setState(() {
        _status = 'Error al actualizar: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
        if (_targetDevice != null) {
          _status = 'Conectado - Actualizando...';
        }
      });
    }
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distancia del Pedido'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_targetDevice != null)
            IconButton(
              onPressed: _isRefreshing ? null : _refreshDistance,
              icon: _isRefreshing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Actualizar distancia',
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _targetDevice != null 
              ? _buildDistanceDisplay() 
              : _buildSearchingDisplay(),
        ),
      ),
    );
  }

  Widget _buildSearchingDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isScanning) ...[
          const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 24),
        ],
        Icon(
          _isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
          size: 64,
          color: _isScanning ? Colors.orange : Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          _status,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDistanceDisplay() {
    final device = _targetDevice!;
    final distance = device.estimatedDistance;
    final rssi = device.rssi;
    
    Color distanceColor;
    String proximityText;
    IconData proximityIcon;
    
    if (distance < 1.0) {
      distanceColor = Colors.green;
      proximityText = 'MUY CERCA';
      proximityIcon = Icons.location_on;
    } else if (distance < 3.0) {
      distanceColor = Colors.orange;
      proximityText = 'CERCA';
      proximityIcon = Icons.location_on;
    } else {
      distanceColor = Colors.red;
      proximityText = 'LEJOS';
      proximityIcon = Icons.location_off;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icono de proximidad
        Icon(
          proximityIcon,
          size: 80,
          color: distanceColor,
        ),
        const SizedBox(height: 24),
        
        // Distancia principal
        Text(
          '${distance.toStringAsFixed(1)}m',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: distanceColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Estado de proximidad
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: distanceColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            proximityText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Información técnica
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dispositivo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(device.name),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RSSI:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${rssi} dBm'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Última actualización:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(device.lastSeen.toString().substring(11, 19)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Botón de actualizar manual
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _refreshDistance,
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(_isRefreshing ? 'Actualizando...' : 'Actualizar Distancia'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
