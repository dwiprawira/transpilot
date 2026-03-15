import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/layout.dart';
import '../../../data/dto/torrent_dto.dart';
import '../../../domain/entities/app_preferences.dart';
import '../../../domain/entities/torrent.dart';
import '../../../shared/logic/torrent_list_logic.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../controllers/torrent_list_controller.dart';
import 'torrent_details_view.dart';

class TorrentsScreen extends ConsumerWidget {
  const TorrentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final useSplitView = AppLayout.useSplitView(width);
    final state = ref.watch(torrentListControllerProvider);

    if (!state.isConfigured) {
      return const EmptyState(
        icon: Icons.dns_rounded,
        title: 'No active server',
        message: 'Select a Transmission server profile to load torrents.',
      );
    }

    final padding = AppLayout.horizontalPadding(width);
    final listPane = Column(
      children: [
        Material(
          elevation: 1,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
              child: _Toolbar(state: state),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(torrentListControllerProvider.notifier).refresh(),
            child: _TorrentList(
              state: state,
              padding: padding,
              useSplitView: useSplitView,
            ),
          ),
        ),
      ],
    );

    if (!useSplitView) {
      return listPane;
    }

    return Row(
      children: [
        Expanded(flex: 4, child: listPane),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 5,
          child: state.selectedTorrentId == null
              ? const EmptyState(
                  icon: Icons.info_outline_rounded,
                  title: 'Select a torrent',
                  message:
                      'The detail pane will show files, trackers, peers, and actions.',
                )
              : TorrentDetailsView(torrentId: state.selectedTorrentId!),
        ),
      ],
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.state});

  final TorrentListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBar(
          hintText: 'Search torrents, paths, trackers',
          leading: const Icon(Icons.search_rounded),
          onChanged: ref
              .read(torrentListControllerProvider.notifier)
              .setSearchQuery,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _SummaryChip(
              icon: Icons.filter_alt_outlined,
              label: state.filter.label,
              onPressed: () => _showChoiceSheet<TorrentFilter>(
                context,
                title: 'Filter Torrents',
                currentValue: state.filter,
                items: TorrentFilter.values,
                itemLabel: (value) => value.label,
                onSelected: ref
                    .read(torrentListControllerProvider.notifier)
                    .setFilter,
              ),
            ),
            _SummaryChip(
              icon: Icons.folder_copy_outlined,
              label: state.groupingMode.label,
              onPressed: () => _showChoiceSheet<TorrentGroupingMode>(
                context,
                title: 'Group Torrents',
                currentValue: state.groupingMode,
                items: TorrentGroupingMode.values,
                itemLabel: (value) => value.label,
                onSelected: ref
                    .read(torrentListControllerProvider.notifier)
                    .setGroupingMode,
              ),
            ),
            _SummaryChip(
              icon: state.sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              label: state.sortField.label,
              onPressed: () => _openSortSheet(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _TorrentList extends ConsumerWidget {
  const _TorrentList({
    required this.state,
    required this.padding,
    required this.useSplitView,
  });

  final TorrentListState state;
  final double padding;
  final bool useSplitView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.torrents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.torrents.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(padding),
        children: [
          EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load torrents',
            message: state.errorMessage!,
          ),
        ],
      );
    }

    final groups = state.visibleGroups;
    final visibleTorrents = state.visibleTorrents;
    if (visibleTorrents.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(padding),
        children: [
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No torrents found',
            message:
                'Try another filter or add a new magnet link or torrent file.',
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(padding, 4, padding, 20),
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => ref
                      .read(torrentListControllerProvider.notifier)
                      .refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        if (state.lastUpdated != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Last sync ${Formatters.dateTime(state.lastUpdated)}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        for (final group in groups) ...[
          if (state.groupingMode != TorrentGroupingMode.flat)
            _GroupHeader(
              group: group,
              collapsed: state.collapsedGroups.contains(group.key),
              onToggle: () => ref
                  .read(torrentListControllerProvider.notifier)
                  .toggleGroupCollapsed(group.key),
            )
          else
            for (final torrent in group.torrents)
              _TorrentTile(torrent: torrent, useSplitView: useSplitView),
          if (state.groupingMode != TorrentGroupingMode.flat &&
              !state.collapsedGroups.contains(group.key))
            ...group.torrents.map(
              (torrent) =>
                  _TorrentTile(torrent: torrent, useSplitView: useSplitView),
            ),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.collapsed,
    required this.onToggle,
  });

  final TorrentGroup group;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 7),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.torrents.length} torrents • ${Formatters.bytes(group.totalSize)} • ↓ ${Formatters.speed(group.totalDownloadSpeed)} • ↑ ${Formatters.speed(group.totalUploadSpeed)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _TorrentTile extends ConsumerWidget {
  const _TorrentTile({required this.torrent, required this.useSplitView});

  final Torrent torrent;
  final bool useSplitView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(torrentListControllerProvider);
    final selected = useSplitView && state.selectedTorrentId == torrent.id;
    final compact = state.viewMode == TorrentListViewMode.compact;
    final scheme = Theme.of(context).colorScheme;
    final showPath =
        state.groupingMode != TorrentGroupingMode.downloadPath &&
        torrent.downloadDir != null &&
        torrent.downloadDir!.isNotEmpty;
    final statusColor = _statusColor(context, torrent);
    final priorityColor = _priorityIndicatorColor(context, torrent);
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.1,
      color: selected ? scheme.onSecondaryContainer : null,
    );

    return Material(
      color: selected
          ? scheme.secondaryContainer.withValues(alpha: 0.18)
          : null,
      child: InkWell(
        onTap: () {
          ref
              .read(torrentListControllerProvider.notifier)
              .selectTorrent(torrent.id);
          if (!useSplitView) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text(
                      torrent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Torrent actions',
                        onPressed: () =>
                            openTorrentActions(context, ref, torrent),
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                    ],
                  ),
                  body: TorrentDetailsView(
                    torrentId: torrent.id,
                    showBodyAction: false,
                    showBodyTitle: false,
                  ),
                ),
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.fromLTRB(
            0,
            compact ? 9 : 11,
            0,
            compact ? 9 : 11,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: compact ? 54 : 60,
                margin: const EdgeInsets.only(top: 2, right: 10),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            torrent.name,
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Formatters.percentage(torrent.effectiveProgress),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? scheme.onSecondaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: torrent.effectiveProgress,
                        color: statusColor,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _primaryMetaLine(torrent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? scheme.onSecondaryContainer.withValues(
                                alpha: 0.84,
                              )
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _secondaryMetaLine(torrent, showPath: showPath),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected
                            ? scheme.onSecondaryContainer.withValues(
                                alpha: 0.72,
                              )
                            : scheme.onSurfaceVariant.withValues(alpha: 0.95),
                      ),
                    ),
                    if (torrent.errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        torrent.errorMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                splashRadius: 18,
                onPressed: () => openTorrentActions(context, ref, torrent),
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(icon, size: 14),
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      side: BorderSide(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
  }
}

String _primaryMetaLine(Torrent torrent) {
  return '${statusLabel(torrent.status)} • ${Formatters.bytes(torrent.totalSize)} • ETA ${Formatters.eta(torrent.etaSeconds)} • Peers ${torrent.peersConnected}';
}

String _secondaryMetaLine(Torrent torrent, {required bool showPath}) {
  final segments = <String>[
    _priorityLabel(torrent.bandwidthPriority),
    '↓ ${Formatters.speed(torrent.rateDownload)}',
    '↑ ${Formatters.speed(torrent.rateUpload)}',
    'R ${Formatters.ratio(torrent.uploadRatio)}',
    TorrentDto.primaryTrackerLabel(torrent),
  ];
  if (showPath) {
    segments.add(torrent.downloadDir!);
  }
  return segments.join(' • ');
}

Color _statusColor(BuildContext context, Torrent torrent) {
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

Color _priorityIndicatorColor(BuildContext context, Torrent torrent) {
  final scheme = Theme.of(context).colorScheme;
  return switch (torrent.bandwidthPriority) {
    BandwidthPriority.high => scheme.primary,
    BandwidthPriority.normal => scheme.outlineVariant,
    BandwidthPriority.low => scheme.secondary.withValues(alpha: 0.85),
  };
}

String _priorityLabel(BandwidthPriority priority) {
  return switch (priority) {
    BandwidthPriority.high => 'High',
    BandwidthPriority.normal => 'Normal',
    BandwidthPriority.low => 'Low',
  };
}

Future<void> _openSortSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(torrentListControllerProvider);
        return SafeArea(
          child: _SheetLayout(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort Torrents',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...TorrentSortField.values.map(
                  (value) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(value.label),
                    trailing: value == state.sortField
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () {
                      ref
                          .read(torrentListControllerProvider.notifier)
                          .setSort(value, state.sortAscending);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ascending order'),
                  value: state.sortAscending,
                  onChanged: (value) {
                    ref
                        .read(torrentListControllerProvider.notifier)
                        .setSort(state.sortField, value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required T currentValue,
  required List<T> items,
  required String Function(T value) itemLabel,
  required Future<void> Function(T value) onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: _SheetLayout(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (value) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(itemLabel(value)),
                trailing: value == currentValue
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () async {
                  await onSelected(value);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetLayout extends StatelessWidget {
  const _SheetLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * 0.72),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: child,
        ),
      ),
    );
  }
}

Future<void> openAddTorrentSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: AddTorrentForm(),
      ),
    ),
  );
}

class AddTorrentForm extends ConsumerStatefulWidget {
  const AddTorrentForm({super.key});

  @override
  ConsumerState<AddTorrentForm> createState() => _AddTorrentFormState();
}

class _AddTorrentFormState extends ConsumerState<AddTorrentForm> {
  final _formKey = GlobalKey<FormState>();
  final _magnetController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _startPaused = false;
  BandwidthPriority _priority = BandwidthPriority.normal;
  List<int>? _metainfo;
  String? _fileName;
  bool _isSaving = false;

  @override
  void dispose() {
    _magnetController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Add Torrent',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _magnetController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Magnet link',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (_metainfo != null) {
                  return null;
                }
                if (value == null || value.trim().isEmpty) {
                  return 'Paste a magnet link or pick a .torrent file';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (_fileName != null) Text('Selected file: $_fileName'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _pasteClipboard,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Paste Clipboard'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: const Text('Pick Torrent File'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination directory',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BandwidthPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Bandwidth priority',
              ),
              items: BandwidthPriority.values
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value.name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _startPaused,
              contentPadding: EdgeInsets.zero,
              title: const Text('Start paused'),
              onChanged: (value) => setState(() => _startPaused = value),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: const Icon(Icons.add_rounded),
              label: Text(_isSaving ? 'Adding...' : 'Add Torrent'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (!mounted) {
      return;
    }
    setState(() {
      _magnetController.text = data?.text ?? '';
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['torrent'],
    );
    final file = result?.files.singleOrNull;
    if (file == null) {
      return;
    }
    List<int>? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _metainfo = bytes;
      _fileName = file.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final controller = ref.read(torrentListControllerProvider.notifier);
      await controller.performAction((repo) async {
        await repo.addTorrent(
          magnetLink: _magnetController.text.trim().isEmpty
              ? null
              : _magnetController.text.trim(),
          metainfo: _metainfo,
          downloadDir: _destinationController.text.trim().isEmpty
              ? null
              : _destinationController.text.trim(),
          paused: _startPaused,
          priority: _priority,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Torrent added.')));
        Navigator.of(context).maybePop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
