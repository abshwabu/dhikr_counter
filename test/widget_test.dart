import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dhikr_counter/main.dart';

void main() {
  testWidgets('Home screen shows Dhikr Counter title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DhikrCounterApp()),
    );

    expect(find.text('Dhikr Counter'), findsWidgets);
  });
}
