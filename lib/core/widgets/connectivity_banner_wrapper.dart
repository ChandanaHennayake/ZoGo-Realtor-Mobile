import 'dart:async';
import 'package:flutter/material.dart';
import '../network/connectivity_service.dart';

/// Top-level overlay wrapper that alerts the user when the device loses internet connectivity.
class ConnectivityBannerWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityBannerWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityBannerWrapper> createState() => _ConnectivityBannerWrapperState();
}

class _ConnectivityBannerWrapperState extends State<ConnectivityBannerWrapper> {
  final ConnectivityService _connectivity = ConnectivityService.instance;
  bool _isOnline = true;
  bool _showRestoredBanner = false;
  Timer? _restoredDismissTimer;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivity.isOnline;
    _connectivity.isOnlineNotifier.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _restoredDismissTimer?.cancel();
    _connectivity.isOnlineNotifier.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    final nowOnline = _connectivity.isOnline;
    if (_isOnline == false && nowOnline == true) {
      // Transition from offline to online
      setState(() {
        _isOnline = true;
        _showRestoredBanner = true;
      });
      _restoredDismissTimer?.cancel();
      _restoredDismissTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showRestoredBanner = false;
          });
        }
      });
    } else {
      setState(() {
        _isOnline = nowOnline;
        if (!_isOnline) {
          _showRestoredBanner = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isOnline || _showRestoredBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: !_isOnline
                    ? _buildOfflineBanner()
                    : _buildRestoredBanner(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      key: const ValueKey('offline_banner'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1412).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Please check your network. Some features may be offline.',
                    style: TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                final ok = await _connectivity.checkConnection();
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Still offline. Please check Wi-Fi or Mobile Data.'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00C6D4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoredBanner() {
    return Container(
      key: const ValueKey('online_banner'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF06231A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wifi_rounded, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Text(
              'Internet Connection Restored',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

