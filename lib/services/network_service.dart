import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Initialize network monitoring
  Future<void> initialize() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus([result]);

    // Listen for changes
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus([result]);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // We're online if we have any connection that's not none
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    // Only emit if status changed
    if (wasOnline != _isOnline) {
      _connectionStatusController.add(_isOnline);
      print('Network status changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
    }
  }

  // Manual check
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus([result]);
      return _isOnline;
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
