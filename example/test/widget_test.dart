// Smoke test for the flutter_picker_plus example app.
//
// The example is a picker demo (not the `flutter create` counter template),
// so the assertions below are written against its real UI: an AppBar titled
// "Picker", a list of demo entries, and a "+" action that opens RawPickerTest.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_picker_plus_example/main.dart';
import 'package:flutter_picker_plus_example/picker_test.dart';

void main() {
  testWidgets('Example app renders the picker demo list',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.textContaining('Picker'), findsWidgets);
    expect(find.text('1. Picker Show'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('Tapping the + action opens RawPickerTest',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(RawPickerTest), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(RawPickerTest), findsOneWidget);
  });
}
