import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder until the counter UI (later step) is built.
class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
      ),
      body: Center(
        child: Text(
          'Counter coming soon',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.darkGreen.withValues(alpha: 0.7),
              ),
        ),
      ),
    );
  }
}
