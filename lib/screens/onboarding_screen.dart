import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/l10n/sasang_localizations.dart';
import '../core/theme/sasang_theme.dart';
import '../features/state/sasang_state.dart';
import '../widgets/sasang_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.state, super.key});

  final SasangState state;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 5;
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      widget.state.completeOnboarding();
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _page == _pageCount - 1;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: _page == 0
                            ? null
                            : CupertinoButton(
                                key: const Key('onboarding-back'),
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                                onPressed: _back,
                                child: Text(
                                  tr('이전'),
                                  style: const TextStyle(
                                    color: SasangColors.secondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pageCount,
                            (index) => AnimatedContainer(
                              key: ValueKey('onboarding-indicator-$index'),
                              duration: const Duration(milliseconds: 180),
                              width: index == _page ? 20 : 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: index == _page
                                    ? SasangColors.accent
                                    : const Color(0xFFD4D4D8),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 72),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    key: const Key('onboarding-pages'),
                    controller: _pageController,
                    onPageChanged: (page) => setState(() => _page = page),
                    children: [
                      _LanguagePage(state: widget.state),
                      _FeaturePage(
                        icon: Icons.map_outlined,
                        title: tr('여행할 지도를 선택하세요'),
                        description: tr('대한민국과 세계 지도에서 여행을 기록할 지역을 골라보세요.'),
                        visual: const _MapVisual(),
                      ),
                      _FeaturePage(
                        icon: Icons.add_a_photo_outlined,
                        title: tr('지역을 사진으로 채워보세요'),
                        description: tr(
                          '방문한 지역을 누르고 사진을 추가하면, 지도 경계 안에 내 추억이 채워져요.',
                        ),
                        visual: const _PhotoVisual(),
                      ),
                      _FeaturePage(
                        icon: Icons.ios_share_outlined,
                        title: tr('여행을 기록하고 공유하세요'),
                        description: tr(
                          '장소별 사진과 날짜를 모아보고, 완성된 여행 지도를 이미지나 영상으로 나눠보세요.',
                        ),
                        visual: const _JourneyVisual(),
                      ),
                      _FeaturePage(
                        icon: Icons.lock_outline,
                        title: tr('사진은 기기에 안전하게 보관돼요'),
                        description: tr(
                          '이 앱에서 사용한 사진은 일체 서버로 전송되지 않으며, 기기 내부에 저장됩니다.',
                        ),
                        visual: const _PrivacyVisual(),
                      ),
                    ],
                  ),
                ),
                SasangPrimaryButton(
                  key: const Key('onboarding-primary-action'),
                  label: isLastPage ? tr('동의하고 시작하기') : tr('다음'),
                  height: 56,
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.state});

  final SasangState state;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(2, 24, 2, 20),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: SasangColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1218181B),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset('assets/images/icon.png', width: 68, height: 68),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          tr('언어를 선택해 주세요'),
          key: const Key('onboarding-language-title'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SasangColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('선택한 언어는 설정에서 언제든지 바꿀 수 있어요.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SasangColors.secondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        for (final language in SasangLanguage.values) ...[
          _LanguageOption(
            language: language,
            selected: state.language == language,
            onPressed: () => state.setLanguage(language),
          ),
          if (language != SasangLanguage.values.last)
            const SizedBox(height: 10),
        ],
      ],
    ),
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.onPressed,
  });

  final SasangLanguage language;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    key: ValueKey('onboarding-language-${language.code}'),
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF4FF) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected ? SasangColors.accent : SasangColors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              language.displayName,
              style: TextStyle(
                color: selected ? SasangColors.accent : SasangColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (selected)
            const Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: SasangColors.accent,
              size: 22,
            ),
        ],
      ),
    ),
  );
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.visual,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget visual;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 34, 0, 28),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: visual),
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF4FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: SasangColors.accent, size: 24),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SasangColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SasangColors.secondary,
            fontSize: 15,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

class _VisualCard extends StatelessWidget {
  const _VisualCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 270,
    height: 250,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: SasangColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1218181B),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: child,
  );
}

class _MapVisual extends StatelessWidget {
  const _MapVisual();

  @override
  Widget build(BuildContext context) => _VisualCard(
    child: Column(
      children: [
        Row(
          children: [
            _MapTab(label: tr('대한민국'), selected: true),
            const SizedBox(width: 8),
            _MapTab(label: tr('세계'), selected: false),
          ],
        ),
        const Expanded(
          child: Icon(Icons.public, color: Color(0xFFB9D9FF), size: 128),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              width: index == 1 ? 38 : 26,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == 1
                    ? SasangColors.accent
                    : const Color(0xFFDDEBFA),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MapTab extends StatelessWidget {
  const _MapTab({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? SasangColors.accent : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected ? Colors.white : SasangColors.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _PhotoVisual extends StatelessWidget {
  const _PhotoVisual();

  @override
  Widget build(BuildContext context) => _VisualCard(
    child: Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.public, color: Color(0xFFDDE1E7), size: 180),
        Transform.rotate(
          angle: -0.08,
          child: Container(
            width: 118,
            height: 142,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: SasangOverlayStyle.shadows,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF87CEEB), Color(0xFF6FCF97)],
                  ),
                ),
                child: const Icon(
                  Icons.landscape_outlined,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: 18,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: SasangColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ],
    ),
  );
}

class _JourneyVisual extends StatelessWidget {
  const _JourneyVisual();

  @override
  Widget build(BuildContext context) => _VisualCard(
    child: Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _JourneyPoint(icon: Icons.photo_outlined, active: true),
            Expanded(child: _JourneyLine()),
            _JourneyPoint(icon: Icons.location_on_outlined, active: true),
            Expanded(child: _JourneyLine()),
            _JourneyPoint(icon: Icons.ios_share_outlined, active: false),
          ],
        ),
        const SizedBox(height: 28),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 112,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB9D9FF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 162,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E4E8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: SasangColors.accent,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _JourneyPoint extends StatelessWidget {
  const _JourneyPoint({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: active ? SasangColors.accent : const Color(0xFFEAF4FF),
      shape: BoxShape.circle,
    ),
    child: Icon(
      icon,
      color: active ? Colors.white : SasangColors.accent,
      size: 21,
    ),
  );
}

class _JourneyLine extends StatelessWidget {
  const _JourneyLine();

  @override
  Widget build(BuildContext context) =>
      Container(height: 2, color: const Color(0xFFB9D9FF));
}

class _PrivacyVisual extends StatelessWidget {
  const _PrivacyVisual();

  @override
  Widget build(BuildContext context) => _VisualCard(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF4FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: SasangColors.accent,
            size: 54,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_iphone_rounded,
              color: SasangColors.secondary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                tr('기기 저장'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SasangColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
