import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/dto/torrent_dto.dart';
import '../../../domain/entities/torrent.dart';
import '../../../domain/repositories/transmission_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../../controllers/torrent_detail_controller.dart';
import '../../controllers/torrent_list_controller.dart';

class TorrentDetailsView extends ConsumerWidget {
  const TorrentDetailsView({
    super.key,
    required this.torrentId,
    this.showBodyAction = true,
    this.showBodyTitle = true,
  });

  final int torrentId;
  final bool showBodyAction;
  final bool showBodyTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(torrentDetailControllerProvider(torrentId));
    final fallbackTorrent = _findFallbackTorrent(
      ref.watch(torrentListControllerProvider).torrents,
      torrentId,
    );
    final resolvedTorrent = detailAsync.valueOrNull ?? fallbackTorrent;

    if (resolvedTorrent == null) {
      return detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Unable to load torrent',
          message: '$error',
        ),
        data: (_) => const EmptyState(
          icon: Icons.info_outline_rounded,
          title: 'No torrent selected',
          message:
              'Pick a torrent to inspect files, trackers, peers, and actions.',
        ),
      );
    }

    return _TorrentDetailsContent(
      torrent: resolvedTorrent,
      detailError: detailAsync.hasError ? '${detailAsync.error}' : null,
      showBodyAction: showBodyAction,
      showBodyTitle: showBodyTitle,
    );
  }
}

class _TorrentDetailsContent extends ConsumerWidget {
  const _TorrentDetailsContent({
    required this.torrent,
    required this.detailError,
    required this.showBodyAction,
    required this.showBodyTitle,
  });

  final Torrent torrent;
  final String? detailError;
  final bool showBodyAction;
  final bool showBodyTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (detailError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              content: Text(detailError!),
              actions: [
                TextButton(
                  onPressed: () => ref
                      .read(
                        torrentDetailControllerProvider(torrent.id).notifier,
                      )
                      .refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        if (showBodyAction)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                tooltip: 'Torrent actions',
                onPressed: () => openTorrentActions(context, ref, torrent),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ),
          ),
        _TorrentOverviewCard(torrent: torrent, showTitle: showBodyTitle),
        const SizedBox(height: 16),
        _ExpandableSection(
          title: 'Files',
          subtitle: 'Load file list',
          initiallyExpanded: false,
          child: _TorrentFilesSection(torrentId: torrent.id),
        ),
        const SizedBox(height: 16),
        _ExpandableSection(
          title: 'Trackers',
          subtitle: '${torrent.trackers.length} trackers',
          initiallyExpanded: false,
          child: _TorrentTrackersSection(trackers: torrent.trackers),
        ),
        const SizedBox(height: 16),
        _ExpandableSection(
          title: 'Peers',
          subtitle: 'Load peer list',
          initiallyExpanded: false,
          child: _TorrentPeersSection(torrentId: torrent.id),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Transfer Stats',
          child: _MetricGrid(
            items: [
              ('Downloaded ever', Formatters.bytes(torrent.downloadedEver)),
              ('Uploaded ever', Formatters.bytes(torrent.uploadedEver)),
              ('Downloading time', '${torrent.secondsDownloading}s'),
              ('Seeding time', '${torrent.secondsSeeding}s'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Dates',
          child: _MetricGrid(
            items: [
              ('Added', Formatters.dateTime(torrent.addedDate)),
              ('Completed', Formatters.dateTime(torrent.doneDate)),
              ('Activity', Formatters.dateTime(torrent.activityDate)),
              ('Created', Formatters.dateTime(torrent.dateCreated)),
            ],
          ),
        ),
        if (torrent.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(title: 'Error', child: Text(torrent.errorMessage)),
        ],
      ],
    );
  }
}

class _TorrentOverviewCard extends StatelessWidget {
  const _TorrentOverviewCard({required this.torrent, required this.showTitle});

