import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  static Future<bool> hasNetworkConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static Future<bool> ensureConnected(
    BuildContext context, {
    String actionDescription = 'perform this action',
    bool popCurrentRouteOnFailure = false,
  }) async {
    final isConnected = await hasNetworkConnection();
    if (isConnected) {
      return true;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          'You are offline. Connect to the internet to $actionDescription.',
        ),
      ),
    );

    if (popCurrentRouteOnFailure) {
      Navigator.of(context).maybePop();
    }

    return false;
  }
}
