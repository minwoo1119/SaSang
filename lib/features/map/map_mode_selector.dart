import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/sasang_theme.dart';
import '../../models/map_models.dart';
import 'map_preview.dart';

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
    child: Container(
      constraints: const BoxConstraints(maxWidth: 168),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: SasangColors.divider, width: .6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF27272A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: Color(0xFF52525B),
          ),
        ],
      ),
    ),
  );

  Future<void> _show(BuildContext context) async {
    final selected = await showModalBottomSheet<MapMode>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .30),
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottom = math
            .max(MediaQuery.paddingOf(sheetContext).bottom, 16)
            .toDouble();
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, 18, 18, bottom),
          decoration: const BoxDecoration(
            color: SasangColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '내 지도',
                          style: TextStyle(
                            color: SasangColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '보유한 지도',
                          style: TextStyle(
                            color: SasangColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFF4F4F5),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 19,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (
                    var index = 0;
                    index < MapMode.values.length;
                    index++
                  ) ...[
                    if (index > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _MapModeCard(
                        mode: MapMode.values[index],
                        selected: MapMode.values[index] == value,
                        onPressed: () =>
                            Navigator.pop(sheetContext, MapMode.values[index]),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        Navigator.pushNamed(context, '/map-store');
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: SasangColors.accent.withValues(alpha: .25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.add, size: 19),
                        SizedBox(width: 6),
                        Text(
                          '새로운 지도 둘러보기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }
}

class _MapModeCard extends StatelessWidget {
  const _MapModeCard({
    required this.mode,
    required this.selected,
    required this.onPressed,
  });

  final MapMode mode;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? SasangColors.accent : SasangColors.divider,
          width: selected ? 1.5 : .6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 82,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MapPreview(mode: mode, selected: selected),
                ),
                if (selected)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: SasangColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.check_mark,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 0),
            child: Text(
              mode.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SasangColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 3, 11, 12),
            child: Text(
              mode.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SasangColors.secondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
