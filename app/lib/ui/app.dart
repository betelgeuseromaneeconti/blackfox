import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../app_settings.dart';
import '../core/android_core.dart';
import '../core/core_api.dart';
import '../core/core_controller.dart';
import '../core/models.dart';
import '../l10n/app_localizations.dart';
import 'about_page.dart';
import 'announcement_panel.dart';
import 'accounts_page.dart';
import 'focus_ring.dart';
import 'format.dart';
import 'help_page.dart';
import 'logs_page.dart';
import 'mobile_shell.dart';
import 'overview_page.dart';
import 'port_dialog.dart';
import 'servers_page.dart';
import 'settings_page.dart';
import 'welcome_page.dart';
import 'widgets.dart';

ThemeData _theme(Brightness brightness, Locale locale) {
  final dark = brightness == Brightness.dark;
  final scheme = dark
      ? const ColorScheme.dark(
          primary: Color(0xFFFFFFFF),
          onPrimary: Color(0xFF070709),
          primaryContainer: Color(0xFF23232C),
          onPrimaryContainer: Color(0xFFF4F4F8),
          secondary: Color(0xFFD4D4DC),
          onSecondary: Color(0xFF0A0A0E),
          secondaryContainer: Color(0xFF1F1F27),
          onSecondaryContainer: Color(0xFFF2F2F6),
          tertiary: Color(0xFFB0B0BC),
          onTertiary: Color(0xFF09090C),
          surface: Color(0xFF08080B),
          onSurface: Color(0xFFF2F2F6),
          onSurfaceVariant: Color(0xFF9696A4),
          surfaceContainerLowest: Color(0xFF050507),
          surfaceContainerLow: Color(0xFF0C0C10),
          surfaceContainer: Color(0xFF111116),
          surfaceContainerHigh: Color(0xFF17171E),
          surfaceContainerHighest: Color(0xFF21212B),
          outline: Color(0x42FFFFFF),
          outlineVariant: Color(0x22FFFFFF),
          error: Color(0xFFD8D8E0),
          onError: Color(0xFF08080A),
        )
      : const ColorScheme.light(
          primary: Color(0xFF101015),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFE4E4EC),
          onPrimaryContainer: Color(0xFF101015),
          secondary: Color(0xFF34343E),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFE8E8F0),
          onSecondaryContainer: Color(0xFF14141A),
          tertiary: Color(0xFF52525E),
          onTertiary: Color(0xFFFFFFFF),
          surface: Color(0xFFF4F4F7),
          onSurface: Color(0xFF101015),
          onSurfaceVariant: Color(0xFF5A5A68),
          surfaceContainerLowest: Color(0xFFFFFFFF),
          surfaceContainerLow: Color(0xFFF8F8FA),
          surfaceContainer: Color(0xFFEEEEF3),
          surfaceContainerHigh: Color(0xFFE6E6ED),
          surfaceContainerHighest: Color(0xFFDCDCE5),
          outline: Color(0x38000000),
          outlineVariant: Color(0x1E000000),
          error: Color(0xFF24242C),
          onError: Color(0xFFFFFFFF),
        );

  // Bundled Inter for English, Vazirmatn for Persian and Arabic, and the
  // platform's typography for the remaining languages.
  final font = languageFont(locale.languageCode);
  final theme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: font,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF07070A)
        : const Color(0xFFF4F4F7),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 0.8,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? const Color(0xD8121218) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.12),
          width: 0.9,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? const Color(0xFF111117) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.14),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
  return theme.copyWith(
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: dark ? const Color(0xFF0C0C10) : const Color(0xFFEAEAEF),
      indicatorColor: dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.10),
      // NavigationRail replaces DefaultTextStyle, so retain the resolved
      // platform font instead of letting a null family choose a fallback.
      selectedLabelTextStyle: theme.textTheme.labelLarge!.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      unselectedLabelTextStyle: theme.textTheme.labelLarge!.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
      selectedIconTheme: IconThemeData(
        size: 22,
        color: scheme.onSecondaryContainer,
      ),
      unselectedIconTheme: IconThemeData(
        size: 22,
        color: scheme.onSurfaceVariant,
      ),
    ),
  );
}

class VpnApp extends StatelessWidget {
  const VpnApp({
    super.key,
    required this.core,
    required this.settings,
    this.navigatorKey,
  });

  final CoreController core;
  final AppSettings settings;
  final GlobalKey<NavigatorState>? navigatorKey;

  static const localizationsDelegates = [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, _) =>
          AppSettings.localeOf(AppSettings.languageForList(locales)),
      localizationsDelegates: localizationsDelegates,
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        // BlackFox Dark is the default theme unless Light is explicitly chosen.
        final dark = switch (settings.themeMode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system => true,
        };
        return Theme(
          data: _theme(dark ? Brightness.dark : Brightness.light, locale),
          child: FocusRing(
            atStart: Platform.isAndroid && AndroidCore.isTv,
            child: child!,
          ),
        );
      },
      home: Shell(core: core, settings: settings),
    ),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.core, required this.settings});

  final CoreController core;
  final AppSettings settings;

  @override
  State<Shell> createState() => _ShellState();
}

