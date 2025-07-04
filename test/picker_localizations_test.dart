import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

void main() {
  group('PickerLocalizations Tests', () {
    testWidgets('PickerLocalizations provides default English text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _TestPickerLocalizationsWidget(),
        ),
      );

      await tester.pumpAndSettle();

      final localizations = PickerLocalizations.of(
          tester.element(find.byType(_TestPickerLocalizationsWidget)));

      expect(localizations.cancelText, equals('Cancel'));
      expect(localizations.confirmText, equals('Confirm'));
      expect(localizations.ampm, isNotNull);
      expect(localizations.ampm!.length, equals(2));
    });

    testWidgets('PickerLocalizations works with Chinese locale',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            PickerLocalizationsDelegate.delegate,
          ],
          home: Builder(
            builder: (context) {
              return Localizations.override(
                context: context,
                locale: const Locale('zh'),
                child: const _TestPickerLocalizationsWidget(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final localizations = PickerLocalizations.of(
          tester.element(find.byType(_TestPickerLocalizationsWidget)));

      expect(localizations.cancelText, equals('取消'));
      expect(localizations.confirmText, equals('确定'));
    });

    testWidgets('PickerLocalizations works with Japanese locale',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            PickerLocalizationsDelegate.delegate,
          ],
          home: Builder(
            builder: (context) {
              return Localizations.override(
                context: context,
                locale: const Locale('ja'),
                child: const _TestPickerLocalizationsWidget(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final localizations = PickerLocalizations.of(
          tester.element(find.byType(_TestPickerLocalizationsWidget)));

      expect(localizations.cancelText, equals('キャンセル'));
      expect(localizations.confirmText, equals('完了'));
    });

    test('PickerLocalizations throws on invalid ampm array', () {
      expect(
        () => PickerLocalizations.registerCustomLanguage(
          'invalid',
          ampm: ['Only One'], // Should have 2 elements
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('PickerLocalizations throws on invalid months array', () {
      expect(
        () => PickerLocalizations.registerCustomLanguage(
          'invalid',
          months:
              List.generate(10, (i) => 'Month $i'), // Should have 12 elements
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('PickerLocalizations throws on invalid monthsLong array', () {
      expect(
        () => PickerLocalizations.registerCustomLanguage(
          'invalid',
          monthsLong:
              List.generate(15, (i) => 'Month $i'), // Should have 12 elements
        ),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('Picker uses default English localized strings in UI',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            PickerLocalizationsDelegate.delegate,
          ],
          home: Scaffold(body: _TestPickerWidget()),
        ),
      );

      await tester.pumpAndSettle();

      // Show the picker
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Verify English localized buttons (default)
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('Picker with default locale shows English text',
        (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Test Option'],
      );

      final picker = Picker(adapter: adapter);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show English by default
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });
  });

  group('PickerLocalizationsDelegate Tests', () {
    test(
        'PickerLocalizationsDelegate isSupported returns true for supported locales',
        () {
      const delegate = PickerLocalizationsDelegate();

      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('zh')), isTrue);
      expect(delegate.isSupported(const Locale('ja')), isTrue);
      expect(delegate.isSupported(const Locale('unknown')), isFalse);
    });

    test('PickerLocalizationsDelegate shouldReload returns false', () {
      const delegate = PickerLocalizationsDelegate();
      const oldDelegate = PickerLocalizationsDelegate();

      expect(delegate.shouldReload(oldDelegate), isFalse);
    });

    testWidgets(
        'PickerLocalizationsDelegate load returns correct localizations',
        (WidgetTester tester) async {
      const delegate = PickerLocalizationsDelegate();

      final englishLocalizations = await delegate.load(const Locale('en'));
      expect(englishLocalizations.cancelText, equals('Cancel'));
      expect(englishLocalizations.confirmText, equals('Confirm'));

      final chineseLocalizations = await delegate.load(const Locale('zh'));
      expect(chineseLocalizations.cancelText, equals('取消'));
      expect(chineseLocalizations.confirmText, equals('确定'));
    });
  });
}

class _TestPickerLocalizationsWidget extends StatelessWidget {
  const _TestPickerLocalizationsWidget();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Test Widget'),
      ),
    );
  }
}

class _TestPickerWidget extends StatelessWidget {
  const _TestPickerWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          final adapter = PickerDataAdapter<String>(
            pickerData: ['Test Option'],
          );

          final picker = Picker(adapter: adapter);
          picker.showModal(context);
        },
        child: const Text('Show Picker'),
      ),
    );
  }
}
