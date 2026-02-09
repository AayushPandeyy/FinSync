import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:flutter/material.dart';

/// Tracks whether local Firestore cache has pending writes (unsynced data).
/// Works with Firebase's built-in offline persistence.
class SyncStatusService extends ChangeNotifier {
  static final SyncStatusService _instance = SyncStatusService._internal();
  factory SyncStatusService() => _instance;

  SyncStatusService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  bool _hasPendingWrites = false;
  bool get hasPendingWrites => _hasPendingWrites;

  bool _isSynced = true;
  bool get isSynced => _isSynced;

  bool _wasSyncedAfterReconnect = false;
  bool get wasSyncedAfterReconnect => _wasSyncedAfterReconnect;

  Timer? _syncCheckTimer;
  final List<StreamSubscription> _subscriptions = [];

  /// Initialize sync monitoring for a given user's collections.
  void startMonitoring(String uid) {
    stopMonitoring();

    // Monitor all user collections for pending writes
    _monitorCollection(
      FirebaseFirestore.instance
          .collection('Transactions')
          .doc(uid)
          .collection('transaction'),
    );
    _monitorCollection(
      FirebaseFirestore.instance
          .collection('Budgets')
          .doc(uid)
          .collection('budgets'),
    );
    _monitorCollection(
      FirebaseFirestore.instance
          .collection('Goals')
          .doc(uid)
          .collection('goal'),
    );
    _monitorCollection(
      FirebaseFirestore.instance.collection('IOUs').doc(uid).collection('iou'),
    );
    _monitorCollection(
      FirebaseFirestore.instance
          .collection('Users')
          .where('uid', isEqualTo: uid),
    );

    // Periodic check to update sync state
    _syncCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _evaluateSyncStatus();
    });
  }

  void _monitorCollection(Query query) {
    final sub =
        query.snapshots(includeMetadataChanges: true).listen((snapshot) {
      final hasPending =
          snapshot.docs.any((doc) => doc.metadata.hasPendingWrites);
      if (hasPending != _hasPendingWrites) {
        _hasPendingWrites = hasPending;
        _evaluateSyncStatus();
      }
    });
    _subscriptions.add(sub);
  }

  void _evaluateSyncStatus() {
    final online = _connectivityService.isOnline;
    final wasSynced = _isSynced;

    if (!online) {
      // Offline → always show as unsynced
      _isSynced = false;
      _wasSyncedAfterReconnect = false;
    } else if (_hasPendingWrites) {
      // Online but there are pending writes → not yet synced
      _isSynced = false;
      _wasSyncedAfterReconnect = false;
    } else {
      // Online and no pending writes → synced
      _isSynced = true;
      if (!wasSynced) {
        _wasSyncedAfterReconnect = true;
        // Auto-clear the "just synced" flag after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          _wasSyncedAfterReconnect = false;
          notifyListeners();
        });
      }
    }
    notifyListeners();
  }

  void stopMonitoring() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _syncCheckTimer?.cancel();
    _syncCheckTimer = null;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
