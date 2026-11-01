import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to monitor internet and backend connectivity throughout the application.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  static ConnectivityService get instance => _instance;

  ConnectivityService._internal();

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Timer? _pollingTimer;
  bool _isChecking = false;

  bool get isOnline => isOnlineNotifier.value;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Starts background heartbeat to monitor connectivity.
  void startMonitoring({Duration interval = const Duration(seconds: 8)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => checkConnection());
    // Initial check
    checkConnection();
  }

  /// Stops background polling.
  void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Actively checks whether internet connection is reachable.
  Future<bool> checkConnection() async {
    if (_isChecking) return isOnline;
    _isChecking = true;

    bool connected = false;
    try {
      // 1. Try DNS lookup to google.com
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        connected = true;
      }
    } catch (_) {
      try {
        // 2. Fallback direct socket test to Cloudflare DNS 1.1.1.1 port 53
        final socket = await Socket.connect(
          '1.1.1.1',
          53,
          timeout: const Duration(seconds: 3),
        );
        socket.destroy();
        connected = true;
      } catch (_) {
        connected = false;
      }
    } finally {
      _isChecking = false;
    }

    _updateStatus(connected);
    return connected;
  }

  /// Manually mark offline when an API call fails with network/socket error.
  void notifyOffline() {
    _updateStatus(false);
  }

  /// Manually mark online when an API call succeeds.
  void notifyOnline() {
    _updateStatus(true);
  }

  void _updateStatus(bool connected) {
    if (isOnlineNotifier.value != connected) {
      isOnlineNotifier.value = connected;
      _controller.add(connected);
      debugPrint('[ConnectivityService] Connection status changed: ${connected ? "ONLINE" : "OFFLINE"}');
    }
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
    isOnlineNotifier.dispose();
  }
}
