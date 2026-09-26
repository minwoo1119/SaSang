import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';
import '../features/state/sasang_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({required this.state, super.key});

  final SasangState state;

  Future<void> _start(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사진 저장 안내'),
        content: const Text('이 앱에서 사용한 사진은 일체 서버로 전송되지 않으며, 기기 내부에 저장됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소하기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('동의하고 시작하기'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    state.start();
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(31),
                        border: Border.all(color: SasangColors.divider),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1418181B),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 76,
                          height: 76,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Image.asset(
                      'assets/images/main-text-design.png',
                      width: 140,
                      height: 86,
                      fit: BoxFit.contain,
                    ),
                    const Text(
                      '사진으로 채우는 여행 지도',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3F3F46),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '방문한 지역을 고르고, 그 경계 안에 내 사진을 담아보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SasangColors.secondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => _start(context),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
