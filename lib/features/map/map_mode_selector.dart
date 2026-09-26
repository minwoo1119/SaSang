import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/sasang_theme.dart';
import '../../models/map_models.dart';
import '../../widgets/sasang_ui.dart';

class MapModeSelector extends StatelessWidget {
  const MapModeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final MapMode value;
  final ValueChanged<MapMode> onChanged;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: () => _show(context),
    child: SasangSurface(
      blur: true,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.label,
            style: const TextStyle(
              color: SasangColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            CupertinoIcons.chevron_down,
            size: 14,
            color: SasangColors.secondary,
          ),
        ],
      ),
    ),
  );

  Future<void> _show(BuildContext context) async {
    final selected = await showSasangSheet<MapMode>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD4D4D8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '내 지도',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const Text(
            '보유한 지도',
            style: TextStyle(color: SasangColors.secondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          for (final mode in MapMode.values)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 5),
              onPressed: () => Navigator.pop(context, mode),
              child: SasangSurface(
                radius: 16,
                color: mode == value ? const Color(0xFFF0F7FF) : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Icon(
                      mode == value
                          ? CupertinoIcons.check_mark_circled_solid
                          : CupertinoIcons.circle,
                      color: mode == value
                          ? SasangColors.accent
                          : const Color(0xFFD4D4D8),
                      size: 21,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.label,
                            style: const TextStyle(
                              color: SasangColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mode.description,
                            style: const TextStyle(
                              color: SasangColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/map-store');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.add, size: 18),
                SizedBox(width: 7),
                Text(
                  '새로운 지도 둘러보기',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) onChanged(selected);
  }
}
