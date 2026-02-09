import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:flutter/material.dart';

/// A banner that slides down from the top to indicate offline/online status.
/// Wrap any Scaffold body with this widget to show the banner app-wide.
class OfflineStatusBanner extends StatefulWidget {
  final Widget child;
  const OfflineStatusBanner({super.key, required this.child});

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  final ConnectivityService _connectivity = ConnectivityService();
  bool _showBackOnlineBanner = false;

  @override
  void initState() {
    super.initState();
    _connectivity.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    if (_connectivity.justReconnected) {
      _connectivity.clearReconnectedFlag();
      setState(() {
        _showBackOnlineBanner = true;
      });
      // Hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showBackOnlineBanner = false;
          });
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height:
              !_connectivity.isOnline ? 36 : (_showBackOnlineBanner ? 36 : 0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: !_connectivity.isOnline
                ? const Color(0xFFE74C3C)
                : const Color(0xFF27AE60),
            boxShadow: [
              if (!_connectivity.isOnline || _showBackOnlineBanner)
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: AnimatedOpacity(
            opacity:
                !_connectivity.isOnline || _showBackOnlineBanner ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    !_connectivity.isOnline
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    !_connectivity.isOnline
                        ? "You are offline — changes will sync when online"
                        : "Back online — syncing your data...",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}
