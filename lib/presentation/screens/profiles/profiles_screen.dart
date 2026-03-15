import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/layout.dart';
import '../../../domain/entities/server_profile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../../controllers/profiles_controller.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesControllerProvider);
    final profiles = profilesAsync.valueOrNull;

    if (profilesAsync.isLoading && profiles == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(profilesControllerProvider.notifier).load(),
      child: profiles == null || profiles.profiles.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                EmptyState(
                  icon: Icons.dns_rounded,
                  title: 'No servers yet',
                  message:
                      'Add your first Transmission server profile to start managing torrents.',
                  actionLabel: 'Add Server',
                  onAction: () => _openProfileForm(context, ref, null),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _openProfileForm(context, ref, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Server'),
                  ),
                ),
                const SizedBox(height: 16),
                for (final profile in profiles.profiles) ...[
                  SectionCard(
                    title: profile.name,
                    trailing: profile.id == profiles.activeProfileId
                        ? const Chip(label: Text('Active'))
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.useHttps ? 'https' : 'http'}://${profile.host}:${profile.port}${profile.normalizedRpcPath}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.username.isEmpty
                              ? 'Authentication: not configured'
                              : 'Authentication: ${profile.username}',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (profile.id != profiles.activeProfileId)
                              FilledButton.tonalIcon(
                                onPressed: () => ref
                                    .read(profilesControllerProvider.notifier)
                                    .setActiveProfile(profile.id),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Use'),
                              ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _openProfileForm(context, ref, profile),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _testProfile(context, ref, profile),
                              icon: const Icon(Icons.network_check_rounded),
                              label: const Text('Test'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _confirmDelete(context, ref, profile),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }

  Future<void> _testProfile(
    BuildContext context,
    WidgetRef ref,
    ServerProfile profile,
  ) async {
    try {
      await ref
          .read(profilesControllerProvider.notifier)
          .testConnection(profile);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connection succeeded.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ServerProfile profile,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete server?'),
            content: Text('Remove "${profile.name}" from this device?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    await ref
        .read(profilesControllerProvider.notifier)
        .deleteProfile(profile.id);
  }
}

Future<void> _openProfileForm(
  BuildContext context,
  WidgetRef ref,
  ServerProfile? profile,
) async {
  final width = MediaQuery.sizeOf(context).width;
  if (AppLayout.isTablet(width)) {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ProfileForm(profile: profile),
        ),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(profile == null ? 'Add Server' : 'Edit Server'),
        ),
        body: ProfileForm(profile: profile),
      ),
    ),
  );
}

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key, required this.profile});

  final ServerProfile? profile;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _rpcPathController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _useHttps = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _hostController = TextEditingController(text: profile?.host ?? '');
    _portController = TextEditingController(text: '${profile?.port ?? 9091}');
    _rpcPathController = TextEditingController(
      text: profile?.rpcPath ?? '/transmission/rpc',
    );
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _passwordController = TextEditingController(text: profile?.password ?? '');
    _useHttps = profile?.useHttps ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _rpcPathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  ServerProfile _buildProfile() {
    return ServerProfile(
      id: widget.profile?.id ?? '',
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 9091,
      rpcPath: _rpcPathController.text.trim(),
      useHttps: _useHttps,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                widget.profile == null ? 'Add Server' : 'Edit Server',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(labelText: 'Host'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(labelText: 'Port'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final port = int.tryParse(value ?? '');
                        if (port == null || port <= 0 || port > 65535) {
                          return 'Invalid port';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _useHttps,
                      title: const Text('HTTPS'),
                      onChanged: (value) => setState(() => _useHttps = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rpcPathController,
                decoration: const InputDecoration(labelText: 'RPC Path'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _testConnection,
                    icon: const Icon(Icons.network_check_rounded),
                    label: const Text('Test Connection'),
                  ),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await ref
          .read(profilesControllerProvider.notifier)
          .testConnection(_buildProfile());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connection succeeded.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final profile = _buildProfile();
      await ref
          .read(profilesControllerProvider.notifier)
          .testConnection(profile);
      await ref.read(profilesControllerProvider.notifier).saveProfile(profile);
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

String _errorMessage(Object error) {
  if (error is AppException) {
    return error.message;
  }
  return '$error';
}
