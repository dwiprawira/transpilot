import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/preferences_controller.dart';
import '../screens/home_shell.dart';

class TransPilotApp extends ConsumerWidget {
  const TransPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider).valueOrNull;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TransPilot',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: preferences?.themeMode ?? ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
