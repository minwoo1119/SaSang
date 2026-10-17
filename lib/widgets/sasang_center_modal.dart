import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';

class SasangCenterModal extends StatelessWidget {
  const SasangCenterModal({
    required this.child,
    required this.semanticsLabel,
    super.key,
    this.cardKey,
  });

  final Widget child;
  final String semanticsLabel;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ModalBarrier(
        key: Key('sasang-center-modal-barrier'),
        dismissible: false,
        color: Color(0x57000000),
      ),
      SafeArea(
        child: Center(
          child: FractionallySizedBox(
            widthFactor: .82,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: semanticsLabel,
                child: DecoratedBox(
                  key: cardKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: SasangColors.border, width: .6),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(30, 30, 30, 26),
                    child: Material(
                      type: MaterialType.transparency,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Future<bool> showSasangCenterConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async =>
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          SasangCenterModal(
            key: const Key('sasang-center-confirm-dialog'),
            cardKey: const Key('sasang-center-confirm-card'),
            semanticsLabel: title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SasangColors.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.45,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(
                    color: SasangColors.secondary,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: _ModalAction(
                        key: const Key('sasang-center-confirm-cancel'),
                        label: '취소',
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModalAction(
                        key: const Key('sasang-center-confirm-action'),
                        label: action,
                        emphasized: true,
                        destructive: destructive,
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: .96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    ) ??
    false;

class _ModalAction extends StatelessWidget {
  const _ModalAction({
    required this.label,
    required this.onPressed,
    super.key,
    this.emphasized = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool emphasized;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? CupertinoColors.systemRed
        : emphasized
        ? SasangColors.accent
        : const Color(0xFFF4F4F5);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      color: color,
      borderRadius: BorderRadius.circular(16),
      onPressed: onPressed,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: emphasized ? Colors.white : SasangColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
