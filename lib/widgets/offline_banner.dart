import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkConnectivity());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      // Hit our own backend instead of google.com to avoid CORS issues and check actual availability
      final response = await http.get(Uri.parse(ApiConfig.baseUrl.replaceAll('/api', '/up'))).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        if (_isOffline) setState(() => _isOffline = false);
      } else {
        // Even if it's not 200, if we got a response, we're technically online
        if (_isOffline) setState(() => _isOffline = false);
      }
    } catch (_) {
      if (!_isOffline) setState(() => _isOffline = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.red[800],
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
          SizedBox(width: 8),
          Text(
            'Offline Mode - Some features may be limited',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
