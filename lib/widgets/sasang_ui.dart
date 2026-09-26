import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';

class SasangSurface extends StatelessWidget {
  const SasangSurface({
    required this.child,
    super.key,
    this.padding,
    this.radius = 18,
    this.blur = false,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool blur;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: blur ? 0.88 : 1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: SasangColors.divider, width: 0.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F18181B),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
    if (!blur) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: content,
      ),
    );
  }
}

class SasangPrimaryButton extends StatelessWidget {
  const SasangPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      borderRadius: BorderRadius.circular(15),
      color: SasangColors.accent,
      disabledColor: const Color(0xFFE4E4E7),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    ),
  );
}

class SasangTextButton extends StatelessWidget {
  const SasangTextButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onPressed: onPressed,
    child: Text(
      label,
      style: TextStyle(
        color: destructive ? CupertinoColors.systemRed : SasangColors.accent,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class SasangChevronRow extends StatelessWidget {
  const SasangChevronRow({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    onPressed: onTap,
    child: SizedBox(
      height: 52,
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
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 18,
            color: SasangColors.secondary,
          ),
        ],
      ),
    ),
  );
}

Future<bool> showSasangConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async =>
    await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            isDefaultAction: !destructive,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Future<T?> showSasangSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFD),
            borderRadius: BorderRadius.circular(28),
          ),
          child: child,
        ),
      ),
    );
