import 'dart:math' as math;

class BleDeviceModel {
  final String id;
  final String name;
  final int rssi;
  final double estimatedDistance;
  final DateTime lastSeen;
  final Map<String, dynamic>? advertisementData;

  BleDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    required this.estimatedDistance,
    required this.lastSeen,
    this.advertisementData,
  });

  factory BleDeviceModel.fromScanResult(dynamic scanResult) {
    // Convert manufacturerData from Map<int, List<int>> to Map<String, dynamic>
    Map<String, dynamic>? convertedData;
    try {
      final manufacturerData = scanResult.advertisementData.manufacturerData;
      if (manufacturerData != null && manufacturerData.isNotEmpty) {
        convertedData = {};
        manufacturerData.forEach((key, value) {
          convertedData![key.toString()] = value;
        });
      }
    } catch (e) {
      // If conversion fails, just use null
      convertedData = null;
    }

    return BleDeviceModel(
      id: scanResult.device.remoteId.toString(),
      name: scanResult.device.platformName.isNotEmpty 
          ? scanResult.device.platformName 
          : 'Unknown Device',
      rssi: scanResult.rssi,
      estimatedDistance: _calculateDistance(scanResult.rssi),
      lastSeen: DateTime.now(),
      advertisementData: convertedData,
    );
  }

  // Tabla de calibración personalizable
  static const Map<int, double> _calibrationTable = {
    -45: 0.1,  // Muy muy cerca
    -50: 0.2,  // Pegado
    -55: 0.4,  // Muy cerca
    -60: 0.8,  // Cerca
    -65: 1.5,  // 1.5m
    -70: 2.5,  // 2.5m
    -75: 4.0,  // 4m
    -80: 6.0,  // 6m
    -85: 10.0, // 10m
    -90: 15.0, // 15m+
  };

  static double _calculateDistance(int rssi) {
    if (rssi == 0) return -1.0;
    
    // Buscar el rango más cercano en la tabla de calibración
    int closestRssi = -90;
    int minDiff = 1000;
    
    for (int calibRssi in _calibrationTable.keys) {
      int diff = (rssi - calibRssi).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestRssi = calibRssi;
      }
    }
    
    // Interpolación lineal para mayor precisión
    List<int> sortedKeys = _calibrationTable.keys.toList()..sort();
    
    for (int i = 0; i < sortedKeys.length - 1; i++) {
      int rssi1 = sortedKeys[i];
      int rssi2 = sortedKeys[i + 1];
      
      if (rssi >= rssi1 && rssi <= rssi2) {
        double dist1 = _calibrationTable[rssi1]!;
        double dist2 = _calibrationTable[rssi2]!;
        
        // Interpolación lineal
        double ratio = (rssi - rssi1) / (rssi2 - rssi1);
        return dist1 + (dist2 - dist1) * ratio;
      }
    }
    
    return _calibrationTable[closestRssi] ?? 10.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': id,
      'device_name': name,
      'rssi': rssi,
      'estimated_distance': estimatedDistance,
      'timestamp': lastSeen.toIso8601String(),
      'advertisement_data': advertisementData,
    };
  }
}