enum _Page { overview, servers, accounts, logs, settings, help, about }

class _ShellState extends State<Shell> {
  _Page _page = _Page.overview;

  /// The settings section the home page opened (Connection), until another
  /// page is chosen.
  SettingsSection? _settingsOpening;

  @override
  void initState() {
    super.initState();
    AndroidCore.homeRequests.addListener(_openHome);
  }

  void _openHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      _page = _Page.overview;
      _settingsOpening = null;
    });
  }

  @override
  void dispose() {
    AndroidCore.homeRequests.removeListener(_openHome);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.core,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final core = widget.core;
      final status = core.status;
      final needsAttention = (core.accounts?.accounts ?? const [])
          .where((a) => a.enabled && a.needsSignIn)
          .length;
      if (widget.settings.firstRun && status != null) {
        return WelcomePage(core: core, settings: widget.settings);
      }
      const pages = [
        _Page.overview,
        _Page.servers,
        _Page.accounts,
        _Page.logs,
        _Page.settings,
        _Page.help,
        _Page.about,
      ];
      final page = pages.contains(_page) ? _page : _Page.overview;
      Widget accountsIcon(IconData icon) => Badge(
        isLabelVisible: needsAttention > 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
        label: Text('$needsAttention'),
        child: Icon(icon),
      );
      final items = [
        for (final p in pages)
          switch (p) {
            _Page.overview => (
              const Icon(Icons.dashboard_outlined),
              const Icon(Icons.dashboard_rounded),
              l.navOverview,
            ),
            _Page.servers => (
              const Icon(Icons.public_outlined),
              const Icon(Icons.public_rounded),
              l.navServers,
            ),
            _Page.accounts => (
              accountsIcon(Icons.people_outline_rounded),
              accountsIcon(Icons.people_rounded),
              l.navAccounts,
            ),
            _Page.logs => (
              const Icon(Icons.receipt_long_outlined),
              const Icon(Icons.receipt_long_rounded),
              l.navLogs,
            ),
            _Page.settings => (
              const Icon(Icons.settings_outlined),
              const Icon(Icons.settings_rounded),
              l.navSettings,
            ),
            _Page.help => (
              const Icon(Icons.help_outline_rounded),
              const Icon(Icons.help_rounded),
              'Help',
            ),
            _Page.about => (
              const Icon(Icons.info_outline_rounded),
              const Icon(Icons.info_rounded),
              l.navAbout,
            ),
          },
      ];
      final showTopBar =
          status != null && MediaQuery.sizeOf(context).height >= 540;
      final content = Column(
        children: [
          if (core.unavailable != null && status != null) const _LostBanner(),
          if (showTopBar)
            _DesktopStatusBar(
              core: core,
              status: status,
              onOpenHelp: () => setState(() => _page = _Page.help),
              onOpenLogs: () => setState(() => _page = _Page.logs),
            ),
          Expanded(
            child: status == null
                ? _NoCore(core: core)
                : switch (page) {
                    _Page.overview => OverviewPage(
                      core: core,
                      settings: widget.settings,
                      onOpenServers: () =>
                          setState(() => _page = _Page.servers),
                      onOpenAccounts: () =>
                          setState(() => _page = _Page.accounts),
                      onOpenConnection: () => setState(() {
                        _page = _Page.settings;
                        _settingsOpening = SettingsSection.connection;
                      }),
                      onOpenUpstreamProxy: () => setState(() {
                        _page = _Page.settings;
                        _settingsOpening = SettingsSection.upstreamProxy;
                      }),
                    ),
                    _Page.servers => ServersPage(
                      core: core,
                      settings: widget.settings,
                    ),
                    _Page.accounts => AccountsPage(
                      core: core,
                      settings: widget.settings,
                    ),
                    _Page.logs => LogsPage(
                      core: core,
                      settings: widget.settings,
                    ),
                    _Page.settings => SettingsPage(
                      key: ValueKey(_settingsOpening),
                      core: core,
                      settings: widget.settings,
                      opening: _settingsOpening,
                      onOpenLogs: () => setState(() => _page = _Page.logs),
                    ),
                    _Page.help => HelpPage(
                      core: core,
                      onOpenLogs: () => setState(() => _page = _Page.logs),
                      onOpenServers: () =>
                          setState(() => _page = _Page.servers),
                      onOpenAccounts: () =>
                          setState(() => _page = _Page.accounts),
                    ),
                    _Page.about => AboutPage(core: core),
                  },
          ),
        ],
      );
      void select(int i) => setState(() {
        _page = pages[i];
        _settingsOpening = null;
      });
      if (Platform.isAndroid || MediaQuery.sizeOf(context).width < 640) {
        return MobileShell(
          core: core,
          settings: widget.settings,
          banner: core.unavailable != null && status != null
              ? const _LostBanner()
              : null,
          noCore: status == null ? _NoCore(core: core) : null,
        );
      }
      final scheme = Theme.of(context).colorScheme;
      return Scaffold(
        body: AnnouncementOverlay(
          settings: widget.settings,
          onOpenUpdates: () => setState(() => _page = _Page.about),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(color: scheme.outlineVariant, width: 1),
                  ),
                ),
                child: NavigationRail(
                  selectedIndex: pages.indexOf(page),
                  onDestinationSelected: select,
                  extended: true,
                  minExtendedWidth: 200,
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const AppLogo(size: 36),
                            const SizedBox(width: 10),
                            Text(
                              l.appTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontFamily: 'Georgia',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const GothicDivider(width: 164),
                      ],
                    ),
                  ),
                  destinations: [
                    for (final (icon, selected, label) in items)
                      NavigationRailDestination(
                        icon: icon,
                        selectedIcon: selected,
                        label: Text(label),
                      ),
                  ],
                  trailing: _TrafficPanel(traffic: status?.traffic),
                  trailingAtBottom: true,
                  scrollable: true,
                ),
              ),
              Expanded(
                child: page == _Page.overview || status == null
                    ? content
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1040),
                          child: content,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Compact Victorian Gothic top status bar for the Windows desktop shell.
