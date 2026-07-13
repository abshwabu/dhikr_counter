import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/daily_entry.dart';
import 'models/dhikr_set.dart';
import 'models/streak_data.dart';
import 'screens/home_screen.dart';
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
  ]);

  runApp(const ProviderScope(child: DhikrCounterApp()));
}

class DhikrCounterApp extends StatelessWidget {
  const DhikrCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dhikr Counter',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
