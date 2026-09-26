import 'package:flutter/material.dart';

import '../../core/theme/sasang_theme.dart';
import '../../models/map_models.dart';

class MapModeSelector extends StatelessWidget {
  const MapModeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final MapMode value;
  final ValueChanged<MapMode> onChanged;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => _show(context),
    iconAlignment: IconAlignment.end,
    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
    label: Text(value.label, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      foregroundColor: SasangColors.ink,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      side: const BorderSide(color: SasangColors.divider),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    ),
  );

  Future<void> _show(BuildContext context) async {
    final selected = await showModalBottomSheet<MapMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '내 지도',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const Text(
                '보유한 지도',
                style: TextStyle(color: SasangColors.secondary),
              ),
              const SizedBox(height: 14),
              for (final mode in MapMode.values)
                ListTile(
                  leading: Icon(
                    mode == value
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: mode == value
                        ? SasangColors.accent
                        : SasangColors.secondary,
                  ),
                  onTap: () => Navigator.pop(context, mode),
                  title: Text(
                    mode.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(mode.description),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add, color: SasangColors.accent),
                title: const Text(
                  '새로운 지도 둘러보기',
                  style: TextStyle(
                    color: SasangColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/map-store');
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }
}
