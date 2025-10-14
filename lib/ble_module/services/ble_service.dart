import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ble_device_model.dart';

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

  Future<bool> initialize() async {
    try {
      // Check BLE support
      if (!await FlutterBluePlus.isSupported) {
        throw Exception('BLE not supported on this device');
      }

      // Request permissions
      await _requestPermissions();
      
      // Check if Bluetooth is on
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      return true;
    } catch (e) {
      print('BLE initialization error: $e');
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
    if (_isScanning) return;

    _targetDeviceId = targetDeviceId;
    _isScanning = true;
    _discoveredDevices.clear();

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _processScanResults(results);
      });

    } catch (e) {
      print('Scan error: $e');
      _isScanning = false;
    }
  }

  void _processScanResults(List<ScanResult> results) {
    for (final result in results) {
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

      // Check if this is our target device
      if (_targetDeviceId != null && 
          (device.id.contains(_targetDeviceId!) || 
           device.name.contains(_targetDeviceId!))) {
        _targetDeviceController.add(device);
      }
    }

    _devicesController.add(List.from(_discoveredDevices));
  }

  Future<void> stopScanning() async {
    if (!_isScanning) return;

    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
  }

  bool get isScanning => _isScanning;

  List<BleDeviceModel> get discoveredDevices => List.from(_discoveredDevices);

  void dispose() {
    stopScanning();
    _devicesController.close();
    _targetDeviceController.close();
  }
}