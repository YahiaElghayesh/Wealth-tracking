import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/widget/home_widget_service.dart';
import '../../networth/providers/home_widget_providers.dart';

class WidgetAppearanceSettingsScreen extends ConsumerStatefulWidget {
  const WidgetAppearanceSettingsScreen({super.key});

  @override
  ConsumerState<WidgetAppearanceSettingsScreen> createState() => _WidgetAppearanceSettingsScreenState();
}

class _WidgetAppearanceSettingsScreenState extends ConsumerState<WidgetAppearanceSettingsScreen> {
  String _preset = 'default';
  double _opacityPercent = HomeWidgetService.defaultBackgroundOpacity.toDouble();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(homeWidgetServiceProvider);
    final preset = await service.loadBackgroundPreset();
    final opacity = await service.loadBackgroundOpacity();
    if (mounted) {
      setState(() {
        _preset = preset;
        _opacityPercent = opacity.toDouble();
        _loaded = true;
      });
    }
  }

  Future<void> _setPreset(String preset) async {
    setState(() => _preset = preset);
    await ref.read(homeWidgetServiceProvider).setBackgroundPreset(preset);
  }

  Future<void> _setOpacity(double percent) async {
    setState(() => _opacityPercent = percent);
    await ref.read(homeWidgetServiceProvider).setBackgroundOpacity(percent.round());
  }

  static const _presetColors = {
    'default': Color(0xFF2E7D6B),
    'blue': Color(0xFF1565C0),
    'purple': Color(0xFF6A1B9A),
    'amber': Color(0xFFFF8F00),
    'charcoal': Color(0xFF263238),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget appearance')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Applies to both home-screen widgets.'),
                const SizedBox(height: 16),
                Text('Color', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: HomeWidgetService.backgroundPresets.map((preset) {
                    final selected = preset == _preset;
                    return InkWell(
                      onTap: () => _setPreset(preset),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _presetColors[preset],
                          border: Border.all(
                            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text('Opacity', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${_opacityPercent.round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Slider(
                  value: _opacityPercent,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_opacityPercent.round()}%',
                  onChanged: (v) => setState(() => _opacityPercent = v),
                  onChangeEnd: _setOpacity,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 160,
                    height: 90,
                    decoration: BoxDecoration(
                      color: (_presetColors[_preset] ?? _presetColors['default']!)
                          .withValues(alpha: _opacityPercent / 100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Preview'),
                  ),
                ),
              ],
            ),
    );
  }
}
