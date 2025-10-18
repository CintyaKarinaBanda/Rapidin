// BLE Module - Simple BLE signal receiver

export 'services/ble_service.dart';
export 'screens/ble_screen.dart';

class BleModule {
  static final bleService = BleService();

  static Future<bool> initialize() async {
    return await bleService.initialize();
  }

  static Future<void> startScanning() async {
    await bleService.startScanning();
  }

  static Future<void> stopScanning() async {
    await bleService.stopScanning();
  }

  static void dispose() {
    bleService.dispose();
  }
}
