import 'dart:io';

import 'package:dhikr_counter/main.dart';
import 'package:dhikr_counter/models/daily_entry.dart';
import 'package:dhikr_counter/models/dhikr_set.dart';
import 'package:dhikr_counter/models/streak_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dhikr_counter_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DhikrSetAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DailyEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StreakDataAdapter());
    }

    await Future.wait([
      Hive.openBox<DhikrSet>('dhikrSets'),
      Hive.openBox<DailyEntry>('dailyEntries'),
      Hive.openBox<StreakData>('streak'),
      Hive.openBox('settings'),
    ]);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Home screen shows Dhikr Counter title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DhikrCounterApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dhikr Counter'), findsWidgets);
  });
}
