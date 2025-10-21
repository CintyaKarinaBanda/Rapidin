import 'dart:async';
import 'ble_service.dart';
import '../models/ble_device_model.dart';

class ProximityManager {
  // Singleton
  static final ProximityManager _instance = ProximityManager._internal();
  factory ProximityManager() => _instance;
  ProximityManager._internal();

  final BleService _bleService = BleService();
  StreamSubscription<BleDeviceModel>? _signalSubscription;

  // Configuración
  double proximityThreshold = 2.0; // metros

  // Estados internos
  final Map<String, bool> _deviceProximityState = {};
  final Map<String, double> _lastDistance = {};

  // Callback opcional para eventos externos
  void Function(String deviceName, bool inProximity, double distance)? onProximityChange;

  // Inicia el monitoreo de proximidad
  Future<void> startMonitoring({double? threshold, String? targetDevice}) async {
    if (threshold != null) proximityThreshold = threshold;

    try {
      await _bleService.initialize();
      await _bleService.startScanning(targetDeviceId: targetDevice ?? 'pedido_1');

      _signalSubscription = _bleService.targetDeviceStream.listen(
        _handleSignalUpdate,
        onError: (e) => print('[BLE Error] $e'),
        cancelOnError: false,
      );

      print('[ProximityManager] Monitoreo iniciado con umbral $proximityThreshold m');
    } catch (e) {
      print('[ProximityManager] Error al iniciar monitoreo: $e');
      await stopMonitoring();
    }
  }

  // Detiene el monitoreo
  Future<void> stopMonitoring() async {
    try {
      await _signalSubscription?.cancel();
      _signalSubscription = null;

      await _bleService.stopScanning();
      _deviceProximityState.clear();
      _lastDistance.clear();

      print('[ProximityManager] Monitoreo detenido');
    } catch (e) {
      print('[ProximityManager] Error al detener monitoreo: $e');
    }
  }

  // Indica si el monitoreo está activo
  bool isMonitoring() => _signalSubscription != null;

  // Devuelve una copia del estado actual
  Map<String, bool> get deviceProximityStates => Map.unmodifiable(_deviceProximityState);

  // Manejo de actualización de señal BLE
  void _handleSignalUpdate(BleDeviceModel device) {
    final deviceName = device.name;
    final rawDistance = device.estimatedDistance;

    // Aplica un pequeño suavizado para evitar fluctuaciones
    final smoothedDistance = _smoothDistance(deviceName, rawDistance);

    final isInProximity = smoothedDistance <= proximityThreshold;
    final wasInProximity = _deviceProximityState[deviceName] ?? false;

    // Solo dispara evento si hubo cambio
    if (isInProximity != wasInProximity) {
      if (isInProximity) {
        print('[ProximityManager] ➕ $deviceName entró a proximidad (${smoothedDistance.toStringAsFixed(2)} m)');
      } else {
        print('[ProximityManager] ➖ $deviceName salió de proximidad (${smoothedDistance.toStringAsFixed(2)} m)');
      }
      onProximityChange?.call(deviceName, isInProximity, smoothedDistance);
    }

    _deviceProximityState[deviceName] = isInProximity;
  }

  // Filtro de suavizado exponencial simple
  double _smoothDistance(String name, double newDistance) {
    const alpha = 0.5; // peso del nuevo valor (0 = suave, 1 = inmediato)
    final prev = _lastDistance[name] ?? newDistance;
    final smoothed = alpha * newDistance + (1 - alpha) * prev;
    _lastDistance[name] = smoothed;
    return smoothed;
  }
}
