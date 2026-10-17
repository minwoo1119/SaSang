import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/theme/sasang_theme.dart';
import '../features/more/info_content.dart';

class InfoDetailScreen extends StatefulWidget {
  const InfoDetailScreen({required this.content, super.key, this.packageInfo});

  final InfoContent content;
  final Future<PackageInfo>? packageInfo;

  @override
  State<InfoDetailScreen> createState() => _InfoDetailScreenState();
}

class _InfoDetailScreenState extends State<InfoDetailScreen> {
  late final Future<PackageInfo> _packageInfo =
      widget.packageInfo ?? PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SasangColors.pageBackground,
    appBar: CupertinoNavigationBar(
      automaticallyImplyLeading: false,
      leading: Navigator.of(context).canPop()
          ? CupertinoNavigationBarBackButton(
              color: SasangColors.ink,
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      backgroundColor: SasangColors.pageBackground.withValues(alpha: .96),
      border: const Border(
        bottom: BorderSide(color: SasangColors.border, width: .5),
      ),
      middle: Text(
        widget.content.title,
        style: const TextStyle(
          color: SasangColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    body: widget.content.isAppInfo
        ? _AppInfoBody(content: widget.content, packageInfo: _packageInfo)
        : _DocumentBody(content: widget.content),
  );
}

class _DocumentBody extends StatelessWidget {
  const _DocumentBody({required this.content});

  final InfoContent content;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: ValueKey('info-document-${content.id}'),
    padding: EdgeInsets.fromLTRB(
      24,
      32,
      24,
      MediaQuery.paddingOf(context).bottom + 48,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          style: const TextStyle(
            color: SasangColors.ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -.65,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content.effectiveDate == null
              ? '시행일 미정'
              : '시행일 ${content.effectiveDate}',
          key: ValueKey('info-effective-date-${content.id}'),
          style: const TextStyle(
            color: SasangColors.secondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 40),
        for (var index = 0; index < content.sections.length; index++) ...[
          _DocumentSection(section: content.sections[index]),
          if (index != content.sections.length - 1) const SizedBox(height: 36),
        ],
      ],
    ),
  );
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({required this.section});

  final InfoSection section;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        section.title,
        style: const TextStyle(
          color: SasangColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -.25,
        ),
      ),
      const SizedBox(height: 12),
      for (var index = 0; index < section.paragraphs.length; index++) ...[
        Text(
          section.paragraphs[index],
          style: const TextStyle(
            color: Color(0xFF52525B),
            fontSize: 16,
            height: 1.68,
          ),
        ),
        if (index != section.paragraphs.length - 1) const SizedBox(height: 14),
      ],
    ],
  );
}

class _AppInfoBody extends StatelessWidget {
  const _AppInfoBody({required this.content, required this.packageInfo});

  final InfoContent content;
  final Future<PackageInfo> packageInfo;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey('app-info-scroll-view'),
    padding: EdgeInsets.fromLTRB(
      24,
      36,
      24,
      MediaQuery.paddingOf(context).bottom + 48,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: SasangRadii.contentCard,
                child: Image.asset(
                  'assets/images/icon.png',
                  key: const ValueKey('app-info-icon'),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  semanticLabel: '사상 앱 아이콘',
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '사상',
                style: TextStyle(
                  color: SasangColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '나의 여행을 지도에 남기다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SasangColors.secondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        for (final section in content.sections) ...[
          Text(
            section.title,
            style: const TextStyle(
              color: SasangColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final paragraph in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                paragraph,
                style: const TextStyle(
                  color: Color(0xFF52525B),
                  fontSize: 16,
                  height: 1.62,
                ),
              ),
            ),
        ],
        const SizedBox(height: 28),
        const Text(
          '상세 정보',
          style: TextStyle(
            color: SasangColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const ValueKey('app-info-detail-group'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SasangColors.card,
            borderRadius: SasangRadii.contentCard,
            border: Border.all(color: SasangColors.border, width: .8),
          ),
          child: Column(
            children: [
              _VersionRow(packageInfo: packageInfo),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Divider(
                  height: 1,
                  thickness: .6,
                  color: SasangColors.border,
                ),
              ),
              _LicenseRow(packageInfo: packageInfo),
            ],
          ),
        ),
      ],
    ),
  );
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.packageInfo});

  final Future<PackageInfo> packageInfo;

  @override
  Widget build(BuildContext context) => _InfoRow(
    label: '버전',
    trailing: FutureBuilder<PackageInfo>(
      future: packageInfo,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final label = info == null
            ? '확인 중'
            : '${info.version} (${info.buildNumber})';
        return Text(
          label,
          key: const ValueKey('app-version-label'),
          style: const TextStyle(
            color: SasangColors.secondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    ),
  );
}

class _LicenseRow extends StatelessWidget {
  const _LicenseRow({required this.packageInfo});

  final Future<PackageInfo> packageInfo;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    key: const ValueKey('open-source-licenses-button'),
    padding: EdgeInsets.zero,
    onPressed: () async {
      final info = await packageInfo;
      if (!context.mounted) return;
      showLicensePage(
        context: context,
        applicationName: '사상',
        applicationVersion: '${info.version} (${info.buildNumber})',
        applicationIcon: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset('assets/images/icon.png', width: 56, height: 56),
        ),
      );
    },
    child: const _InfoRow(
      label: '오픈소스 라이선스',
      trailing: Icon(
        CupertinoIcons.chevron_forward,
        size: 17,
        color: SasangColors.secondary,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 62),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: SasangColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(child: trailing),
        ],
      ),
    ),
  );
}