class _DesktopStatusBar extends StatelessWidget {
  const _DesktopStatusBar({
    required this.core,
    required this.status,
    required this.onOpenHelp,
    required this.onOpenLogs,
  });

  final CoreController core;
  final CoreStatus status;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenLogs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final proxy = status.proxy;
    final listen = proxy?.listen ?? '';
    final transport = proxy?.transport ?? '';
    final readyCount = status.readyAccounts;
    final totalCount = status.totalAccounts;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_moon_outlined,
            size: 15,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'VICTORIAN GOTHIC EDITION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (transport.isNotEmpty) ...[
            Pill(transport),
            const SizedBox(width: 8),
          ],
          if (listen.isNotEmpty) ...[
            Pill(ltr(listen), icon: Icons.lan_outlined),
            const SizedBox(width: 8),
          ],
          if (totalCount > 0) ...[
            Pill(
              '$readyCount/$totalCount',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 17,
            onPressed: () => runShowingErrors(context, core.refresh),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
    );
  }
}

/// The side menu's traffic: the speed now and the total since the core
/// started, through Mozilla, up and down.
class _TrafficPanel extends StatelessWidget {
  const _TrafficPanel({required this.traffic});

  final Traffic? traffic;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = traffic;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: SizedBox(
        width: 172,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TrafficCard(
              title: l.liveTraffic,
              up: formatRate(t?.upRate ?? 0),
              down: formatRate(t?.downRate ?? 0),
            ),
            const SizedBox(height: 8),
            _TrafficCard(
              title: l.totalTraffic,
              up: formatBytes(t?.up ?? 0),
              down: formatBytes(t?.down ?? 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficCard extends StatelessWidget {
  const _TrafficCard({
    required this.title,
    required this.up,
    required this.down,
  });

  final String title;
  final String up;
  final String down;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget line(IconData icon, Color color, String text) => Row(
      children: [
        Icon(icon, size: 14, color: color),
        const Spacer(),
        Text(text, style: value),
      ],
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          line(Icons.arrow_upward_rounded, StatusColors.good, up),
          line(Icons.arrow_downward_rounded, scheme.primary, down),
        ],
      ),
    );
  }
}

class _LostBanner extends StatelessWidget {
  const _LostBanner();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: StatusColors.bad.withValues(alpha: 0.14),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
    child: Row(
      children: [
        const Icon(Icons.link_off_rounded, size: 18, color: StatusColors.bad),
        const SizedBox(width: 10),
        Expanded(child: Text(AppLocalizations.of(context).coreLost)),
      ],
    ),
  );
}

class _NoCore extends StatelessWidget {
  const _NoCore({required this.core});

  final CoreController core;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final problem = core.unavailable;
    final portTaken =
        problem != null &&
        (problem.problem == CoreProblem.portInUse ||
            problem.problem == CoreProblem.refused);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (problem == null || problem.problem == CoreProblem.starting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l.startingCore, style: theme.textTheme.titleMedium),
            ] else ...[
              Icon(
                Icons.power_off_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(l.cantReachCore, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                describeProblem(l, problem),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (portTaken && core.moveStoppedCore != null)
                    FilledButton.icon(
                      onPressed: () async {
                        final port = await showPortDialog(
                          context,
                          taken: problem.detail,
                        );
                        if (port != null && context.mounted) {
                          await runShowingErrors(
                            context,
                            () => core.setAppPort(port),
                          );
                        }
                      },
                      icon: const Icon(Icons.settings_ethernet_rounded),
                      label: Text(l.changePort),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: core.retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l.retry),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
