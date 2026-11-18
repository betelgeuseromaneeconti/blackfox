import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../app_settings.dart';
import '../core/android_core.dart';
import '../core/core_controller.dart';
import '../l10n/app_localizations.dart';
import 'about_page.dart';
import 'announcement_panel.dart';
import 'accounts_page.dart';
import 'format.dart';
import 'help_page.dart';
import 'logs_page.dart';
import 'overview_page.dart';
import 'servers_page.dart';
import 'settings_page.dart';
import 'widgets.dart';

/// BLACKFOX mobile-first shell for Android phones, foldables, tablets, and
/// narrow desktop windows.
/// On Android (`Platform.isAndroid`), offers 5 bottom navigation tabs:
/// Home, Servers, Accounts, Activity (Logs + Connections), and Settings
/// (with Help and About inside Settings and the header menu).
class MobileShell extends StatefulWidget {
  const MobileShell({
    super.key,
    required this.core,
    required this.settings,
    required this.banner,
    this.noCore,
  });

  final CoreController core;
  final AppSettings settings;
  final Widget? banner;
  final Widget? noCore;

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    AndroidCore.homeRequests.addListener(_openHome);
  }

  void _openHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _tab = 0);
  }

  @override
  void dispose() {
    AndroidCore.homeRequests.removeListener(_openHome);
    super.dispose();
  }

  void _push(String title, Widget Function() page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ListenableBuilder(
          listenable: widget.core,
          builder: (context, _) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: SafeArea(
              top: false,
              child: OwnTopBar(child: _readable(page())),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _readable(Widget page) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: page,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final core = widget.core;
    final settings = widget.settings;
    final fiveTabs = Platform.isAndroid;
    final maxTab = fiveTabs ? 4 : 1;
    final currentTab = _tab.clamp(0, maxTab);

    void openServers() =>
        _push(l.navServers, () => ServersPage(core: core, settings: settings));
    void openAccounts() => _push(
      l.navAccounts,
      () => AccountsPage(core: core, settings: settings),
    );
    void openConnection() => _push(
      l.sectionConnection,
      () => SettingsPage(
        core: core,
        settings: settings,
        section: SettingsSection.connection,
      ),
    );
    void openUpstreamProxy() => _push(
      l.upstreamProxy,
      () => SettingsPage(
        core: core,
        settings: settings,
        section: SettingsSection.upstreamProxy,
      ),
    );

    final settingsView = _readable(
      _SettingsList(
        onOpenServers: openServers,
        onOpenAccounts: openAccounts,
        push: _push,
        core: core,
        settings: settings,
      ),
    );

    final page =
        widget.noCore ??
        switch (currentTab) {
          0 => OverviewPage(
            core: core,
            settings: settings,
            onOpenServers: openServers,
            onOpenAccounts: openAccounts,
            onOpenConnection: openConnection,
            onOpenUpstreamProxy: openUpstreamProxy,
            phone: true,
          ),
          1 when fiveTabs => _readable(
            ServersPage(core: core, settings: settings),
          ),
          2 when fiveTabs => _readable(
            AccountsPage(core: core, settings: settings),
          ),
          3 when fiveTabs => _readable(
            LogsPage(core: core, settings: settings, connections: true),
          ),
          _ => settingsView,
        };

    return PopScope(
      canPop: currentTab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        body: SafeArea(
          top:
              currentTab != 0 ||
              widget.noCore != null ||
              widget.banner != null,
          child: AnnouncementOverlay(
            settings: settings,
            onOpenUpdates: () =>
                _push(l.checkUpdates, () => AboutPage(core: core)),
            child: Column(
              children: [
                ?widget.banner,
                Expanded(child: page),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _themed(
          context,
          home:
              currentTab == 0 &&
              widget.noCore == null &&
              Theme.of(context).brightness == Brightness.dark,
          child: NavigationBar(
            selectedIndex: currentTab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: fiveTabs
                ? [
                    NavigationDestination(
                      icon: const Icon(Icons.space_dashboard_outlined),
                      selectedIcon: const Icon(Icons.space_dashboard_rounded),
                      label: l.navHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.hub_outlined),
                      selectedIcon: const Icon(Icons.hub_rounded),
                      label: l.navServers,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.manage_accounts_outlined),
                      selectedIcon: const Icon(Icons.manage_accounts_rounded),
                      label: l.navAccounts,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.monitor_heart_outlined),
                      selectedIcon: const Icon(Icons.monitor_heart_rounded),
                      label: l.navLogs,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.tune_outlined),
                      selectedIcon: const Icon(Icons.tune_rounded),
                      label: l.navSettings,
                    ),
                  ]
                : [
                    NavigationDestination(
                      icon: const Icon(Icons.space_dashboard_outlined),
                      selectedIcon: const Icon(Icons.space_dashboard_rounded),
                      label: l.navHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.tune_outlined),
                      selectedIcon: const Icon(Icons.tune_rounded),
                      label: l.navSettings,
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _themed(
    BuildContext context, {
    required bool home,
    required Widget child,
  }) => home
      ? Theme(data: midnightTheme(Theme.of(context)), child: child)
      : child;
}

class _SettingsList extends StatefulWidget {
  const _SettingsList({
    required this.onOpenServers,
    required this.onOpenAccounts,
    required this.push,
    required this.core,
    required this.settings,
  });

  final VoidCallback onOpenServers;
  final VoidCallback onOpenAccounts;
  final void Function(String title, Widget Function() page) push;
  final CoreController core;
  final AppSettings settings;

  @override
  State<_SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<_SettingsList> {
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final core = widget.core;
    final settings = widget.settings;
    final push = widget.push;
    final onOpenServers = widget.onOpenServers;
    final onOpenAccounts = widget.onOpenAccounts;
    bool matches(String name) =>
        _query.isEmpty || foldForSearch(name).contains(_query);
    Widget? group(String title, List<(String, Widget)> tiles) {
      final kept = [
        for (final (name, tile) in tiles)
          if (matches(name)) tile,
      ];
      return kept.isEmpty ? null : SettingsGroup(title: title, tiles: kept);
    }

    Widget tile(IconData icon, String title, VoidCallback onTap) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
    void open(SettingsSection section, String name) => push(
      name,
      () => SettingsPage(core: core, settings: settings, section: section),
    );
    (String, Widget) section(
      SettingsSection section,
      IconData icon,
      String name,
    ) => (name, tile(icon, name, () => open(section, name)));
    (String, Widget) row(IconData icon, String name, VoidCallback onTap) =>
        (name, tile(icon, name, onTap));

    final offered = {
      SettingsSection.general,
      SettingsSection.connection,
      SettingsSection.routing,
      SettingsSection.dns,
      SettingsSection.relay,
      SettingsSection.fragment,
      SettingsSection.upstreamProxy,
      if (!Platform.isAndroid) SettingsSection.advanced,
    };
    final hits = _query.isEmpty
        ? const <(SettingsSection, String)>[]
        : [
            for (final entry in settingsIndex(l))
              if (foldForSearch(entry.$2).contains(_query) &&
                  offered.contains(entry.$1) &&
                  settingOnThisPlatform(l, entry.$2))
                entry,
          ];
    final groups = [
      ?group(l.sectionGeneral, [
        section(
          SettingsSection.general,
          Icons.tune_rounded,
          l.sectionGeneral,
        ),
        row(Icons.hub_rounded, l.navServers, onOpenServers),
        row(Icons.manage_accounts_outlined, l.navAccounts, onOpenAccounts),
      ]),
      ?group(l.groupNetwork, [
        section(
          SettingsSection.connection,
          Icons.vpn_lock_outlined,
          l.sectionConnection,
        ),
        section(
          SettingsSection.routing,
          Icons.alt_route_rounded,
          l.sectionRouting,
        ),
        section(SettingsSection.dns, Icons.dns_rounded, l.sectionDns),
      ]),
      ?group(l.sectionBypass, [
        section(SettingsSection.relay, Icons.cloud_outlined, l.apiRelay),
        section(
          SettingsSection.fragment,
          Icons.content_cut_rounded,
          l.tlsFragment,
        ),
        section(
          SettingsSection.upstreamProxy,
          Icons.lan_outlined,
          l.upstreamProxy,
        ),
      ]),
      ?group(l.groupApp, [
        if (!Platform.isAndroid)
          section(
            SettingsSection.advanced,
            Icons.build_outlined,
            l.sectionAdvanced,
          ),
        row(
          Icons.monitor_heart_outlined,
          l.navLogs,
          () => push(
            l.navLogs,
            () => LogsPage(core: core, settings: settings, connections: true),
          ),
        ),
        row(
          Icons.help_outline_rounded,
          'Help',
          () => push('Help', () => HelpPage(core: core)),
        ),
        row(
          Icons.info_outline_rounded,
          l.navAbout,
          () => push(l.navAbout, () => AboutPage(core: core)),
        ),
      ]),
    ];
    return ListView(
      padding: pagePadding(context),
      children: [
        PageTitle(l.settingsTitle),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = foldForSearch(v)),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: l.search,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (groups.isEmpty && hits.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Text(
              l.settingsNoMatch,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ...groups,
        if (hits.isNotEmpty)
          SettingsGroup(
            title: l.settingsTitle,
            tiles: [
              for (final (section, name) in hits)
                ListTile(
                  leading: const Icon(Icons.chevron_right_rounded),
                  title: Text(name),
                  subtitle: Text(settingsSectionName(l, section)),
                  onTap: () => open(section, settingsSectionName(l, section)),
                ),
            ],
          ),
      ],
    );
  }
}