  final Torrent torrent;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InlineBadge(
                  label: statusLabel(torrent.status),
                  background: _detailStatusColor(
                    context,
                    torrent,
                  ).withValues(alpha: 0.14),
                  foreground: _detailStatusColor(context, torrent),
                ),
                _InlineBadge(
                  label: TorrentDto.primaryTrackerLabel(torrent),
                  background: scheme.surfaceContainerHighest,
                  foreground: scheme.onSurfaceVariant,
                  icon: Icons.language_rounded,
                ),
              ],
            ),
            if (showTitle) ...[
              const SizedBox(height: 12),
              Text(
                torrent.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
            if (torrent.downloadDir != null &&
                torrent.downloadDir!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      torrent.downloadDir!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: torrent.effectiveProgress,
                      color: _detailStatusColor(context, torrent),
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  Formatters.percentage(torrent.effectiveProgress),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MetricGrid(
              items: [
                ('Size', Formatters.bytes(torrent.totalSize)),
                ('ETA', Formatters.eta(torrent.etaSeconds)),
                ('Ratio', Formatters.ratio(torrent.uploadRatio)),
                ('Peers', '${torrent.peersConnected}'),
                ('Download', Formatters.speed(torrent.rateDownload)),
                ('Upload', Formatters.speed(torrent.rateUpload)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth >= 430
            ? 3
            : 2;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _MetricTile(label: item.$1, value: item.$2),
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  const _InlineBadge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (value) => setState(() => _expanded = value),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: widget.subtitle == null ? null : Text(widget.subtitle!),
          children: _expanded ? [widget.child] : const <Widget>[],
        ),
      ),
    );
  }
}

class _TorrentFilesSection extends ConsumerWidget {
  const _TorrentFilesSection({required this.torrentId});

  final int torrentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(torrentFilesControllerProvider(torrentId));
    return filesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$error'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref
                  .read(torrentFilesControllerProvider(torrentId).notifier)
                  .refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (files) {
        if (files.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No file information available.'),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: files.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final file = files[index];
            return _FileTile(torrentId: torrentId, file: file);
          },
        );
      },
    );
  }
}

class _TorrentTrackersSection extends StatelessWidget {
  const _TorrentTrackersSection({required this.trackers});

  final List<TorrentTracker> trackers;

