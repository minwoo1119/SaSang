import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/sasang_theme.dart';
import 'photo_date.dart';

Future<DateTime?> showPhotoDateDialog(
  BuildContext context, {
  required File photo,
  required DateTime initialDate,
  required bool dateFromMetadata,
}) async {
  var selected = initialDate;
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '사진 날짜',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 390,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFromMetadata
                    ? '사진에 기록된 촬영일을 불러왔어요.'
                    : '촬영일 정보가 없어 오늘 날짜로 설정했어요.',
                style: const TextStyle(
                  color: SasangColors.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  photo,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '사진 날짜',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(koreanDate(selected)),
                trailing: const Icon(
                  Icons.edit_calendar,
                  color: SasangColors.accent,
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selected,
                    firstDate: DateTime(1970),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => selected = date);
                },
              ),
              Center(
                child: Text(
                  '기록일 ${photoDateKey(selected)}',
                  style: const TextStyle(color: SasangColors.secondary),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('이 날짜로 저장'),
          ),
        ],
      ),
    ),
  );
}
