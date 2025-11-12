// ignore_for_file: all

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_device_model.dart';
import '../utils/distance_filter.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final StreamController<List<BleDeviceModel>> _devicesController = 
      StreamController<List<BleDeviceModel>>.broadcast();
  final StreamController<BleDeviceModel> _targetDeviceController = 
      StreamController<BleDeviceModel>.broadcast();

  Stream<List<BleDeviceModel>> get devicesStream => _devicesController.stream;
  Stream<BleDeviceModel> get targetDeviceStream => _targetDeviceController.stream;

  final List<BleDeviceModel> _discoveredDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  String? _targetDeviceId;
  bool _isScanning = false;
  int _logCounter = 0;
  final Map<String, DistanceFilter> _deviceFilters = {};

  Future<bool> initialize() async {
    try {
      print('[BLE] Starting initialization...');
      
      // Check BLE support
      if (!await FlutterBluePlus.isSupported) {
        print('[BLE] ERROR: BLE not supported on this device');
        throw Exception('BLE not supported on this device');
      }
      print('[BLE] BLE is supported');

      // Request permissions
      print('[BLE] Requesting permissions...');
      await _requestPermissions();
      print('[BLE] Permissions granted');
      
      // Check if Bluetooth is on
      final state = await FlutterBluePlus.adapterState.first;
      print('[BLE] Bluetooth adapter state: $state');
      if (state != BluetoothAdapterState.on) {
        print('[BLE] Turning on Bluetooth...');
        await FlutterBluePlus.turnOn();
      }
      print('[BLE] Bluetooth is ON');

      print('[BLE] Initialization completed successfully');
      return true;
    } catch (e) {
      print('[BLE] Initialization error: $e');
      return false;
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        throw Exception('Permission ${permission.toString()} not granted');
      }
    }
  }

  Future<void> startScanning({String? targetDeviceId}) async {
    if (_isScanning) {
      print('[BLE] Already scanning, ignoring request');
      return;
    }

    print('[BLE] Starting scan for target: ${targetDeviceId ?? "all devices"}');
    _targetDeviceId = targetDeviceId;
    _isScanning = true;
    _discoveredDevices.clear();

    try {
      await FlutterBluePlus.startScan(
        androidUsesFineLocation: true,
      );
      print('[BLE] Scan started successfully');

      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          _processScanResults(results);
        },
        onError: (e) {
          print('[BLE] Scan results stream error: $e');
        },
      );

    } catch (e) {
      print('[BLE] Scan start error: $e');
      _isScanning = false;
    }
  }

  void _processScanResults(List<ScanResult> results) {
    
    for (final result in results) {
      try {
        final device = BleDeviceModel.fromScanResult(result);
        // Update or add device
        final existingIndex = _discoveredDevices.indexWhere(
          (d) => d.id == device.id
        );
        
        if (existingIndex >= 0) {
          _discoveredDevices[existingIndex] = device;
        } else {
          _discoveredDevices.add(device);
        }

        // Check if this is our target device - EMIT EVERY TIME
        if (_targetDeviceId != null) {
          if (device.id.contains(_targetDeviceId!) || 
              device.name.contains(_targetDeviceId!)) {
            // Aplicar filtro de distancia
            final filterId = device.id;
            _deviceFilters[filterId] ??= DistanceFilter(windowSize: 3, threshold: 0.5);
            final filteredDistance = _deviceFilters[filterId]!.filter(device.estimatedDistance);
            
            // Crear device con distancia filtrada
            final filteredDevice = BleDeviceModel(
              id: device.id,
              name: device.name,
              rssi: device.rssi,
              estimatedDistance: filteredDistance,
              lastSeen: device.lastSeen,
              advertisementData: device.advertisementData,
            );
            
            _targetDeviceController.add(filteredDevice);
            // Log solo cada 5 actualizaciones para reducir spam
            if (_logCounter % 5 == 0) {
              print('[BLE] ✅ ${device.name}: ${device.rssi}dBm = ${filteredDistance.toStringAsFixed(1)}m');
            }
            _logCounter++;
          }
        }
      } catch (e) {
        print('[BLE] Error processing scan result: $e');
        // Continue processing other results
        continue;
      }
    }

    _devicesController.add(List.from(_discoveredDevices));
  }

  Future<void> stopScanning() async {
    if (!_isScanning) {
      print('[BLE] Not scanning, nothing to stop');
      return;
    }

    print('[BLE] Stopping scan...');
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    _deviceFilters.clear(); // Limpiar filtros al parar
    print('[BLE] Scan stopped');
  }

  bool get isScanning => _isScanning;

  List<BleDeviceModel> get discoveredDevices => List.from(_discoveredDevices);

  void dispose() {
    stopScanning();
    _devicesController.close();
    _targetDeviceController.close();
  }
}
