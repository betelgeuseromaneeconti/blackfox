import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/core_controller.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';
import 'widgets.dart';

/// Dedicated Help & Technical Reference page for BLACKFOX (Windows & Android).
/// Explains how to connect applications, copy SOCKS5/HTTP proxy addresses and
/// v2ray/NekoBox URIs, TCP/UDP port limitations, routing, TUN mode, DNS,
/// multi-account rotation, and connection troubleshooting.
class HelpPage extends StatefulWidget {
  const HelpPage({
    super.key,
    required this.core,
    this.onOpenLogs,
    this.onOpenServers,
    this.onOpenAccounts,
    this.onOpenSettings,
  });

  final CoreController core;
  final VoidCallback? onOpenLogs;
  final VoidCallback? onOpenServers;
  final VoidCallback? onOpenAccounts;
  final VoidCallback? onOpenSettings;

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  CoreController get core => widget.core;
  VoidCallback? get onOpenLogs => widget.onOpenLogs;
  VoidCallback? get onOpenServers => widget.onOpenServers;
  VoidCallback? get onOpenAccounts => widget.onOpenAccounts;
  VoidCallback? get onOpenSettings => widget.onOpenSettings;

  late Future<Map<String, Object?>?> _config;

  @override
  void initState() {
    super.initState();
    _config = _readConfig();
  }

  Future<Map<String, Object?>?> _readConfig() async {
    try {
      return await core.settings();
    } catch (_) {
      // Help remains available while the core is starting or offline.
      return null;
    }
  }

  String _listenAddress([Map<String, Object?>? config]) {
    final current = core.status?.proxy?.listen ?? '';
    if (current.isNotEmpty) return current;
    final proxy = config?['proxy'];
    if (proxy is Map) {
      final listen = proxy['listen'];
      if (listen is String && listen.isNotEmpty) return listen;
    }
    return '127.0.0.1:10810';
  }

