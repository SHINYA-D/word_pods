import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({
    super.key,
    required this.child,
    required this.showSampleTab,
  });

  final Widget child;

  /// 「テスト」タブ（サンプル画面）を表示するか。開発者のときだけ true にする。
  final bool showSampleTab;

  static const _home = _Tab(
    path: '/home',
    destination: NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'ホーム',
    ),
  );
  static const _results = _Tab(
    path: '/results',
    destination: NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: '成績',
    ),
  );
  static const _sample = _Tab(
    path: '/sample',
    destination: NavigationDestination(
      icon: Icon(Icons.science_outlined),
      selectedIcon: Icon(Icons.science),
      label: 'テスト',
    ),
  );
  static const _settings = _Tab(
    path: '/settings',
    destination: NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: '設定',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tabs = [_home, _results, if (showSampleTab) _sample, _settings];
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex(tabs, location),
        onDestinationSelected: (i) => context.go(tabs[i].path),
        destinations: [for (final tab in tabs) tab.destination],
      ),
    );
  }

  int _tabIndex(List<_Tab> tabs, String location) {
    for (var i = tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }
}

class _Tab {
  const _Tab({required this.path, required this.destination});

  final String path;
  final NavigationDestination destination;
}
