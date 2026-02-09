import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/SyncStatusService.dart';
import 'package:flutter/material.dart';

/// A small sync status icon for the AppBar that shows:
/// - Green cloud_done when data is fully synced
/// - Red cloud_upload when there are pending writes / offline
/// - Animated spin when syncing in progress (just came online)
class SyncStatusIcon extends StatefulWidget {
  const SyncStatusIcon({super.key});

  @override
  State<SyncStatusIcon> createState() => _SyncStatusIconState();
}

class _SyncStatusIconState extends State<SyncStatusIcon>
    with SingleTickerProviderStateMixin {
  final SyncStatusService _syncService = SyncStatusService();
  final ConnectivityService _connectivityService = ConnectivityService();
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _syncService.addListener(_onSyncChanged);
    _connectivityService.addListener(_onSyncChanged);
  }

  void _onSyncChanged() {
    if (!mounted) return;
    setState(() {});
    if (_syncService.wasSyncedAfterReconnect) {
      _spinController.stop();
    } else if (!_syncService.isSynced && _connectivityService.isOnline) {
      // Syncing in progress
      _spinController.repeat();
    } else {
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncChanged);
    _connectivityService.removeListener(_onSyncChanged);
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _connectivityService.isOnline;
    final isSynced = _syncService.isSynced;
    final justSynced = _syncService.wasSyncedAfterReconnect;

    IconData icon;
    Color color;
    String tooltip;

    if (!isOnline) {
      icon = Icons.cloud_off_rounded;
      color = const Color(0xFFE74C3C);
      tooltip = "Offline — changes saved locally";
    } else if (!isSynced) {
      icon = Icons.cloud_upload_rounded;
      color = const Color(0xFFE67E22);
      tooltip = "Syncing data...";
    } else if (justSynced) {
      icon = Icons.cloud_done_rounded;
      color = const Color(0xFF27AE60);
      tooltip = "All data synced!";
    } else {
      icon = Icons.cloud_done_rounded;
      color = const Color(0xFF27AE60);
      tooltip = "Data is up to date";
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: !isSynced && isOnline
              ? RotationTransition(
                  key: const ValueKey('syncing'),
                  turns: _spinController,
                  child: Icon(Icons.sync_rounded, color: color, size: 22),
                )
              : Icon(icon, key: ValueKey(icon), color: color, size: 22),
        ),
      ),
    );
  }
}
