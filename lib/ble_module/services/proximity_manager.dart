import 'dart:async';
import '../models/ble_device_model.dart';
import 'ble_service.dart';
import 'aws_iot_service.dart';

class ProximityManager {
  static final ProximityManager _instance = ProximityManager._internal();
  factory ProximityManager() => _instance;
  ProximityManager._internal();

  final BleService _bleService = BleService();
  final AwsIotService _awsIotService = AwsIotService();
  
  StreamSubscription<BleDeviceModel>? _targetDeviceSubscription;
  Timer? _publishTimer;
  
  // Proximity settings
  double proximityThreshold = 2.0; // meters
  Duration publishInterval = const Duration(seconds: 5);
  
  // State tracking
  final Map<String, bool> _deviceProximityState = {};
  final Map<String, DateTime> _lastPublishTime = {};

  Future<void> startMonitoring({
    required String targetDeviceId,
    double? threshold,
    Duration? interval,
  }) async {
    if (threshold != null) proximityThreshold = threshold;
    if (interval != null) publishInterval = interval;

    // Initialize services
    await _bleService.initialize();
    
    // Start scanning for target device
    await _bleService.startScanning(targetDeviceId: targetDeviceId);
    
    // Listen to target device updates
    _targetDeviceSubscription = _bleService.targetDeviceStream.listen(
      _handleTargetDeviceUpdate,
    );

    // Start periodic publishing
    _publishTimer = Timer.periodic(publishInterval, (_) {
      _publishPeriodicData();
    });

    print('Proximity monitoring started for device: $targetDeviceId');
  }

  void _handleTargetDeviceUpdate(BleDeviceModel device) {
    final deviceId = device.id;
    final distance = device.estimatedDistance;
    final isInProximity = distance <= proximityThreshold;
    final wasInProximity = _deviceProximityState[deviceId] ?? false;

    // Check for proximity state changes
    if (isInProximity && !wasInProximity) {
      _awsIotService.publishProximityEvent(
        deviceId: deviceId,
        eventType: 'entered',
        distance: distance,
        threshold: proximityThreshold,
      );
      print('Device $deviceId entered proximity (${distance.toStringAsFixed(2)}m)');
    } else if (!isInProximity && wasInProximity) {
      _awsIotService.publishProximityEvent(
        deviceId: deviceId,
        eventType: 'exited',
        distance: distance,
        threshold: proximityThreshold,
      );
      print('Device $deviceId exited proximity (${distance.toStringAsFixed(2)}m)');
    }

    // Update state
    _deviceProximityState[deviceId] = isInProximity;
    
    // Publish device data immediately for significant changes
    if (_shouldPublishImmediately(device)) {
      _awsIotService.publishDeviceData(device);
      _lastPublishTime[deviceId] = DateTime.now();
    }
  }

  bool _shouldPublishImmediately(BleDeviceModel device) {
    final lastPublish = _lastPublishTime[device.id];
    if (lastPublish == null) return true;
    
    final timeSinceLastPublish = DateTime.now().difference(lastPublish);
    return timeSinceLastPublish.inSeconds >= 10; // Minimum 10 seconds between immediate publishes
  }

  void _publishPeriodicData() {
    final devices = _bleService.discoveredDevices;
    for (final device in devices) {
      _awsIotService.publishDeviceData(device);
    }
  }

  Future<void> stopMonitoring() async {
    await _targetDeviceSubscription?.cancel();
    _targetDeviceSubscription = null;
    
    _publishTimer?.cancel();
    _publishTimer = null;
    
    await _bleService.stopScanning();
    
    _deviceProximityState.clear();
    _lastPublishTime.clear();
    
    print('Proximity monitoring stopped');
  }

  // Getters for current state
  bool isMonitoring() => _targetDeviceSubscription != null;
  
  Map<String, bool> get deviceProximityStates => Map.from(_deviceProximityState);
  
  List<BleDeviceModel> get nearbyDevices => _bleService.discoveredDevices
      .where((device) => device.estimatedDistance <= proximityThreshold)
      .toList();
}