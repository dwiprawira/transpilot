import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/layout.dart';
import '../controllers/profiles_controller.dart';
import 'dashboard/dashboard_screen.dart';
import 'profiles/profiles_screen.dart';
import 'settings/settings_screen.dart';
import 'torrents/torrents_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final layoutSize = AppLayout.fromWidth(width);
    final titles = ['Torrents', 'Dashboard', 'Servers', 'Settings'];
    final screens = const [
      TorrentsScreen(),
      DashboardScreen(),
      ProfilesScreen(),
      SettingsScreen(),
    ];

    final profiles = ref.watch(profilesControllerProvider).valueOrNull;
    final activeProfile = profiles?.activeProfile;

    final appBar = AppBar(
      toolbarHeight: 86,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titles[_index],
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              activeProfile?.name ?? 'No server selected',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      actions: [
        if (_index == 0 && activeProfile != null)
          IconButton(
            tooltip: 'Add torrent',
            onPressed: () => openAddTorrentSheet(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        if ((profiles?.profiles.isNotEmpty ?? false))
          PopupMenuButton<String>(
            tooltip: 'Switch server',
            icon: const Icon(Icons.dns_rounded),
            onSelected: (value) async {
              await ref
                  .read(profilesControllerProvider.notifier)
                  .setActiveProfile(value);
            },
            itemBuilder: (context) {
              return [
                for (final profile in profiles!.profiles)
                  PopupMenuItem<String>(
                    value: profile.id,
                    child: Row(
                      children: [
                        if (profile.id == activeProfile?.id)
                          const Icon(Icons.check, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(profile.name)),
                      ],
                    ),
                  ),
              ];
            },
          ),
      ],
    );

    if (layoutSize == AppLayoutSize.compact) {
      return Scaffold(
        appBar: appBar,
        body: IndexedStack(index: _index, children: screens),
        bottomNavigationBar: NavigationBar(
          height: 74,
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.downloading_rounded),
              label: 'Torrents',
            ),
            NavigationDestination(
              icon: Icon(Icons.speed_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.dns_rounded),
              label: 'Servers',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.downloading_rounded),
                label: Text('Torrents'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.speed_rounded),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.dns_rounded),
                label: Text('Servers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_rounded),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(index: _index, children: screens),
          ),
        ],
      ),
    );
  }
}
