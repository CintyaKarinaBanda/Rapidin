// BLE Module - Main export file
// This module provides BLE scanning, distance measurement, and AWS IoT integration

export 'models/ble_device_model.dart';
export 'services/ble_service.dart';
export 'services/aws_iot_service.dart';
export 'services/proximity_manager.dart';
export 'screens/ble_monitor_screen.dart';

// Main BLE Module class for easy integration
class BleModule {
  static const String version = '1.0.0';
  static const String description = 'BLE proximity monitoring with AWS IoT integration';
  
  // Quick access to main services
  static final proximityManager = ProximityManager();
  static final awsIotService = AwsIotService();
  static final bleService = BleService();
  
  // Initialize the entire module
  static Future<bool> initialize({
    String? awsEndpoint,
    String? clientId,
  }) async {
    try {
      // Initialize BLE service
      final bleInitialized = await bleService.initialize();
      if (!bleInitialized) return false;
      
      // Initialize AWS IoT if credentials provided
      if (awsEndpoint != null) {
        final awsInitialized = await awsIotService.initialize(
          endpoint: awsEndpoint,
          clientId: clientId ?? 'rapidin-mobile-${DateTime.now().millisecondsSinceEpoch}',
        );
        if (!awsInitialized) {
          print('Warning: AWS IoT initialization failed, continuing with BLE only');
        }
      }
      
      return true;
    } catch (e) {
      print('BLE Module initialization error: $e');
      return false;
    }
  }
  
  // Quick start monitoring
  static Future<void> startMonitoring(String targetDeviceId) async {
    await proximityManager.startMonitoring(targetDeviceId: targetDeviceId);
  }
  
  // Stop monitoring
  static Future<void> stopMonitoring() async {
    await proximityManager.stopMonitoring();
  }
  
  // Cleanup resources
  static void dispose() {
    proximityManager.stopMonitoring();
    awsIotService.disconnect();
    bleService.dispose();
  }
}