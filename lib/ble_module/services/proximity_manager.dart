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
  final Map<String, BleDeviceModel> _currentDevices = {};

  // Stream controller para dispositivos
  final StreamController<List<BleDeviceModel>> _devicesController = 
      StreamController<List<BleDeviceModel>>.broadcast();

  // Stream público para dispositivos
  Stream<List<BleDeviceModel>> get devicesStream => _devicesController.stream;
  List<BleDeviceModel> get nearbyDevices => _currentDevices.values.toList();

  // Callback opcional para eventos externos
  void Function(String deviceName, bool inProximity, double distance)? onProximityChange;

  // Inicia el monitoreo de proximidad
  Future<void> startMonitoring({double? threshold, String? targetDevice, String? targetDeviceId, Duration? interval}) async {
    if (threshold != null) proximityThreshold = threshold;
    final target = targetDeviceId ?? targetDevice ?? 'pedido_1';

    print('[ProximityManager] Starting monitoring for: $target with threshold: $proximityThreshold m');

    try {
      print('[ProximityManager] Initializing BLE service...');
      await _bleService.initialize();
      
      print('[ProximityManager] Starting scan for target: $target');
      await _bleService.startScanning(targetDeviceId: target);

      print('[ProximityManager] Setting up stream listener...');
      _signalSubscription = _bleService.targetDeviceStream.listen(
        (device) {
          print('[ProximityManager] Received device signal: ${device.name} at ${device.estimatedDistance}m');
          _handleSignalUpdate(device);
        },
        onError: (e) => print('[ProximityManager] Stream error: $e'),
        cancelOnError: false,
      );

      print('[ProximityManager] ✅ Monitoring started successfully');
    } catch (e) {
      print('[ProximityManager] ❌ Error starting monitoring: $e');
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
      _currentDevices.clear();
      
      // Emitir lista vacía
      _devicesController.add([]);

      print('[ProximityManager] Monitoreo detenido');
    } catch (e) {
      print('[ProximityManager] Error al detener monitoreo: $e');
    }
  }

  // Dispose resources
  void dispose() {
    stopMonitoring();
    _devicesController.close();
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

    // Crear device actualizado con distancia suavizada
    final updatedDevice = BleDeviceModel(
      id: device.id,
      name: device.name,
      rssi: device.rssi,
      estimatedDistance: smoothedDistance,
      lastSeen: DateTime.now(),
      advertisementData: device.advertisementData,
    );

    // Actualizar dispositivo actual
    _currentDevices[device.id] = updatedDevice;
    
    // Emitir lista actualizada
    _devicesController.add(_currentDevices.values.toList());

    final isInProximity = smoothedDistance <= proximityThreshold;
    final wasInProximity = _deviceProximityState[deviceName] ?? false;

    // SIEMPRE dispara evento para actualizaciones continuas
    if (isInProximity != wasInProximity) {
      if (isInProximity) {
        print('[ProximityManager] ➕ $deviceName entró a proximidad (${smoothedDistance.toStringAsFixed(1)} m)');
      } else {
        print('[ProximityManager] ➖ $deviceName salió de proximidad (${smoothedDistance.toStringAsFixed(1)} m)');
      }
    }
    
    // Llamar SIEMPRE para actualizaciones continuas de distancia
    onProximityChange?.call(deviceName, isInProximity, smoothedDistance);
    _deviceProximityState[deviceName] = isInProximity;
  }

  // Filtro de suavizado mejorado con detección de saltos
  double _smoothDistance(String name, double newDistance) {
    const alpha = 0.2; // Más suave (era 0.3)
    const maxJump = 2.0; // Máximo salto permitido en metros
    
    final prev = _lastDistance[name] ?? newDistance;
    
    // Detectar saltos extremos y rechazarlos
    if ((newDistance - prev).abs() > maxJump && _lastDistance.containsKey(name)) {
      print('[ProximityManager] ⚠️ Salto extremo detectado: ${prev.toStringAsFixed(1)}m -> ${newDistance.toStringAsFixed(1)}m, ignorando');
      return prev; // Mantener valor anterior
    }
    
    final smoothed = alpha * newDistance + (1 - alpha) * prev;
    _lastDistance[name] = smoothed;
    return smoothed;
  }
}
