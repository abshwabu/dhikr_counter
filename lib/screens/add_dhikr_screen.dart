import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder until custom dhikr creation (Step 8) is built.
class AddDhikrScreen extends StatelessWidget {
  const AddDhikrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add custom dhikr'),
      ),
      body: Center(
        child: Text(
          'Add custom dhikr coming soon',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.darkGreen.withValues(alpha: 0.7),
              ),
        ),
      ),
    );
  }
}
