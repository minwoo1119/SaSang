import 'package:flutter/material.dart';

import '../../core/theme/sasang_theme.dart';
import '../../widgets/sasang_center_modal.dart';

class BackupProgressDialog extends StatelessWidget {
  const BackupProgressDialog({super.key});

  @override
  Widget build(BuildContext context) => const SasangCenterModal(
    key: Key('backup-progress-dialog'),
    cardKey: Key('backup-progress-card'),
    semanticsLabel: '데이터 백업 진행',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '백업 파일을 만들고 있어요',
          style: TextStyle(
            color: SasangColors.ink,
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -.45,
            height: 1.22,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '여행 기록과 사진을 하나로 정리하는 중이에요.',
          style: TextStyle(
            color: SasangColors.secondary,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        SizedBox(height: 28),
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(3)),
          child: LinearProgressIndicator(
            key: Key('backup-progress-indicator'),
            minHeight: 4,
            backgroundColor: Color(0xFFE9E9ED),
            color: SasangColors.accent,
          ),
        ),
      ],
    ),
  );
}
