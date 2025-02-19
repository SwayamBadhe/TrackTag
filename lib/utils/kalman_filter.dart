// lib/services/kalman_filter.dart
class KalmanFilter {
  double _estimate = 0;
  double _errorEstimate = 1;
  final double _q = 0.1; // Process noise
  final double _r = 1; // Measurement noise

  double update(double measurement) {
    // Prediction
    double errorEstimate = _errorEstimate + _q;
    
    // Update
    double kalmanGain = errorEstimate / (errorEstimate + _r);
    _estimate += kalmanGain * (measurement - _estimate);
    _errorEstimate = (1 - kalmanGain) * errorEstimate;
    
    return _estimate;
  }
  
   double get latestValue => _estimate;
}
