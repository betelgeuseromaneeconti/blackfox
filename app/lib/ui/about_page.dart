import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../core/core_controller.dart';
import '../core/updates.dart';
import '../l10n/app_localizations.dart';
import '../platform.dart';
import 'widgets.dart';

/// Redesigned BLACKFOX Victorian Gothic About page.
/// Displays the BLACKFOX Kitsune crest, BLACKFOX, Version 1.0.3, live Core
/// version, update-check action, source-code action, data folder / web
/// dashboard access, and ends with the exact creator signature
/// "Made by Jackdaw" with nothing appearing after it.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key, required this.core});

  final CoreController core;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _checking = false;
  String? _result;
  Release? _release;

  @override
  void initState() {
    super.initState();
    _release = Updates.available.value;
  }

  Future<void> _check() async {
    final l = AppLocalizations.of(context);
    if (githubRepo.isEmpty) {
      setState(() => _result = l.repoNotSet);
      return;
    }
    setState(() {
      _checking = true;
      _result = null;
      _release = null;
    });
    try {
      final release = await checkForUpdate(
        check: UpdateCheck.manual,
        proxy: updateProxy(widget.core.status),
        onAnnouncements: Updates.receiveAnnouncements,
      );
      Updates.found(release, check: UpdateCheck.manual);
      if (!mounted) return;
      setState(() {
        _release = release;
        _result = release == null
            ? l.upToDate
            : release.mandatory
            ? l.updateRequired(release.version)
            : l.updateAvailable(release.version);
      });
    } on Exception catch (e) {
      final network =
          e is SocketException || e is TimeoutException || e is TlsException;
      if (mounted) {
        setState(
          () => _result = network
              ? l.updateCheckNoNetwork
              : l.updateCheckFailed('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = widget.core.status;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final github = githubRepo.isEmpty ? '' : 'https://github.com/$githubRepo';
    return ListView(
      padding: pagePadding(context),
      children: [
        PageTitle(l.navAbout),
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Panel(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                children: [
                  const AppLogo(size: 88),
                  const SizedBox(height: 16),
                  Text(
                    'BLACKFOX',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Version $appVersion',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.unofficialNote,
                    style: muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const GothicDivider(centered: true),
                  const SizedBox(height: 20),
                  _Line(label: l.appVersionLabel, value: appVersion),
                  const Divider(height: 24),
                  _Line(
                    label: l.coreVersionLabel,
                    value: status?.version ?? '—',
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.checkUpdates,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _checking ? null : _check,
                        icon: _checking
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.update_rounded, size: 18),
                        label: Text(
                          _checking ? l.checkingUpdates : l.checkUpdates,
                        ),
                      ),
                    ],
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(_result!, style: muted),
                    ),
                  ],
                  if (_release case final release?) ...[
                    const SizedBox(height: 10),
                    _UpdateAction(core: widget.core, release: release),
                  ],
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.sourceCode,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text('GNU General Public License v3.0', style: muted),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: github.isEmpty
                            ? null
                            : () => openLink(context, github),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('GitHub'),
                      ),
                    ],
                  ),
                  if (Platform.isAndroid) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.webDashboard,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(l.webDashboardHint, style: muted),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => runShowingErrors(
                            context,
                            () async =>
                                openUrl('${await widget.core.dashboardLink()}'),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(l.webDashboardOpen),
                        ),
                      ],
                    ),
                  ],
                  if (!Platform.isAndroid &&
                      status != null &&
                      status.dataDir.isNotEmpty) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.dataFolder,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status.dataDir,
                                style: muted,
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              runShowingErrors(context, widget.core.openFolder),
                          icon: const Icon(Icons.folder_open_rounded, size: 18),
                          label: Text(l.openFolder),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const GothicDivider(centered: true),
                  const SizedBox(height: 18),
                  Text(
                    'Made by Jackdaw',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdateAction extends StatelessWidget {
  const _UpdateAction({required this.core, required this.release});

  final CoreController core;
  final Release release;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([core, Updates.failure]),
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final muted = Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
      final update = core.status?.update;
      Widget button(String label, IconData icon, VoidCallback? onPressed) =>
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
            ),
          );
      if (update == null) {
        return release.url.isEmpty
            ? const SizedBox.shrink()
            : button(
                l.download,
                Icons.download_rounded,
                () => openDownload(context, release),
              );
      }
      final mine = update.version == release.version;
      if (mine && (update.downloading || update.installing)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              update.downloading
                  ? l.updateDownloading(release.version)
                  : l.updateInstalling(release.version),
              style: muted,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: update.downloading ? update.progress : null,
            ),
          ],
        );
      }
      final failure =
          Updates.failure.value ??
          (mine && update.failed ? update.error : null);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            Tooltip(
              message: failure,
              child: Text(l.updateFailed(release.version), style: muted),
            ),
            const SizedBox(height: 8),
          ],
          button(
            failure != null ? l.tryAgain : l.updateNow,
            failure != null
                ? Icons.refresh_rounded
                : Icons.system_update_alt_rounded,
            () => Updates.update(release),
          ),
        ],
      );
    },
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}
