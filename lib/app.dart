import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/sasang_theme.dart';
import 'features/more/info_content.dart';
import 'features/state/sasang_state.dart';
import 'screens/home_shell.dart';
import 'screens/info_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_store_screen.dart';

class SasangApp extends StatefulWidget {
  const SasangApp({required this.state, super.key});

  final SasangState state;

  @override
  State<SasangApp> createState() => _SasangAppState();
}

class _SasangAppState extends State<SasangApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(_openLink);
    unawaited(_openInitialLink());
  }

  Future<void> _openInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openLink(uri));
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _openLink(Uri uri) {
    if (uri.scheme != 'sasang' && uri.scheme != 'com.sasang.app') return;
    final route = uri.host.isNotEmpty ? '/${uri.host}${uri.path}' : uri.path;
    if (route == '/map-store') {
      _navigatorKey.currentState?.pushNamed('/map-store');
    } else if (const {'/map', '/places', '/more'}.contains(route)) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
    } else if (route.startsWith('/info/')) {
      final type = route.substring('/info/'.length);
      if (InfoContent.byId(type) != null) {
        _navigatorKey.currentState?.pushNamed('/info/$type');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: '사상',
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: SasangTheme.light,
      builder: (context, child) => CupertinoTheme(
        data: const CupertinoThemeData(
          primaryColor: SasangColors.accent,
          scaffoldBackgroundColor: SasangColors.background,
          barBackgroundColor: Color(0xF2FFFFFF),
        ),
        child: child!,
      ),
      initialRoute: widget.state.hasStarted ? '/home' : '/',
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        if (name == '/') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => LoginScreen(state: widget.state),
          );
        }
        if (const {'/home', '/map', '/places', '/more'}.contains(name)) {
          final initialIndex = switch (name) {
            '/places' => 1,
            '/more' => 2,
            _ => 0,
          };
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                HomeShell(state: widget.state, initialIndex: initialIndex),
          );
        }
        if (name == '/map-store') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const MapStoreScreen(),
          );
        }
        if (name.startsWith('/info/')) {
          final content = InfoContent.byId(name.substring(6));
          if (content != null) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => InfoDetailScreen(content: content),
            );
          }
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => HomeShell(state: widget.state),
        );
      },
    );
  }
}
