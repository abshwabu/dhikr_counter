import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/dhikr_set.dart';

const _hasSeededKey = 'hasSeeded';

/// Populates [dhikrSets] with built-in defaults on first launch only.
Future<void> seedDefaultDhikrSets({
  Box? settingsBox,
  Box<DhikrSet>? dhikrSetsBox,
  Uuid? uuid,
}) async {
  final settings = settingsBox ?? await Hive.openBox('settings');
  if (settings.get(_hasSeededKey) == true) {
    return;
  }

  final sets = dhikrSetsBox ?? Hive.box<DhikrSet>('dhikrSets');
  final id = uuid ?? const Uuid();
  final now = DateTime.now();

  const defaults = <({
    String arabic,
    String transliteration,
    String translation,
    int targetCount,
    String colorHex,
  })>[
    (
      arabic: 'سُبْحَانَ اللَّه',
      transliteration: 'Subhanallah',
      translation: 'Glory be to Allah',
      targetCount: 33,
      colorHex: '#1B5E20',
    ),
    (
      arabic: 'الْحَمْدُ لِلَّه',
      transliteration: 'Alhamdulillah',
      translation: 'Praise be to Allah',
      targetCount: 33,
      colorHex: '#D4AF37',
    ),
    (
      arabic: 'اللَّهُ أَكْبَر',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest',
      targetCount: 34,
      colorHex: '#1565C0',
    ),
    (
      arabic: 'أَسْتَغْفِرُ اللَّه',
      transliteration: 'Astaghfirullah',
      translation: 'I seek forgiveness from Allah',
      targetCount: 100,
      colorHex: '#6A1B9A',
    ),
    (
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّه',
      transliteration: 'La ilaha illallah',
      translation: 'There is no god but Allah',
      targetCount: 100,
      colorHex: '#BF360C',
    ),
  ];

  for (final item in defaults) {
    final dhikrSet = DhikrSet(
      id: id.v4(),
      arabic: item.arabic,
      transliteration: item.transliteration,
      translation: item.translation,
      targetCount: item.targetCount,
      isCustom: false,
      colorHex: item.colorHex,
      createdAt: now,
    );
    await sets.put(dhikrSet.id, dhikrSet);
  }

  await settings.put(_hasSeededKey, true);
}
