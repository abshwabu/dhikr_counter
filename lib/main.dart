import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/daily_entry.dart';
import 'models/dhikr_set.dart';
import 'models/streak_data.dart';
import 'providers/settings_providers.dart';
import 'screens/home_screen.dart';
import 'services/dhikr_repository.dart';
import 'services/reminder_service.dart';
import 'services/seed_data.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(DhikrSetAdapter());
  Hive.registerAdapter(DailyEntryAdapter());
  Hive.registerAdapter(StreakDataAdapter());

  await Future.wait([
    Hive.openBox<DhikrSet>('dhikrSets'),
    Hive.openBox<DailyEntry>('dailyEntries'),
    Hive.openBox<StreakData>('streak'),
    Hive.openBox('settings'),
  ]);

  await seedDefaultDhikrSets();
  await ReminderService.instance.init();

  runApp(const ProviderScope(child: DhikrCounterApp()));
}

class DhikrCounterApp extends ConsumerStatefulWidget {
  const DhikrCounterApp({super.key});

  @override
  ConsumerState<DhikrCounterApp> createState() => _DhikrCounterAppState();
}

class _DhikrCounterAppState extends ConsumerState<DhikrCounterApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReminderService.instance.sync(
        settings: ref.read(settingsProvider),
        repository: DhikrRepository(
          todayProvider: () => ref.read(currentDateKeyProvider),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dhikr Counter',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
