// ignore_for_file: all

class DistanceFilter {
  final List<double> _values = [];
  final int _windowSize;
  final double _threshold;
  
  DistanceFilter({
    int windowSize = 5,
    double threshold = 1.0,
  }) : _windowSize = windowSize, _threshold = threshold;
  
  double filter(double newValue) {
    _values.add(newValue);
    if (_values.length > _windowSize) {
      _values.removeAt(0);
    }
    
    // Media móvil simple
    final average = _values.reduce((a, b) => a + b) / _values.length;
    
    // Solo actualizar si el cambio es significativo
    if (_values.length > 1) {
      final lastValue = _values[_values.length - 2];
      if ((newValue - lastValue).abs() < _threshold) {
        return lastValue; // Mantener valor anterior si cambio es menor al threshold
      }
    }
    
    return average;
  }
  
  void clear() {
    _values.clear();
  }
}
