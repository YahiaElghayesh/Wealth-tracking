import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../../core/debug/debug_log.dart';
import '../../../core/theme/app_colors.dart';

/// Read-only view of [AppDebugLog]'s captured breadcrumbs -- built
/// specifically so a user hitting a real-device-only bug in Quick Add /
/// notification tapping can copy exactly what happened on their own phone
/// and send it back, without needing `adb logcat`, a computer, or USB
/// debugging at all. Not a general-purpose developer console: it shows
/// nothing more than the same `debugPrint` breadcrumbs already scattered
/// through the SMS/Quick Add code, just made visible from the device that
/// actually hit the bug.
class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  List<String>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await AppDebugLog.readAll();
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _copyAll() async {
    final entries = _entries ?? const [];
    // Oldest first when copied out, even though newest-first is how this
    // screen displays them -- a log read top-to-bottom should read the
    // same direction events actually happened in.
    await Clipboard.setData(
      ClipboardData(text: entries.reversed.join('\n')),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${entries.length} line(s)')),
    );
  }

  Future<void> _clear() async {
    await AppDebugLog.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug log'),
        actions: [
          IconButton(
            onPressed: (entries == null || entries.isEmpty) ? null : _copyAll,
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Copy all',
          ),
          IconButton(
            onPressed: (entries == null || entries.isEmpty) ? null : _clear,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nothing logged yet. Trigger the thing you\'re testing '
                '(send/simulate a bank text, tap Quick add or the '
                'notification), then come back here and refresh.',
                style: TextStyle(color: colors.textDim),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, index) => Text(
                entries[index],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
    );
  }
}