  @override
  Widget build(BuildContext context) {
    if (trackers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No tracker information available.'),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trackers.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tracker = trackers[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tracker.displayLabel),
          subtitle: Text(tracker.announce),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Tier ${tracker.tier}'),
                Text(
                  tracker.lastAnnounceResult.isEmpty
                      ? 'No status'
                      : tracker.lastAnnounceResult,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TorrentPeersSection extends ConsumerWidget {
  const _TorrentPeersSection({required this.torrentId});

  final int torrentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peersAsync = ref.watch(torrentPeersControllerProvider(torrentId));
    return peersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$error'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref
                  .read(torrentPeersControllerProvider(torrentId).notifier)
                  .refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (peers) {
        if (peers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No peer information available.'),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: peers.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final peer = peers[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(peer.address),
              subtitle: Text(
                '${peer.clientName} • ${Formatters.percentage(peer.progress)}',
              ),
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Down ${Formatters.speed(peer.rateToClient)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Up ${Formatters.speed(peer.rateToPeer)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FileTile extends ConsumerWidget {
  const _FileTile({required this.torrentId, required this.file});

  final int torrentId;
  final TorrentFileEntry file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: file.wanted,
        onChanged: (value) async {
          await ref
              .read(torrentFilesControllerProvider(torrentId).notifier)
              .perform(
                (repo) => repo.setFilesWanted(
                  torrentId,
                  wanted: value == true ? [file.index] : const [],
                  unwanted: value == true ? const [] : [file.index],
                ),
              );
          await ref.read(torrentListControllerProvider.notifier).refresh();
        },
      ),
      title: Text(file.name),
      subtitle: Text(
        '${Formatters.bytes(file.length)} • ${Formatters.percentage(file.progress)}',
      ),
      trailing: DropdownButton<BandwidthPriority>(
        value: file.priority,
        items: BandwidthPriority.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.name)),
            )
            .toList(),
        onChanged: (value) async {
          if (value == null) {
            return;
          }
          final high = value == BandwidthPriority.high ? [file.index] : <int>[];
          final normal = value == BandwidthPriority.normal
              ? [file.index]
              : <int>[];
          final low = value == BandwidthPriority.low ? [file.index] : <int>[];
          await ref
              .read(torrentFilesControllerProvider(torrentId).notifier)
              .perform(
                (repo) => repo.setFilePriority(
                  torrentId,
                  high: high,
                  normal: normal,
                  low: low,
                ),
              );
          await ref.read(torrentListControllerProvider.notifier).refresh();
        },
      ),
    );
  }
}

Torrent? _findFallbackTorrent(List<Torrent> torrents, int torrentId) {
  for (final torrent in torrents) {
    if (torrent.id == torrentId) {
      return torrent;
    }
  }
  return null;
}

Color _detailStatusColor(BuildContext context, Torrent torrent) {
  final scheme = Theme.of(context).colorScheme;
  if (torrent.hasError) {
    return scheme.error;
  }
  return switch (torrent.status) {
    TorrentStatus.stopped => scheme.outline,
    TorrentStatus.queuedForVerification => scheme.secondary,
    TorrentStatus.verifying => scheme.secondary,
    TorrentStatus.queuedForDownload => scheme.primary.withValues(alpha: 0.6),
    TorrentStatus.downloading => scheme.primary,
    TorrentStatus.queuedForSeed => scheme.tertiary.withValues(alpha: 0.7),
    TorrentStatus.seeding => scheme.tertiary,
  };
}

String statusLabel(TorrentStatus status) {
  switch (status) {
    case TorrentStatus.stopped:
      return 'Paused';
    case TorrentStatus.queuedForVerification:
      return 'Queued for verify';
    case TorrentStatus.verifying:
      return 'Verifying';
    case TorrentStatus.queuedForDownload:
      return 'Queued';
    case TorrentStatus.downloading:
      return 'Downloading';
    case TorrentStatus.queuedForSeed:
      return 'Queued for seeding';
    case TorrentStatus.seeding:
      return 'Seeding';
  }
}

Future<void> openTorrentActions(
  BuildContext context,
  WidgetRef ref,
  Torrent torrent,
) async {
  final hostContext = context;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            _ActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Start',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction((repo) => repo.startTorrents([torrent.id])),
              ),
            ),
            _ActionButton(
              icon: Icons.flash_on_rounded,
              label: 'Start Now',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction(
                      (repo) =>
                          repo.startTorrents([torrent.id], bypassQueue: true),
                    ),
              ),
            ),
            _ActionButton(
              icon: Icons.pause_rounded,
              label: 'Pause',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction((repo) => repo.stopTorrents([torrent.id])),
              ),
            ),
            _ActionButton(
              icon: Icons.verified_rounded,
              label: 'Verify',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction((repo) => repo.verifyTorrents([torrent.id])),
              ),
            ),
            _ActionButton(
              icon: Icons.campaign_rounded,
              label: 'Reannounce',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction(
                      (repo) => repo.reannounceTorrents([torrent.id]),
                    ),
              ),
            ),
            _ActionButton(
              icon: Icons.priority_high_rounded,
              label: 'High Priority',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction(
                      (repo) => repo.setBandwidthPriority([
                        torrent.id,
                      ], BandwidthPriority.high),
                    ),
              ),
            ),
            _ActionButton(
              icon: Icons.remove_rounded,
              label: 'Normal Priority',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction(
                      (repo) => repo.setBandwidthPriority([
                        torrent.id,
                      ], BandwidthPriority.normal),
                    ),
              ),
            ),
            _ActionButton(
              icon: Icons.vertical_align_bottom_rounded,
              label: 'Low Priority',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction(
                      (repo) => repo.setBandwidthPriority([
                        torrent.id,
                      ], BandwidthPriority.low),
                    ),
              ),
            ),
            _ActionButton(
              icon: Icons.arrow_upward_rounded,
              label: 'Queue Top',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction(
                      (repo) =>
                          repo.moveQueue([torrent.id], QueueMoveDirection.top),
                    ),
              ),
            ),
            _ActionButton(
              icon: Icons.keyboard_arrow_up_rounded,
              label: 'Queue Up',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction(
                      (repo) =>
                          repo.moveQueue([torrent.id], QueueMoveDirection.up),
                    ),
              ),
            ),
            _ActionButton(
              icon: Icons.keyboard_arrow_down_rounded,
              label: 'Queue Down',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction(
                      (repo) =>
                          repo.moveQueue([torrent.id], QueueMoveDirection.down),
                    ),
              ),
            ),
            _ActionButton(
              icon: Icons.arrow_downward_rounded,
              label: 'Queue Bottom',
              onTap: () => _dismissSheetAndRunTorrentAction(
                sheetContext,
                hostContext,
                ref,
                () => ref
                    .read(torrentListControllerProvider.notifier)
                    .performAction(
                      (repo) => repo.moveQueue([
                        torrent.id,
                      ], QueueMoveDirection.bottom),
                    ),
              ),
            ),
            _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Rename Path',
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final value = await _promptForText(
                  hostContext,
                  title: 'Rename path',
                  initialValue: torrent.name,
                  label: 'New name',
                );
                if (value == null ||
                    value.trim().isEmpty ||
                    !hostContext.mounted) {
                  return;
                }
                await _runTorrentAction(
                  hostContext,
                  ref,
                  () => ref
                      .read(torrentListControllerProvider.notifier)
                      .performAction(
                        (repo) => repo.renamePath(
                          torrentId: torrent.id,
                          path: torrent.name,
                          name: value.trim(),
                        ),
                      ),
                );
              },
            ),
            _ActionButton(
              icon: Icons.folder_open_rounded,
              label: 'Move Torrent Location',
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await openMoveTorrentLocationDialog(hostContext, ref, torrent);
              },
            ),
            _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Torrent',
              onTap: () => _confirmRemove(
                sheetContext,
                hostContext,
                ref,
                torrent,
                false,
              ),
            ),
            _ActionButton(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Torrent + Data',
              onTap: () =>
                  _confirmRemove(sheetContext, hostContext, ref, torrent, true),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _confirmRemove(
  BuildContext sheetContext,
  BuildContext hostContext,
  WidgetRef ref,
  Torrent torrent,
  bool deleteLocalData,
) async {
  Navigator.of(sheetContext).pop();
  final confirmed =
      await showDialog<bool>(
        context: hostContext,
        builder: (context) => AlertDialog(
          title: Text(
            deleteLocalData ? 'Remove torrent and data?' : 'Remove torrent?',
          ),
          content: Text(torrent.name),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed) {
    return;
  }
  if (!hostContext.mounted) {
    return;
  }
  final removed = await confirmRemoveTorrent(
    hostContext,
    ref,
    torrent,
    deleteLocalData: deleteLocalData,
  );
  if (removed && hostContext.mounted && Navigator.of(hostContext).canPop()) {
    Navigator.of(hostContext).pop();
  }
}

Future<bool> confirmRemoveTorrent(
  BuildContext context,
  WidgetRef ref,
  Torrent torrent, {
  required bool deleteLocalData,
}) async {
  return _runTorrentAction(
    context,
    ref,
    () => ref
        .read(torrentListControllerProvider.notifier)
        .performAction(
          (repo) => repo.removeTorrents([
            torrent.id,
          ], deleteLocalData: deleteLocalData),
        ),
  );
}

Future<void> openMoveTorrentLocationDialog(
  BuildContext context,
  WidgetRef ref,
  Torrent torrent,
) async {
  final value = await _promptForText(
    context,
    title: 'Move torrent location',
    initialValue: torrent.downloadDir ?? '',
    label: 'New destination directory',
  );
  if (value == null || value.trim().isEmpty || !context.mounted) {
    return;
  }
  await _runTorrentAction(
    context,
    ref,
    () => ref
        .read(torrentListControllerProvider.notifier)
        .performAction(
          (repo) => repo.moveData(ids: [torrent.id], location: value.trim()),
        ),
  );
}

Future<void> _dismissSheetAndRunTorrentAction(
  BuildContext sheetContext,
  BuildContext hostContext,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  Navigator.of(sheetContext).pop();
  await _runTorrentAction(hostContext, ref, action);
}

Future<bool> _runTorrentAction(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  try {
    await action();
    if (!context.mounted) {
      return false;
    }
    await ref.read(torrentListControllerProvider.notifier).refresh();
    if (!context.mounted) {
      return false;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Action completed.')));
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
    return false;
  }
}

Future<String?> _promptForText(
  BuildContext context, {
  required String title,
  required String initialValue,
  required String label,
}) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}
