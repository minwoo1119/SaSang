import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';
import '../features/more/info_content.dart';
import '../features/photos/photo_picker_service.dart';
import '../features/state/sasang_state.dart';
import '../widgets/ad_banner.dart';
import '../widgets/sasang_ui.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({required this.state, super.key});
  final SasangState state;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _picker = PhotoPickerService();

  Future<void> _pickProfile() async {
    try {
      final picked = await _picker.pick(imageQuality: 85);
      if (picked == null) return;
      final saved = await widget.state.storage.copyImage(
        picked.file,
        'profile',
        'profile-image',
      );
      widget.state.setProfile(imageUri: saved.uri.toString(), setImage: true);
    } on Object catch (error) {
      if (mounted) _error(error);
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: widget.state.name);
    final value = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('표시 이름 수정'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            textInputAction: TextInputAction.done,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      widget.state.setProfile(nextName: value);
    }
  }

  void _error(Object error) => showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('이미지를 변경할 수 없어요'),
      content: Text(error.toString()),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );

  Future<void> _logout() async {
    final approved = await _confirm(
      '로그아웃',
      '기기에 저장된 여행 기록과 프로필은 유지됩니다.',
      '로그아웃',
    );
    if (!approved || !mounted) return;
    widget.state.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  Future<void> _clear() async {
    final approved = await _confirm(
      '데이터 지우고 로그아웃',
      '기기에 저장된 모든 여행 기록과 프로필 정보를 초기화합니다.',
      '데이터 지우기',
    );
    if (!approved || !mounted) return;
    await widget.state.clearAllData();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  Future<bool> _confirm(String title, String body, String action) =>
      showSasangConfirmDialog(
        context,
        title: title,
        message: body,
        action: action,
        destructive: true,
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
      children: [
        SasangSurface(
          padding: const EdgeInsets.all(18),
          radius: 24,
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickProfile,
                    child: FutureBuilder<File?>(
                      future: widget.state.storage.resolveImage(
                        widget.state.profileImageUri,
                      ),
                      builder: (context, snapshot) => CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFFF4F4F5),
                        foregroundImage: snapshot.data == null
                            ? const AssetImage(
                                'assets/images/default-profile.jpg',
                              )
                            : FileImage(snapshot.data!) as ImageProvider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '개인 프로필',
                          style: TextStyle(
                            color: SasangColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.state.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          '프로필 사진과 표시 이름을 관리해요',
                          style: TextStyle(
                            color: SasangColors.secondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SasangPrimaryButton(
                label: '수정',
                height: 44,
                onPressed: _editName,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AdBanner(placement: AdPlacement.more),
        const SizedBox(height: 24),
        _section('지도', [
          ('지도 상점', () => Navigator.pushNamed(context, '/map-store')),
        ]),
        const SizedBox(height: 22),
        _section('약관 및 정보', [
          for (final item in InfoContent.items)
            (
              item.label,
              () => Navigator.pushNamed(context, '/info/${item.id}'),
            ),
        ]),
        const SizedBox(height: 26),
        SasangTextButton(label: '로그아웃', onPressed: _logout),
        SasangTextButton(
          label: '데이터 지우고 로그아웃하기',
          destructive: true,
          onPressed: _clear,
        ),
      ],
    ),
  );

  Widget _section(String title, List<(String, VoidCallback)> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      SasangSurface(
        radius: 18,
        child: Column(
          children: [
            for (final item in items)
              SasangChevronRow(label: item.$1, onTap: item.$2),
          ],
        ),
      ),
    ],
  );
}
