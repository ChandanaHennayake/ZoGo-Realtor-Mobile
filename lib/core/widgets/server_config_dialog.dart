import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  static const Color slateBg = Color(0xFF0A0D14);
  static const Color cardDark = Color(0xFF161B26);
  static const Color primaryCyan = Color(0xFF00C6D4);

  late TextEditingController _urlController;
  final _formKey = GlobalKey<FormState>();

  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  static const List<Map<String, String>> presets = [
    {
      'label': 'Physical Device / Wi-Fi',
      'url': 'http://192.168.0.200:5000',
      'desc': 'For physical phones on local LAN',
    },
    {
      'label': 'Android Emulator',
      'url': 'http://10.0.2.2:5000',
      'desc': 'Standard loopback for Android Virtual Device',
    },
    {
      'label': 'Localhost / Desktop',
      'url': 'http://127.0.0.1:5000',
      'desc': 'For Windows desktop or iOS simulator',
    },
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConstants.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Please enter a valid HTTP or HTTPS URL.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          validateStatus: (_) => true,
        ),
      );

      final response = await dio.get('/api/Auth/login');
      stopwatch.stop();

      setState(() {
        _isTesting = false;
        _testSuccess = true;
        _testResult = 'Connected successfully (${stopwatch.elapsedMilliseconds}ms) [HTTP ${response.statusCode}]';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Connection failed: Host unreachable (${stopwatch.elapsedMilliseconds}ms). Check server & IP.';
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final targetUrl = _urlController.text.trim();
    await ApiConstants.setBaseUrl(targetUrl);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server URL set to: $targetUrl'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, color: primaryCyan, size: 24),
          SizedBox(width: 10),
          Text(
            'API Server Switcher',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Switch the backend server endpoint for testing across physical devices, emulators, or local environments without recompilation:',
                style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Presets
              const Text(
                'ENVIRONMENT PRESETS',
                style: TextStyle(color: primaryCyan, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              ...presets.map((p) {
                final isCurrent = _urlController.text.trim() == p['url'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isCurrent ? primaryCyan.withValues(alpha: 0.12) : slateBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent ? primaryCyan.withValues(alpha: 0.5) : Colors.white10,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    title: Text(
                      p['label']!,
                      style: TextStyle(
                        color: isCurrent ? primaryCyan : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      '${p['url']} • ${p['desc']}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle_rounded, color: primaryCyan, size: 16)
                        : null,
                    onTap: () {
                      setState(() {
                        _urlController.text = p['url']!;
                        _testResult = null;
                        _testSuccess = null;
                      });
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),

              // Custom Input
              const Text(
                'SERVER BASE URL',
                style: TextStyle(color: primaryCyan, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'http://192.168.0.200:5000',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: slateBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryCyan)),
                  suffixIcon: IconButton(
                    tooltip: 'Test Connection',
                    icon: _isTesting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryCyan))
                        : const Icon(Icons.wifi_find_rounded, color: primaryCyan, size: 20),
                    onPressed: _isTesting ? null : _testConnection,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'URL cannot be empty';
                  if (!val.trim().startsWith('http://') && !val.trim().startsWith('https://')) {
                    return 'URL must begin with http:// or https://';
                  }
                  return null;
                },
              ),

              // Test Result Tag
              if (_testResult != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_testSuccess == true ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_testSuccess == true ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess == true ? Icons.check_circle_rounded : Icons.cancel_outlined,
                        size: 14,
                        color: _testSuccess == true ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _testSuccess == true ? const Color(0xFF10B981) : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryCyan,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
