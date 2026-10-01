import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isHardwareConnected = true;
  bool _isSimulatingOffline = false;

  bool get isHardwareConnected => _isHardwareConnected;
  bool get isSimulatingOffline => _isSimulatingOffline;

  /// Effective online status (false if hardware offline OR simulation enabled)
  bool get isOnline => _isHardwareConnected && !_isSimulatingOffline;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  NetworkService._internal() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final connected = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    if (_isHardwareConnected != connected) {
      _isHardwareConnected = connected;
      _controller.add(isOnline);
      notifyListeners();
    }
  }

  /// User action: Toggle simulated offline mode
  void setSimulatedOffline(bool simulateOffline) {
    if (_isSimulatingOffline != simulateOffline) {
      _isSimulatingOffline = simulateOffline;
      _controller.add(isOnline);
      notifyListeners();
    }
  }

  void toggleSimulatedOffline() {
    setSimulatedOffline(!_isSimulatingOffline);
  }

  void disposeService() {
    _subscription?.cancel();
    _controller.close();
  }
}
