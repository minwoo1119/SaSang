import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';
import '../core/layout/sasang_layout.dart';
import '../features/state/sasang_state.dart';
import 'map_screen.dart';
import 'more_screen.dart';
import 'places_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.state, this.initialIndex = 0, super.key});

  final SasangState state;
  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _index == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _index != 0) setState(() => _index = 0);
    },
    child: Scaffold(
      extendBody: true,
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) => IndexedStack(
          index: _index,
          children: [
            MapScreen(state: widget.state),
            PlacesScreen(
              state: widget.state,
              onOpenMap: () => setState(() => _index = 0),
            ),
            MoreScreen(state: widget.state),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          sasangBottomBarMinimumInset,
        ),
        child: Container(
          height: sasangBottomBarHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A18181B),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _TabItem(
                index: 0,
                selected: _index == 0,
                icon: CupertinoIcons.map,
                label: '지도',
                onTap: _select,
              ),
              _TabItem(
                index: 1,
                selected: _index == 1,
                icon: CupertinoIcons.photo_on_rectangle,
                label: '장소',
                onTap: _select,
              ),
              _TabItem(
                index: 2,
                selected: _index == 2,
                icon: CupertinoIcons.ellipsis,
                label: '더보기',
                onTap: _select,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _select(int value) => setState(() => _index = value);
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.index,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final int index;
  final bool selected;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? SasangColors.accent : SasangColors.secondary;
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: color),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
