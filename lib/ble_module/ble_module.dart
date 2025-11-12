// ignore_for_file: all


export 'models/ble_device_model.dart';
export 'services/ble_service.dart';
export 'services/proximity_manager.dart';
export 'screens/distance_screen.dart';
export 'screens/ble_monitor_screen.dart';
export 'services/aws_iot_service.dart';

// Main BLE Module class for easy integration
class BleModule {
  static const String version = '1.0.0';
  static const String description = 'BLE proximity monitoring for distance measurement';
  
  // Quick access to main services
  static final proximityManager = ProximityManager();
  static final bleService = BleService();
  static final awsIotService = AwsIotService();
  
  // Initialize the entire module
  static Future<bool> initialize() async {
    try {
      return await bleService.initialize();
    } catch (e) {
      print('BLE Module initialization error: $e');
      return false;
    }
  }
  
  // Quick start monitoring
  static Future<void> startMonitoring({String? targetDevice}) async {
    await proximityManager.startMonitoring(targetDevice: targetDevice ?? 'pedido_1');
  }
  
  // Stop monitoring
  static Future<void> stopMonitoring() async {
    await proximityManager.stopMonitoring();
  }
  
  // Cleanup resources
  static void dispose() {
    proximityManager.dispose();
    bleService.dispose();
    awsIotService.disconnect();
  }
}
