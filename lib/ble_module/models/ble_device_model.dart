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
    return BleDeviceModel(
      id: scanResult.device.remoteId.toString(),
      name: scanResult.device.platformName.isNotEmpty 
          ? scanResult.device.platformName 
          : 'Unknown Device',
      rssi: scanResult.rssi,
      estimatedDistance: _calculateDistance(scanResult.rssi),
      lastSeen: DateTime.now(),
      advertisementData: scanResult.advertisementData.manufacturerData,
    );
  }

  static double _calculateDistance(int rssi) {
    if (rssi == 0) return -1.0;
    
    double ratio = ((-69) - rssi) / 20.0;
    if (ratio < 1.0) {
      return ratio;
    } else {
      double accuracy = (0.89976) * (ratio * ratio * ratio) + 
                       (7.7095) * (ratio * ratio) + 
                       (0.111) * ratio;
      return accuracy;
    }
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