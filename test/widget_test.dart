import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kana_quest/src/app/app.dart';

void main() {
  testWidgets('Kana Quest app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const KanaQuestApp());

    expect(find.byType(KanaQuestApp), findsOneWidget);
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
