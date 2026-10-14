import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/calendar/calendar_page.dart';
import 'features/namaz/namaz_page.dart';
import 'features/shell/top_bar.dart';
import 'features/timer/timer_page.dart';
import 'features/wird/wird_page.dart';
import 'providers/settings_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: 'Namaz Timer',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.values[mode],
      theme: buildTheme(AppPalette.light, Brightness.light),
      darkTheme: buildTheme(AppPalette.dark, Brightness.dark),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int i = 0;

  static const dests = [
    (Icons.mosque_outlined, Icons.mosque, 'Namaz'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Wird'),
    (Icons.timer_outlined, Icons.timer, 'Timer'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final wide = MediaQuery.sizeOf(context).width >= 800;
    const pages = [NamazPage(), CalendarPage(), WirdPage(), TimerPage()];
    final body = DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .45],
              colors: [p.bgTop, p.bg])),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              const TopBar(),
              Expanded(
                  child: IndexedStack(
                      index: i, sizing: StackFit.expand, children: pages)),
            ]),
          ),
        ),
      ),
    );
    return Scaffold(
      body: wide
          ? Row(children: [
              NavigationRail(
                labelType: NavigationRailLabelType.all,
                selectedIndex: i,
                onDestinationSelected: (v) => setState(() => i = v),
                destinations: [
                  for (final d in dests)
                    NavigationRailDestination(
                        icon: Icon(d.$1),
                        selectedIcon: Icon(d.$2),
                        label: Text(d.$3))
                ],
              ),
              Expanded(child: body),
            ])
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: i,
              onDestinationSelected: (v) => setState(() => i = v),
              destinations: [
                for (final d in dests)
                  NavigationDestination(
                      icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3)
              ],
            ),
    );
  }
}
