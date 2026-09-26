import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';
import '../features/more/info_content.dart';

class InfoDetailScreen extends StatelessWidget {
  const InfoDetailScreen({required this.content, super.key});
  final InfoContent content;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const CupertinoNavigationBar(
      middle: Text('약관 및 정보', style: TextStyle(fontWeight: FontWeight.w700)),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SasangColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            for (final paragraph in content.body)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  paragraph,
                  style: const TextStyle(
                    color: Color(0xFF52525B),
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
