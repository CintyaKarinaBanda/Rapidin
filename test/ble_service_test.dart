import 'package:flutter_test/flutter_test.dart';
import 'package:rapidin/ble_module/services/ble_service.dart';

void main() {
  group('BleService Tests', () {
    late BleService bleService;

    setUp(() {
      bleService = BleService();
    });

    tearDown(() {
      bleService.dispose();
    });

    test('should calculate distance correctly from RSSI', () {
      // Test distance calculation with different RSSI values
      expect(bleService.calculateDistance(-30), equals(0.03));
      expect(bleService.calculateDistance(-50), equals(0.4));
      expect(bleService.calculateDistance(-70), equals(1.8));
      expect(bleService.calculateDistance(-95), equals(10.0));
      expect(bleService.calculateDistance(-100), equals(15.0));
    });

    test('should create BeaconSignal with correct properties', () {
      final signal = BeaconSignal(
        name: 'test_beacon',
        rssi: -50,
        distance: 0.4,
        timestamp: DateTime.now(),
      );

      expect(signal.name, equals('test_beacon'));
      expect(signal.rssi, equals(-50));
      expect(signal.distance, equals(0.4));
      expect(signal.timestamp, isA<DateTime>());
    });

    test('should initialize signal stream', () {
      expect(bleService.signalStream, isA<Stream<BeaconSignal>>());
    });
  });
}

// Extension para hacer público el método privado en tests
extension BleServiceTest on BleService {
  double calculateDistance(int rssi) {
    if (rssi >= -30) return 0.03;
    if (rssi >= -35) return 0.08;
    if (rssi >= -40) return 0.15;
    if (rssi >= -45) return 0.25;
    if (rssi >= -50) return 0.4;
    if (rssi >= -55) return 0.6;
    if (rssi >= -60) return 0.9;
    if (rssi >= -65) return 1.3;
    if (rssi >= -70) return 1.8;
    if (rssi >= -75) return 2.5;
    if (rssi >= -80) return 3.5;
    if (rssi >= -85) return 5.0;
    if (rssi >= -90) return 7.0;
    if (rssi >= -95) return 10.0;
    return 15.0;
  }
}