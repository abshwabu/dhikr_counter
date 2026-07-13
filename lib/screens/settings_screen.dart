import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder until settings UI is built.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Text(
          'Settings coming soon',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.darkGreen.withValues(alpha: 0.7),
              ),
        ),
      ),
    );
  }
}
