import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/l10n/sasang_localizations.dart';

import '../../core/theme/sasang_theme.dart';
import '../../widgets/sasang_ui.dart';
import 'photo_date.dart';

Future<DateTime?> showPhotoDateDialog(
  BuildContext context, {
  required File photo,
  required DateTime initialDate,
  required bool dateFromMetadata,
}) async {
  var selected = initialDate;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              borderRadius: BorderRadius.circular(28),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('사진 날짜'),
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  Text(
                    dateFromMetadata
                        ? tr('사진에 기록된 촬영일을 불러왔어요.')
                        : tr('촬영일 정보가 없어 오늘 날짜로 설정했어요.'),
                    style: const TextStyle(
                      color: SasangColors.secondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      photo,
                      height: 138,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 14),
                  if (MediaQuery.textScalerOf(context).scale(1) >= 1.5)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('선택한 날짜'),
                          style: TextStyle(
                            color: SasangColors.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizedPhotoDate(selected),
                          key: const Key('selected-photo-date'),
                          style: const TextStyle(
                            color: SasangColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Text(
                          tr('선택한 날짜'),
                          style: TextStyle(
                            color: SasangColors.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          localizedPhotoDate(selected),
                          key: const Key('selected-photo-date'),
                          style: const TextStyle(
                            color: SasangColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(
                    height: 176,
                    child: PhotoDatePicker(
                      initialDate: selected,
                      maximumDate: DateTime.now(),
                      onChanged: (date) => setState(() => selected = date),
                    ),
                  ),
                  SizedBox(height: 14),
                  if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) ...[
                    SasangPrimaryButton(
                      label: tr('이 날짜로 저장'),
                      height: 56,
                      onPressed: () => Navigator.pop(context, selected),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: SasangTextButton(
                        label: tr('취소'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: SasangTextButton(
                            label: tr('취소'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: SasangPrimaryButton(
                            label: tr('이 날짜로 저장'),
                            height: 48,
                            onPressed: () => Navigator.pop(context, selected),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PhotoDatePicker extends StatelessWidget {
  const PhotoDatePicker({
    required this.initialDate,
    required this.maximumDate,
    required this.onChanged,
    super.key,
  });

  final DateTime initialDate;
  final DateTime maximumDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => CupertinoTheme(
    data: CupertinoTheme.of(context).copyWith(
      brightness: Brightness.light,
      textTheme: CupertinoTheme.of(context).textTheme.copyWith(
        dateTimePickerTextStyle: const TextStyle(
          color: SasangColors.ink,
          fontSize: 21,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: CupertinoDatePicker(
        key: const Key('photo-date-picker'),
        mode: CupertinoDatePickerMode.date,
        initialDateTime: initialDate,
        minimumDate: DateTime(1970),
        maximumDate: maximumDate,
        onDateTimeChanged: onChanged,
      ),
    ),
  );
}
