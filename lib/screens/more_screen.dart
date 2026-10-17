import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';
import '../features/more/info_content.dart';
import '../features/state/sasang_state.dart';
import '../widgets/ad_banner.dart';
import '../widgets/sasang_ui.dart';

const _backgroundColor = Color(0xFFF7F7F8);
const _surfaceColor = Color(0xFFFFFFFF);
const _borderColor = Color(0xFFE9E9ED);

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
      destructive: true,
    );
    if (!approved || !mounted) return;
    await widget.state.clearAllData();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  Future<bool> _confirm(
    String title,
    String body,
    String action, {
    bool destructive = false,
  }) => showSasangConfirmDialog(
    context,
    title: title,
    message: body,
    action: action,
    destructive: destructive,
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _backgroundColor,
    child: SafeArea(
      child: ListView(
        key: const ValueKey('more-scroll-view'),
        padding: const EdgeInsets.only(top: 22, bottom: 128),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              '더보기',
              key: ValueKey('more-page-title'),
              style: TextStyle(
                color: SasangColors.ink,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _MoreAdArea(),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _section('map', '지도', [
              _MoreMenuItem(
                label: '지도 상점',
                onTap: () => Navigator.pushNamed(context, '/map-store'),
              ),
            ]),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _section('information', '약관 및 정보', [
              for (final item in InfoContent.items)
                _MoreMenuItem(
                  label: item.label,
                  onTap: () => Navigator.pushNamed(context, '/info/${item.id}'),
                ),
            ]),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _section('account', '계정 및 데이터', [
              _MoreMenuItem(label: '로그아웃', onTap: _logout, showsChevron: false),
              _MoreMenuItem(
                label: '데이터 지우고 로그아웃하기',
                onTap: _clear,
                showsChevron: false,
                destructive: true,
              ),
            ]),
          ),
        ],
      ),
    ),
  );

  Widget _section(String id, String title, List<_MoreMenuItem> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: SasangColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 12),
      Container(
        key: ValueKey('more-section-card-$id'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: _borderColor, width: 0.8),
        ),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _MoreMenuRow(item: items[index]),
              if (index != items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(
                    height: 1,
                    thickness: 0.6,
                    color: _borderColor,
                  ),
                ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _MoreAdArea extends StatelessWidget {
  const _MoreAdArea();

  @override
  Widget build(BuildContext context) => const SizedBox(
    key: ValueKey('more-ad-area'),
    height: 58,
    width: double.infinity,
    child: Center(child: AdBanner(placement: AdPlacement.more)),
  );
}

class _MoreMenuItem {
  const _MoreMenuItem({
    required this.label,
    required this.onTap,
    this.showsChevron = true,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool showsChevron;
  final bool destructive;
}

class _MoreMenuRow extends StatelessWidget {
  const _MoreMenuRow({required this.item});

  final _MoreMenuItem item;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = item.destructive
        ? CupertinoColors.systemRed
        : SasangColors.ink;

    return CupertinoButton(
      key: ValueKey('more-menu-${item.label}'),
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity: 0.62,
      onPressed: item.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              if (item.showsChevron) ...[
                const SizedBox(width: 12),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  size: 17,
                  color: SasangColors.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
