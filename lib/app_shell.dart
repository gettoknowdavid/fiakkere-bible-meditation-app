import 'package:fiakkere/_shared/routing/playlist_route.dart';
import 'package:fiakkere/_shared/routing/scripture_route.dart';
import 'package:fiakkere/_shared/routing/settings_route.dart';
import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return KaiselBranchedShell.specs(
      branches: [
        KaiselBranchSpec<ScriptureRoute>(
          initial: const VerseBrowser(),
          builder: (context, route) => switch (route) {
            VerseBrowser() => const Placeholder(),
            VerseSearch() => const Placeholder(),
            VerseDetail(:final verseId) => Placeholder(),
          },
        ),
        KaiselBranchSpec<PlaylistRoute>(
          initial: const PlaylistList(),
          builder: (context, route) => switch (route) {
            PlaylistList() => const Placeholder(),
            PlaylistDetail(:final playlistId) => const Placeholder(),
          },
        ),
        KaiselBranchSpec<SettingsRoute>(
          initial: const SettingsHome(),
          builder: (context, route) => switch (route) {
            SettingsHome() => const Placeholder(),
          },
        ),
      ],
      chromeBuilder: (context, activeBranch, branchContent, switchBranch) {
        return Scaffold(
          body: branchContent,
          bottomNavigationBar: NavigationBar(
            selectedIndex: activeBranch,
            onDestinationSelected: switchBranch,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.menu_book),
                label: 'Scripture',
              ),
              NavigationDestination(
                icon: Icon(Icons.self_improvement),
                label: 'Meditate',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
