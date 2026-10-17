import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/sasang_theme.dart';
import '../../widgets/sasang_center_modal.dart';
import 'map_share_service.dart';

class ExportProgressDialog extends StatelessWidget {
  const ExportProgressDialog({
    required this.progress,
    required this.format,
    this.onCancel,
    this.onRetry,
    this.onClose,
    super.key,
  });

  final MapExportProgress progress;
  final MapShareFormat format;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final state = _contentFor(progress.phase, format);
    final fraction = progress.phase == MapExportPhase.rendering
        ? progress.fraction?.clamp(0, 1).toDouble()
        : null;
    final terminal =
        progress.phase == MapExportPhase.failed ||
        progress.phase == MapExportPhase.cancelled;

    return SasangCenterModal(
      key: const Key('share-export-progress-dialog'),
      cardKey: const Key('share-export-progress-card'),
      semanticsLabel: '내보내기 진행',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.title,
            key: const Key('share-export-progress-title'),
            style: const TextStyle(
              color: SasangColors.ink,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -.45,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.description,
            key: const Key('share-export-progress-description'),
            style: const TextStyle(
              color: SasangColors.secondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          if (!terminal) ...[
            const SizedBox(height: 28),
            if (fraction != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(fraction * 100).floor()}%',
                  key: const Key('share-video-progress-percent'),
                  style: const TextStyle(
                    color: SasangColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                key: const Key('share-video-progress'),
                value: fraction,
                minHeight: 4,
                backgroundColor: const Color(0xFFE9E9ED),
                color: SasangColors.accent,
              ),
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: CupertinoButton(
                  key: const Key('share-export-cancel'),
                  padding: EdgeInsets.zero,
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: onCancel,
                  child: const Text(
                    '내보내기 취소',
                    style: TextStyle(
                      color: SasangColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onClose != null)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: onClose,
                    child: const Text('닫기'),
                  ),
                if (onRetry != null) ...[
                  const SizedBox(width: 4),
                  CupertinoButton(
                    key: const Key('share-export-retry'),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    color: SasangColors.accent,
                    borderRadius: BorderRadius.circular(15),
                    onPressed: onRetry,
                    child: const Text(
                      '다시 시도',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

({String title, String description}) _contentFor(
  MapExportPhase phase,
  MapShareFormat format,
) {
  final video = format == MapShareFormat.video;
  return switch (phase) {
    MapExportPhase.preparing => (
      title: video ? '여행 영상을 만들고 있어요' : '여행 지도를 만들고 있어요',
      description: '사진을 정리하는 중이에요.',
    ),
    MapExportPhase.rendering => (
      title: video ? '여행 영상을 만들고 있어요' : '여행 지도를 만들고 있어요',
      description: video ? '여행의 순간을 영상으로 담고 있어요.' : '여행의 순간을 한 장에 담고 있어요.',
    ),
    MapExportPhase.encoding => (
      title: '거의 다 됐어요',
      description: video ? '완성된 영상을 저장하고 있어요.' : '완성된 사진을 저장하고 있어요.',
    ),
    MapExportPhase.ready => (
      title: video ? '영상이 준비됐어요' : '사진이 준비됐어요',
      description: '공유 화면을 여는 중이에요.',
    ),
    MapExportPhase.cancelled => (
      title: '내보내기를 중단했어요',
      description: '지도와 여행 기록은 그대로 유지돼요.',
    ),
    MapExportPhase.failed => (
      title: video ? '영상을 만들지 못했어요' : '사진을 만들지 못했어요',
      description: '기기 저장 공간을 확인한 뒤 다시 시도해 주세요.',
    ),
  };
}
