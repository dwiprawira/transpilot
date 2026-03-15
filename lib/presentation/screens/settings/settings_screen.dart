import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/layout.dart';
import '../../../domain/entities/app_preferences.dart';
import '../../../domain/entities/session_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/preferences_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final preferences =
        ref.watch(preferencesControllerProvider).valueOrNull ??
        AppPreferences.defaults();
    final dashboard = ref.watch(dashboardControllerProvider);

    final horizontalPadding = AppLayout.horizontalPadding(width);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        24,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: 'App Preferences',
                  child: _ResponsiveFields(
                    children: [
                      DropdownButtonFormField<ThemeMode>(
                        initialValue: preferences.themeMode,
                        decoration: const InputDecoration(labelText: 'Theme'),
                        items: ThemeMode.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(preferencesControllerProvider.notifier)
                                .updateThemeMode(value);
                          }
                        },
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: preferences.refreshInterval.inSeconds,
                        decoration: const InputDecoration(
                          labelText: 'Refresh interval',
                        ),
                        items: const [5, 10, 15, 30, 60]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value seconds'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(preferencesControllerProvider.notifier)
                                .updateRefreshInterval(
                                  Duration(seconds: value),
                                );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!dashboard.isConfigured)
                  const EmptyState(
                    icon: Icons.dns_rounded,
                    title: 'No active server',
                    message:
                        'Select a server profile to edit live Transmission session settings.',
                  )
                else
                  SectionCard(
                    title: 'Session Settings',
                    trailing: FilledButton.tonalIcon(
                      onPressed: dashboard.sessionInfo == null
                          ? null
                          : () => _openSessionDialog(
                              context,
                              dashboard.sessionInfo!,
                            ),
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Edit'),
                    ),
                    child: _ResponsiveSettingValues(
                      children: [
                        _SettingValue(
                          label: 'Download directory',
                          value:
                              dashboard.sessionInfo?.downloadDir ?? 'Unknown',
                        ),
                        _SettingValue(
                          label: 'Download limit',
                          value:
                              dashboard.sessionInfo?.speedLimitDownEnabled ??
                                  false
                              ? '${dashboard.sessionInfo?.speedLimitDown ?? 0} KB/s'
                              : 'Unlimited',
                        ),
                        _SettingValue(
                          label: 'Upload limit',
                          value:
                              dashboard.sessionInfo?.speedLimitUpEnabled ??
                                  false
                              ? '${dashboard.sessionInfo?.speedLimitUp ?? 0} KB/s'
                              : 'Unlimited',
                        ),
                        _SettingValue(
                          label: 'Encryption',
                          value:
                              dashboard.sessionInfo?.encryptionMode.name ??
                              'Unknown',
                        ),
                        _SettingValue(
                          label: 'Alternative speed',
                          value: dashboard.sessionInfo?.altSpeedEnabled ?? false
                              ? 'Enabled'
                              : 'Disabled',
                        ),
                        _SettingValue(
                          label: 'Free space',
                          value: Formatters.bytes(
                            dashboard.freeSpaceInfo?.sizeBytes ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _openSessionDialog(
  BuildContext context,
  SessionInfo sessionInfo,
) async {
  final width = MediaQuery.sizeOf(context).width;
  if (AppLayout.isTablet(width)) {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SessionSettingsForm(sessionInfo: sessionInfo),
        ),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Session Settings')),
        body: SessionSettingsForm(sessionInfo: sessionInfo),
      ),
    ),
  );
}

class SessionSettingsForm extends ConsumerStatefulWidget {
  const SessionSettingsForm({super.key, required this.sessionInfo});

  final SessionInfo sessionInfo;

  @override
  ConsumerState<SessionSettingsForm> createState() =>
      _SessionSettingsFormState();
}

class _SessionSettingsFormState extends ConsumerState<SessionSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _downloadDirController;
  late final TextEditingController _speedLimitDownController;
  late final TextEditingController _speedLimitUpController;
  late final TextEditingController _altSpeedDownController;
  late final TextEditingController _altSpeedUpController;
  late final TextEditingController _downloadQueueSizeController;
  late final TextEditingController _seedQueueSizeController;
  late final TextEditingController _queueStalledMinutesController;
  late bool _altSpeedEnabled;
  late bool _speedLimitDownEnabled;
  late bool _speedLimitUpEnabled;
  late bool _downloadQueueEnabled;
  late bool _seedQueueEnabled;
  late bool _queueStalledEnabled;
  late bool _startAddedTorrents;
  late EncryptionMode _encryptionMode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final session = widget.sessionInfo;
    _downloadDirController = TextEditingController(text: session.downloadDir);
    _speedLimitDownController = TextEditingController(
      text: '${session.speedLimitDown}',
    );
    _speedLimitUpController = TextEditingController(
      text: '${session.speedLimitUp}',
    );
    _altSpeedDownController = TextEditingController(
      text: '${session.altSpeedDown}',
    );
    _altSpeedUpController = TextEditingController(
      text: '${session.altSpeedUp}',
    );
    _downloadQueueSizeController = TextEditingController(
      text: '${session.downloadQueueSize}',
    );
    _seedQueueSizeController = TextEditingController(
      text: '${session.seedQueueSize}',
    );
    _queueStalledMinutesController = TextEditingController(
      text: '${session.queueStalledMinutes}',
    );
    _altSpeedEnabled = session.altSpeedEnabled;
    _speedLimitDownEnabled = session.speedLimitDownEnabled;
    _speedLimitUpEnabled = session.speedLimitUpEnabled;
    _downloadQueueEnabled = session.downloadQueueEnabled;
    _seedQueueEnabled = session.seedQueueEnabled;
    _queueStalledEnabled = session.queueStalledEnabled;
    _startAddedTorrents = session.startAddedTorrents;
    _encryptionMode = session.encryptionMode;
  }

  @override
  void dispose() {
    _downloadDirController.dispose();
    _speedLimitDownController.dispose();
    _speedLimitUpController.dispose();
    _altSpeedDownController.dispose();
    _altSpeedUpController.dispose();
    _downloadQueueSizeController.dispose();
    _seedQueueSizeController.dispose();
    _queueStalledMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Session Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _FormSection(
                title: 'Storage',
                description:
                    'Choose the default download path and transport policy.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _downloadDirController,
                      decoration: const InputDecoration(
                        labelText: 'Default download directory',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EncryptionMode>(
                      initialValue: _encryptionMode,
                      decoration: const InputDecoration(
                        labelText: 'Encryption mode',
                      ),
                      items: EncryptionMode.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _encryptionMode = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: 'Bandwidth',
                description: 'Configure standard and alternative speed limits.',
                child: Column(
                  children: [
                    _SwitchTile(
                      title: 'Alternative speed mode',
                      subtitle: 'Use separate limits for scheduled throttling.',
                      value: _altSpeedEnabled,
                      onChanged: (value) =>
                          setState(() => _altSpeedEnabled = value),
                    ),
                    const SizedBox(height: 12),
                    _ResponsiveFields(
                      minChildWidth: isWide ? 200 : 260,
                      children: [
                        TextFormField(
                          controller: _altSpeedDownController,
                          enabled: _altSpeedEnabled,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Alt download KB/s',
                          ),
                        ),
                        TextFormField(
                          controller: _altSpeedUpController,
                          enabled: _altSpeedEnabled,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Alt upload KB/s',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: 'Enable download speed limit',
                      subtitle: 'Cap normal download throughput.',
                      value: _speedLimitDownEnabled,
                      onChanged: (value) =>
                          setState(() => _speedLimitDownEnabled = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _speedLimitDownController,
                      enabled: _speedLimitDownEnabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Download limit KB/s',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: 'Enable upload speed limit',
                      subtitle: 'Cap normal upload throughput.',
                      value: _speedLimitUpEnabled,
                      onChanged: (value) =>
                          setState(() => _speedLimitUpEnabled = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _speedLimitUpController,
                      enabled: _speedLimitUpEnabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Upload limit KB/s',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: 'Queue',
                description: 'Tune active download and seeding queue behavior.',
                child: Column(
                  children: [
                    _SwitchTile(
                      title: 'Download queue enabled',
                      subtitle: 'Limit how many torrents download at once.',
                      value: _downloadQueueEnabled,
                      onChanged: (value) =>
                          setState(() => _downloadQueueEnabled = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _downloadQueueSizeController,
                      enabled: _downloadQueueEnabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Download queue size',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: 'Seed queue enabled',
                      subtitle: 'Limit how many torrents seed at once.',
                      value: _seedQueueEnabled,
                      onChanged: (value) =>
                          setState(() => _seedQueueEnabled = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _seedQueueSizeController,
                      enabled: _seedQueueEnabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seed queue size',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: 'Queue stalled detection',
                      subtitle: 'Mark torrents as stalled after inactivity.',
                      value: _queueStalledEnabled,
                      onChanged: (value) =>
                          setState(() => _queueStalledEnabled = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _queueStalledMinutesController,
                      enabled: _queueStalledEnabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stalled minutes',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: 'Behavior',
                description: 'Choose how newly added torrents should start.',
                child: _SwitchTile(
                  title: 'Start added torrents automatically',
                  subtitle: 'Disable this to add torrents in a paused state.',
                  value: _startAddedTorrents,
                  onChanged: (value) =>
                      setState(() => _startAddedTorrents = value),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final updated = widget.sessionInfo.copyWith(
      downloadDir: _downloadDirController.text.trim(),
      altSpeedEnabled: _altSpeedEnabled,
      altSpeedDown: int.tryParse(_altSpeedDownController.text.trim()) ?? 0,
      altSpeedUp: int.tryParse(_altSpeedUpController.text.trim()) ?? 0,
      speedLimitDown: int.tryParse(_speedLimitDownController.text.trim()) ?? 0,
      speedLimitUp: int.tryParse(_speedLimitUpController.text.trim()) ?? 0,
      speedLimitDownEnabled: _speedLimitDownEnabled,
      speedLimitUpEnabled: _speedLimitUpEnabled,
      encryptionMode: _encryptionMode,
      downloadQueueEnabled: _downloadQueueEnabled,
      downloadQueueSize:
          int.tryParse(_downloadQueueSizeController.text.trim()) ?? 0,
      seedQueueEnabled: _seedQueueEnabled,
      seedQueueSize: int.tryParse(_seedQueueSizeController.text.trim()) ?? 0,
      queueStalledEnabled: _queueStalledEnabled,
      queueStalledMinutes:
          int.tryParse(_queueStalledMinutesController.text.trim()) ?? 0,
      startAddedTorrents: _startAddedTorrents,
    );
    await ref
        .read(dashboardControllerProvider.notifier)
        .updateSessionInfo(updated);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children, this.minChildWidth = 240});

  final List<Widget> children;
  final double minChildWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useSingleColumn = width < (minChildWidth * 2) + 16;

        if (useSingleColumn) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        final itemWidth = (width - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _ResponsiveSettingValues extends StatelessWidget {
  const _ResponsiveSettingValues({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = switch (width) {
          >= 960 => 3,
          >= 620 => 2,
          _ => 1,
        };
        final spacing = 16.0;
        final itemWidth = columns == 1
            ? width
            : (width - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 16,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SettingValue extends StatelessWidget {
  const _SettingValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
