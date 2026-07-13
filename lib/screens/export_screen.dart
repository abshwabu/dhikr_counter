import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder until export/share (Step 11) is built.
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share progress'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Export coming soon',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkGreen.withValues(alpha: 0.7),
                ),
          ),
        ),
      ),
    );
  }
}
