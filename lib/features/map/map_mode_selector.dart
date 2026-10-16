import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/sasang_theme.dart';
import '../../models/map_models.dart';

class MapModeSelector extends StatelessWidget {
  const MapModeSelector({
    required this.value,
    required this.onChanged,
    super.key,
    this.elevated = false,
  });

  final MapMode value;
  final ValueChanged<MapMode> onChanged;
  final bool elevated;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: () => _show(context),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 168),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: elevated ? .94 : .92),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: elevated ? SasangOverlayStyle.border : SasangColors.divider,
          width: .6,
        ),
        boxShadow: elevated ? SasangOverlayStyle.shadows : null,
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
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      final selected = await showCupertinoModalPopup<MapMode>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: const Text('지도 선택'),
          actions: [
            for (final mode in MapMode.values)
              CupertinoActionSheetAction(
                key: Key('map-mode-option-${mode.storageKey}'),
                isDefaultAction: mode == value,
                onPressed: () => Navigator.pop(sheetContext, mode),
                child: Text(mode.label),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('취소'),
          ),
        ),
      );
      if (selected != null) onChanged(selected);
      return;
    }
    final selected = await showModalBottomSheet<MapMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in MapMode.values)
              ListTile(
                key: Key('map-mode-option-${mode.storageKey}'),
                title: Text(mode.label),
                trailing: mode == value
                    ? const Icon(CupertinoIcons.check_mark, size: 18)
                    : null,
                onTap: () => Navigator.pop(sheetContext, mode),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }
}
