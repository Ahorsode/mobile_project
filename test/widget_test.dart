
import 'package:flutter_test/flutter_test.dart';

import 'package:project_part1_v1/main.dart';

void main() {
  testWidgets('Playground UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PyQuestApp());

    // Verify that the title is present.
    expect(find.text('PyQuest Playground'), findsOneWidget);

    // Verify that the Run Code button is present.
    expect(find.text('Run Code'), findsOneWidget);
  });
}
