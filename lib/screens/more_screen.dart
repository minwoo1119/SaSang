import 'package:flutter/cupertino.dart';

import '../features/more/info_content.dart';
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
