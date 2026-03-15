import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/layout.dart';
import '../../../domain/entities/session_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../controllers/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    if (!state.isConfigured) {
      return const EmptyState(
        icon: Icons.dns_rounded,
        title: 'Connect a server',
        message:
            'Add a Transmission server profile to see live transfer stats.',
      );
    }

    if (state.isLoading && state.sessionInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.sessionInfo == null) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load dashboard',
        message: state.errorMessage!,
      );
    }

    final sessionInfo = state.sessionInfo;
    final stats = state.sessionStats;
    final freeSpace = state.freeSpaceInfo;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layout = AppLayout.fromWidth(width);
        final padding = AppLayout.horizontalPadding(width);
        final statColumns = switch (layout) {
          AppLayoutSize.compact => 2,
          AppLayoutSize.medium => 2,
          AppLayoutSize.expanded => 4,
        };
        final sectionColumns = layout == AppLayoutSize.expanded ? 2 : 1;

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(padding, 12, padding, 24),
            children: [
              _DashboardHero(
                sessionInfo: sessionInfo,
                stats: stats,
                freeSpace: freeSpace,
                lastUpdated: state.lastUpdated,
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                _DashboardErrorBanner(message: state.errorMessage!),
              ],
              const SizedBox(height: 16),
              _DashboardGrid(
                columns: statColumns,
                children: [
                  _MetricTile(
                    icon: Icons.download_rounded,
                    label: 'Download',
                    value: Formatters.speed(stats?.downloadSpeed ?? 0),
                    tone: _MetricTone.primary,
                  ),
                  _MetricTile(
                    icon: Icons.upload_rounded,
                    label: 'Upload',
                    value: Formatters.speed(stats?.uploadSpeed ?? 0),
                    tone: _MetricTone.secondary,
                  ),
                  _MetricTile(
                    icon: Icons.bolt_rounded,
                    label: 'Active torrents',
                    value: '${stats?.activeTorrentCount ?? 0}',
                    tone: _MetricTone.neutral,
                  ),
                  _MetricTile(
                    icon: Icons.storage_rounded,
                    label: 'Free space',
                    value: Formatters.bytes(freeSpace?.sizeBytes ?? 0),
                    tone: _MetricTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionGrid(
                columns: sectionColumns,
                children: [
                  _InfoSection(
                    title: 'Session',
                    subtitle: 'Current remote client state',
                    items: [
                      _InfoItem(
                        label: 'Version',
                        value: sessionInfo?.version ?? 'Unknown',
                      ),
                      _InfoItem(
                        label: 'RPC version',
                        value: '${sessionInfo?.rpcVersion ?? 0}',
                      ),
                      _InfoItem(
                        label: 'Download directory',
                        value: sessionInfo?.downloadDir ?? 'Unknown',
                      ),
                      _InfoItem(
                        label: 'Alternative speed',
                        value:
                            (sessionInfo?.altSpeedEnabled ?? false)
                                ? 'Enabled'
                                : 'Disabled',
                      ),
                      _InfoItem(
                        label: 'Encryption',
                        value: _encryptionLabel(sessionInfo?.encryptionMode),
                      ),
                      _InfoItem(
                        label: 'Queue size',
                        value:
                            '${sessionInfo?.downloadQueueSize ?? 0} down / ${sessionInfo?.seedQueueSize ?? 0} seed',
                      ),
                    ],
                  ),
                  _InfoSection(
                    title: 'Lifetime',
                    subtitle: 'Overall transfer totals',
                    items: [
                      _InfoItem(
                        label: 'Downloaded',
                        value: Formatters.bytes(
                          stats?.cumulativeDownloadedBytes ?? 0,
                        ),
                      ),
                      _InfoItem(
                        label: 'Uploaded',
                        value: Formatters.bytes(
                          stats?.cumulativeUploadedBytes ?? 0,
                        ),
                      ),
                      _InfoItem(
                        label: 'Ratio',
                        value: _lifetimeRatio(stats),
                      ),
                      _InfoItem(
                        label: 'Files added',
                        value: '${stats?.filesAdded ?? 0}',
                      ),
                      _InfoItem(
                        label: 'Sessions',
                        value: '${stats?.sessionCount ?? 0}',
                      ),
                      _InfoItem(
                        label: 'Active now',
                        value: '${stats?.activeTorrentCount ?? 0}',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _lifetimeRatio(SessionStats? stats) {
    final downloaded = stats?.cumulativeDownloadedBytes ?? 0;
    final uploaded = stats?.cumulativeUploadedBytes ?? 0;
    if (downloaded <= 0) {
      return uploaded > 0 ? 'Infinite' : '0.00';
    }
    return (uploaded / downloaded).toStringAsFixed(2);
  }

  static String _encryptionLabel(EncryptionMode? mode) {
    return switch (mode) {
      EncryptionMode.required => 'Required',
      EncryptionMode.preferred => 'Preferred',
      EncryptionMode.tolerated => 'Tolerated',
      null => 'Unknown',
    };
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.sessionInfo,
    required this.stats,
    required this.freeSpace,
    required this.lastUpdated,
  });

  final SessionInfo? sessionInfo;
  final SessionStats? stats;
  final FreeSpaceInfo? freeSpace;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalSpeed =
        (stats?.downloadSpeed ?? 0) + (stats?.uploadSpeed ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.92),
            scheme.secondaryContainer.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.speed_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer overview',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sessionInfo?.version ?? 'Transmission server',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              _HeroStat(
                label: 'Combined speed',
                value: Formatters.speed(totalSpeed),
              ),
              _HeroStat(
                label: 'Free space',
                value: Formatters.bytes(freeSpace?.sizeBytes ?? 0),
              ),
              _HeroStat(
                label: 'Last updated',
                value: Formatters.dateTime(lastUpdated),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onPrimaryContainer = Theme.of(context).colorScheme.onPrimaryContainer;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: onPrimaryContainer.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: columns >= 4 ? 112 : 120,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            children[index],
          ],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 360,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

enum _MetricTone { primary, secondary, neutral }

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final Color background;
    final Color accent;
    final Color foreground;

    switch (tone) {
      case _MetricTone.primary:
        background = scheme.primaryContainer.withValues(alpha: 0.62);
        accent = scheme.primary;
        foreground = scheme.onPrimaryContainer;
      case _MetricTone.secondary:
        background = scheme.secondaryContainer.withValues(alpha: 0.56);
        accent = scheme.secondary;
        foreground = scheme.onSecondaryContainer;
      case _MetricTone.neutral:
        background = scheme.surfaceContainerHigh;
        accent = scheme.tertiary;
        foreground = scheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              Divider(
                height: 20,
                color: scheme.outlineVariant.withValues(alpha: 0.2),
              ),
            _InfoRow(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            item.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            item.value,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
