import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Singleton service that monitors network connectivity throughout the app.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Whether we just came back online from an offline state.
  bool _justReconnected = false;
  bool get justReconnected => _justReconnected;

  void clearReconnectedFlag() {
    _justReconnected = false;
  }

  void _init() {
    // Check initial connectivity
    _connectivity.checkConnectivity().then((results) {
      _updateStatus(results);
    });

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _updateStatus(results);
      if (wasOffline && _isOnline) {
        _justReconnected = true;
      }
      notifyListeners();
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    _isOnline = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
