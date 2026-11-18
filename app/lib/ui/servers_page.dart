import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_settings.dart';
import '../core/core_api.dart';
import '../core/core_controller.dart';
import '../core/models.dart';
import '../l10n/app_localizations.dart';
import 'browser_signin.dart';
import 'format.dart';
import 'widgets.dart';

/// BLACKFOX Server Selection page for Windows Desktop and Android Mobile.
/// Supports Auto (Recommended), Auto (Fastest), manual country selection,
/// live search by country/city/ISO code, sorting by Real Latency or Name,
/// Test Real Delay, and server list refresh.
class ServersPage extends StatefulWidget {
  const ServersPage({super.key, required this.core, required this.settings});

  final CoreController core;
  final AppSettings settings;

  @override
  State<ServersPage> createState() => _ServersPageState();
}

const _pingStale = Duration(minutes: 10);

class _ServersPageState extends State<ServersPage> {
  List<Location>? _locations;
  DateTime? _pingedAt;
  String _country = '';
  bool _testing = false;
  bool _sortByName = false;
  String _query = '';
  final _searchController = TextEditingController();

  /// The choice being saved ('' recommended, 'fastest', or a code).
  String? _busy;
  String? _summary;

  CoreController get _core => widget.core;

  bool get _noAccounts => _core.status?.totalAccounts == 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _core.call((api) => api.locations());
      final config = await _core.settings();
      if (!mounted) return;
      setState(() {
        _locations = list.locations;
        _pingedAt = list.pingedAt;
        if (config['proxy'] case {'country': final String country}) {
          _country = country;
        }
      });
      final at = _pingedAt;
      if (!_noAccounts &&
          (at == null || DateTime.now().difference(at) > _pingStale)) {
        unawaited(_test());
      }
    } on CoreApiException catch (e) {
      if (mounted) showError(context, e.message);
    } on CoreUnavailable {
      // The shell shows it.
    }
  }

  Future<void> _choose(String country) async {
    if (_busy != null || _country.toLowerCase() == country.toLowerCase()) {
      return;
    }
    setState(() => _busy = country);
    final ok = await runShowingErrors(
      context,
      () => _core.setLocation(country),
    );
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (ok) _country = country;
    });
  }

  Future<void> _test({bool fresh = false}) async {
    final l = AppLocalizations.of(context);
    final codes = [
      for (final loc in _locations ?? const <Location>[]) loc.code,
    ];
    setState(() {
      _testing = true;
      _summary = null;
    });
    try {
      final result = await _core.call(
        (api) => api.pingLocations(codes, fresh: fresh),
      );
      final tested = {for (final loc in result.locations) loc.code: loc};
      if (!mounted) return;
      setState(() {
        _locations = [
          for (final loc in _locations ?? const <Location>[])
            tested[loc.code] ?? loc,
        ];
        _pingedAt = result.pingedAt ?? DateTime.now();
        final answered = result.locations.where((loc) => loc.answered).length;
        _summary = l.delaySummary(answered, result.locations.length);
      });
    } on CoreApiException {
      if (mounted) showError(context, l.delayTestFailed);
    } on CoreUnavailable catch (e) {
      if (mounted) showError(context, describeProblem(l, e));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  List<Location> _countries(AppLocalizations l) {
    final q = foldForSearch(_query);
    final list = [
      for (final loc in _locations ?? const <Location>[])
        if (!isRecommendedPlace(loc.code) &&
            (q.isEmpty ||
                foldForSearch(locationName(l, loc.code, loc.name)).contains(q) ||
                foldForSearch(loc.city).contains(q) ||
                foldForSearch(loc.code).contains(q)))
          loc,
    ];
    list.sort((a, b) {
      if (!_sortByName) {
        final da = a.answered ? a.pingMs : 1 << 30;
        final db = b.answered ? b.pingMs : 1 << 30;
        if (da != db) return da.compareTo(db);
      }
      return nameSortKey(
        l.localeName,
        locationName(l, a.code, a.name),
      ).compareTo(nameSortKey(l.localeName, locationName(l, b.code, b.name)));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final chosen = _country.toLowerCase();
    final countries = _countries(l);
    final recommended = (_locations ?? const <Location>[])
        .where((loc) => isRecommendedPlace(loc.code))
        .firstOrNull;
    final delayLine =
        _summary ??
        (_pingedAt == null ? null : l.testedAgo(formatAgo(l, _pingedAt!)));
    final noAccounts = _noAccounts;
    return ListView(
      padding: pagePadding(context),
      children: [
        PageTitle(l.navServers),
        if (noAccounts) ...[
          NoAccountsPanel(
            onAdd: () => startAddAccount(context, _core, widget.settings),
          ),
          const SizedBox(height: 12),
        ],
        _SectionHeader(title: l.autoSection),
        _ChoiceCard(
          children: [
            _ChoiceRow(
              leading: const CountryFlag(code: 'REC', width: 36),
              title: l.modeRecommended,
              subtitle: l.modeRecommendedHint,
              delay: recommended == null
                  ? null
                  : _Delay(location: recommended, testing: _testing),
              selected: chosen == '',
              busy: _busy == '',
              onTap: () => _choose(''),
            ),
            _ChoiceRow(
              leading: const _IconTile(icon: Icons.bolt_rounded),
              title: l.modeFastest,
              subtitle: l.modeFastestHint,
              selected: chosen == 'fastest',
              busy: _busy == 'fastest',
              onTap: () => _choose('fastest'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: l.locationsSection,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: () => setState(() => _sortByName = !_sortByName),
                icon: Icon(
                  _sortByName
                      ? Icons.sort_by_alpha_rounded
                      : Icons.speed_rounded,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: _testing ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
              TextButton.icon(
                onPressed: !_testing && _locations != null && !noAccounts
                    ? () => _test(fresh: true)
                    : null,
                icon: _testing
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.speed_rounded, size: 18),
                label: Text(_testing ? l.testingDelay : l.testDelay),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: l.search,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _query = '';
                      }),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (delayLine != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
            child: Text(delayLine, style: muted),
          ),
        if (_locations == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (countries.isEmpty)
          Panel(child: Text(l.noServers, style: muted))
        else
          _ChoiceCard(
            children: [
              for (final loc in countries)
                _ChoiceRow(
                  leading: CountryFlag(code: loc.code, width: 36),
                  title: locationName(l, loc.code, loc.name),
                  subtitle: _subtitle(loc),
                  delay: _Delay(location: loc, testing: _testing),
                  selected: chosen == loc.code.toLowerCase(),
                  busy: _busy?.toLowerCase() == loc.code.toLowerCase(),
                  onTap: () => _choose(loc.code),
                ),
            ],
          ),
      ],
    );
  }

  String? _subtitle(Location loc) =>
      loc.city.isNotEmpty && loc.city != loc.name ? loc.city : null;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 0, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          children[i],
        ],
      ],
    ),
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 27,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.55),
          width: 0.75,
        ),
      ),
      child: Icon(icon, size: 18, color: scheme.onSecondaryContainer),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.leading,
    required this.title,
    required this.selected,
    required this.busy,
    required this.onTap,
    this.subtitle,
    this.delay,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? delay;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (delay != null) ...[const SizedBox(width: 10), delay!],
              const SizedBox(width: 6),
              SizedBox.square(
                dimension: 24,
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(3),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected ? scheme.primary : scheme.outline,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Delay extends StatelessWidget {
  const _Delay({required this.location, required this.testing});

  final Location location;
  final bool testing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final loc = location;
    final (text, color) = testing
        ? ('', muted)
        : loc.answered
        ? (l.milliseconds(loc.pingMs), delayColor(loc.pingMs))
        : loc.pingError.isNotEmpty
        ? (l.noAnswer, muted)
        : ('—', muted);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.75),
      ),
      child: testing
          ? SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: muted),
            )
          : Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
    if (testing || !loc.cached) return chip;
    return Tooltip(
      message: l.delayFromLastTest,
      child: Opacity(opacity: 0.5, child: chip),
    );
  }
}