  String _socksUri(String listen, [Map<String, Object?>? config]) {
    final proxy = config?['proxy'];
    final user = proxy is Map && proxy['username'] is String
        ? proxy['username'] as String
        : '';
    final pass = proxy is Map && proxy['password'] is String
        ? proxy['password'] as String
        : '';
    if (user.isNotEmpty && pass.isNotEmpty) {
      final auth = base64Url.encode(utf8.encode('$user:$pass')).replaceAll('=', '');
      return 'socks://$auth@$listen#BLACKFOX';
    }
    return 'socks://$listen#BLACKFOX';
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).copied(text)),
          behavior: SnackBarBehavior.floating,
          width: 420,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final listen = _listenAddress();
    final socksUri = _socksUri(listen);
    final wide = MediaQuery.sizeOf(context).width >= 760;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageTitle('Help'),
              if (!OwnTopBar.of(context)) const SizedBox(height: 20),

              // 1. Connecting Applications & Local Proxy Endpoints
              Panel(
                title: 'CONNECTING APPLICATIONS · SOCKS5 & HTTP PROXY',
                icon: Icons.lan_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BLACKFOX exposes a single local proxy port that automatically accepts both SOCKS5 (with UDP Associate) and HTTP/HTTPS CONNECT traffic on the same address.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, Object?>?>(
                      future: _config,
                      builder: (context, snapshot) {
                        final config = snapshot.data;
                        final listen = _listenAddress(config);
                        final socksUri = _socksUri(listen, config);
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _EndpointBox(
                              label: 'SOCKS5 / HTTP Proxy Address',
                              value: ltr(listen),
                              buttonLabel: l.copyAll,
                              onCopy: () => _copy(context, listen),
                            ),
                            _EndpointBox(
                              label: 'Proxy URI (v2rayN / v2rayNG / NekoBox)',
                              value: ltr(socksUri),
                              buttonLabel: 'Copy URI',
                              onCopy: () => _copy(context, socksUri),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '• Browsers (Firefox, Chrome, Brave) and desktop apps (Telegram, Discord) can either use System Proxy mode, TUN mode, or point directly to the local proxy address shown above.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Technical Limitations: TCP & UDP Ports
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _tcpLimitsPanel(theme, scheme)),
                    const SizedBox(width: 16),
                    Expanded(child: _udpLimitsPanel(theme, scheme)),
                  ],
                )
              else ...[
                _tcpLimitsPanel(theme, scheme),
                const SizedBox(height: 16),
                _udpLimitsPanel(theme, scheme),
              ],
              const SizedBox(height: 16),

              // 3. TUN, Smart Routing, and DNS Architecture
              Panel(
                title: 'TUN MODE, SMART ROUTING & DNS',
                icon: Icons.alt_route_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HelpTopic(
                      title: 'TUN Mode & Per-App Bypass',
                      body:
                          'On Windows, TUN mode creates a virtual Wintun network adapter managed by the BLACKFOX TUN service so all system traffic goes through the tunnel. You can bypass specific executables (or only their UDP traffic for voice/gaming) in Settings → TUN settings. On Android, VpnService routes device traffic with per-app include/exclude support.',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: GothicDivider(),
                    ),
                    _HelpTopic(
                      title: 'Smart Regional Routing',
                      body:
                          'When Regional Routing is enabled (Iran, China, Russia, Afghanistan, Turkey, Indonesia, Brazil), local domestic domains and IPs connect directly without consuming VPN quota, while international traffic uses the encrypted tunnel. Custom domain, IP, CIDR, and geosite/geoip rules can be configured in Settings → Routing.',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: GothicDivider(),
                    ),
                    _HelpTopic(
                      title: 'Encrypted DNS (DoH / DoT)',
                      body:
                          'DNS queries for proxied destinations are resolved through the tunnel using Cloudflare, Google, Quad9, or custom DoH/DoT resolvers to prevent DNS poisoning and leaks.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Multi-Account Rotation & Server Selection
              Panel(
                title: 'MULTI-ACCOUNT ROTATION & SERVERS',
                icon: Icons.verified_user_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HelpTopic(
                      title: 'Choosing a Server',
                      body:
                          'Use Auto (Recommended) for balanced routing, Auto (Fastest) for lowest measured RTT, or select any country manually on the Servers page. Use Test real delay to measure end-to-end HTTP latency across all exit locations.',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: GothicDivider(),
                    ),
                    _HelpTopic(
                      title: 'Multi-Account Failover & Quota Switching',
                      body:
                          'Add multiple Firefox Accounts in the Accounts tab and order them by priority. When the active account reaches the configured switch threshold (default 95%) or requires re-authentication, BLACKFOX automatically switches to the next ready account.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Common Errors, Troubleshooting & Diagnostics
              Panel(
                title: 'COMMON ERRORS & TROUBLESHOOTING',
                icon: Icons.build_circle_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HelpTopic(
                      title: 'Sign-In Blocked (HTTP 406) or Unreachable',
                      body:
                          'If Mozilla blocks direct API sign-in or the authentication service is filtered on your network, enable the Shared Relay or configure a Personal Relay in Settings → Relay server, or switch the Sign-In Method on the Accounts page to In-App Browser.',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: GothicDivider(),
                    ),
                    _HelpTopic(
                      title: 'TLS Handshake Timeouts on Censored Networks',
                      body:
                          'Enable TLS Fragmentation (Automatic, Record 0x16 split, or SNI split) in Settings → TLS fragmentation, or configure an Upstream SOCKS5 Proxy if direct connections to edge proxies are throttled.',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: GothicDivider(),
                    ),
                    _HelpTopic(
                      title: 'Live Logs & Connection Inspector',
                      body:
                          'Inspect real-time proxy logs, refused port notices, and active TCP/UDP connections in the Logs / Activity view. Sensitive tokens and passwords are never written to logs.',
                    ),
                    if (onOpenLogs != null ||
                        onOpenServers != null ||
                        onOpenAccounts != null) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (onOpenLogs != null)
                            OutlinedButton.icon(
                              onPressed: onOpenLogs,
                              icon: const Icon(Icons.article_outlined, size: 18),
                              label: Text(l.navLogs),
                            ),
                          if (onOpenServers != null)
                            OutlinedButton.icon(
                              onPressed: onOpenServers,
                              icon: const Icon(Icons.public_rounded, size: 18),
                              label: Text(l.navServers),
                            ),
                          if (onOpenAccounts != null)
                            OutlinedButton.icon(
                              onPressed: onOpenAccounts,
                              icon: const Icon(Icons.people_outline_rounded, size: 18),
                              label: Text(l.navAccounts),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tcpLimitsPanel(ThemeData theme, ColorScheme scheme) => Panel(
    title: 'TCP PORT LIMITATIONS',
    icon: Icons.cable_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Pill('Allowed TCP: 80, 443, 8080, 8443'),
        const SizedBox(height: 12),
        Text(
          'Mozilla\'s edge proxy network only forwards TCP connections to web ports 80, 443, 8080, and 8443. Other TCP ports (such as 22 for SSH, 465/587/993 for mail, or 5228 for push notifications) are refused by the remote proxy.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tip: For Git over SSH, configure ssh.github.com on port 443 or add your SSH client to Direct routing rules.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface,
          ),
        ),
      ],
    ),
  );

  Widget _udpLimitsPanel(ThemeData theme, ColorScheme scheme) => Panel(
    title: 'UDP PORT LIMITATIONS',
    icon: Icons.graphic_eq_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Pill('Allowed UDP: 80, 443, 3478, 8080, 8443, 49152–65534'),
        const SizedBox(height: 12),
        Text(
          'UDP forwarding (MASQUE CONNECT-UDP over HTTP/3) supports HTTP/3 (QUIC on 443), STUN (3478), and WebRTC ephemeral ports (49152–65534). Custom game or VoIP UDP ports outside this range cannot traverse the tunnel.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tip: Set games or voice apps to "UDP only" bypass in Settings → TUN settings so their UDP packets go directly while TCP stays protected.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface,
          ),
        ),
      ],
    ),
  );
}

class _EndpointBox extends StatelessWidget {
  const _EndpointBox({
    required this.label,
    required this.value,
    required this.buttonLabel,
    required this.onCopy,
  });

  final String label;
  final String value;
  final String buttonLabel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Consolas',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _HelpTopic extends StatelessWidget {
  const _HelpTopic({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
