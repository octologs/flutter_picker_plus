import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

void main() {
  group('Basic Picker Tests', () {
    test('Picker can be created with adapter', () {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Option 1', 'Option 2', 'Option 3'],
      );
      
      final picker = Picker(adapter: adapter);
      
      expect(picker.adapter, equals(adapter));
      expect(picker.selecteds, isNotNull);
    });

    test('PickerDataAdapter processes simple string array', () {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Apple', 'Banana', 'Cherry'],
      );

      expect(adapter.data.length, equals(3));
      expect(adapter.data[0].value, equals('Apple'));
      expect(adapter.data[1].value, equals('Banana'));
      expect(adapter.data[2].value, equals('Cherry'));
    });

    test('NumberPickerAdapter handles numeric ranges', () {
      final adapter = NumberPickerAdapter(
        data: [
          const NumberPickerColumn(begin: 1, end: 10),
        ],
      );

      expect(adapter.getMaxLevel(), equals(1)); // Should have 1 column
      // Don't test getLength() without proper setup as it may require column index to be set
    });

    test('DateTimePickerAdapter creates with date configuration', () {
      final adapter = DateTimePickerAdapter(
        type: PickerDateTimeType.kYMD,
        value: DateTime(2023, 6, 15),
      );

      expect(adapter.getMaxLevel(), equals(3)); // Year, Month, Day
      expect(adapter.value?.year, equals(2023));
      expect(adapter.value?.month, equals(6));
      expect(adapter.value?.day, equals(15));
    });

    test('PickerItem can store data and widgets', () {
      final item = PickerItem<String>(
        text: const Text('Display Text'),
        value: 'stored_value',
      );

      expect(item.text, isA<Text>());
      expect(item.value, equals('stored_value'));
      expect(item.children, isNull);
    });

    test('PickerDelimiter has configurable properties', () {
      final delimiter = PickerDelimiter(
        child: const Text(':'),
        column: 2,
      );

      expect(delimiter.child, isA<Text>());
      expect(delimiter.column, equals(2));
    });

    testWidgets('Basic picker widget renders', (WidgetTester tester) async {
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

      expect(find.text('Test Option'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('Picker with hidden header', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Test Option'],
      );
      
      final picker = Picker(
        adapter: adapter,
        hideHeader: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      expect(find.text('Test Option'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Confirm'), findsNothing);
    });

    testWidgets('Picker handles confirm tap', (WidgetTester tester) async {
      bool confirmTapped = false;

      final adapter = PickerDataAdapter<String>(
        pickerData: ['Option'],
      );
      
      final picker = Picker(
        adapter: adapter,
        onConfirm: (picker, selected) => confirmTapped = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(confirmTapped, isTrue);
    });

    testWidgets('Picker handles cancel tap', (WidgetTester tester) async {
      bool cancelTapped = false;

      final adapter = PickerDataAdapter<String>(
        pickerData: ['Option'],
      );
      
      final picker = Picker(
        adapter: adapter,
        onCancel: () => cancelTapped = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cancelTapped, isTrue);
    });

    testWidgets('Multi-column picker with delimiters', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          ['10', '11', '12'],
          ['00', '30', '45'],
        ],
        isArray: true,
      );
      
      final picker = Picker(
        adapter: adapter,
        delimiter: [
          PickerDelimiter(child: const Text(':'), column: 1),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      expect(find.text(':'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
    });
  });

  group('Advanced Configuration Tests', () {
    test('Hierarchical data structure', () {
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          {
            'Category A': ['Item A1', 'Item A2'],
            'Category B': ['Item B1', 'Item B2'],
          }
        ],
      );

      expect(adapter.data.length, equals(2));
      expect(adapter.data[0].value, equals('Category A'));
      expect(adapter.data[0].children?.length, equals(2));
      expect(adapter.data[0].children?[0].value, equals('Item A1'));
    });

    test('Number picker with custom ranges and intervals', () {
      final adapter = NumberPickerAdapter(
        data: [
          const NumberPickerColumn(begin: 0, end: 23), // Hours
          const NumberPickerColumn(begin: 0, end: 59, jump: 15), // Minutes
        ],
      );

      expect(adapter.getMaxLevel(), equals(2));
      
      // Test hours (first column is index -1 in setColumn due to internal +1)
      adapter.setColumn(-1);
      expect(adapter.getLength(), equals(24)); // 0 to 23 = 24 items
      
      // Test minutes with 15-minute intervals (second column is index 0)
      adapter.setColumn(0);
      expect(adapter.getLength(), equals(4)); // 0, 15, 30, 45
    });

    test('DateTime picker with different types', () {
      final dateTypes = [
        PickerDateTimeType.kYMD,   // 3 columns
        PickerDateTimeType.kHM,    // 2 columns
        PickerDateTimeType.kY,     // 1 column
      ];

      final expectedColumns = [3, 2, 1];

      for (int i = 0; i < dateTypes.length; i++) {
        final adapter = DateTimePickerAdapter(
          type: dateTypes[i],
          value: DateTime(2023, 6, 15, 10, 30),
        );
        
        expect(
          adapter.getMaxLevel(),
          equals(expectedColumns[i]),
          reason: 'Type ${dateTypes[i]} should have ${expectedColumns[i]} columns',
        );
      }
    });

    test('Custom PickerItem with children', () {
      final parentItem = PickerItem<String>(
        value: 'parent',
        text: const Text('Parent Category'),
        children: [
          PickerItem<String>(value: 'child1', text: const Text('Child 1')),
          PickerItem<String>(value: 'child2', text: const Text('Child 2')),
        ],
      );

      expect(parentItem.children?.length, equals(2));
      expect(parentItem.children?[0].value, equals('child1'));
      expect(parentItem.children?[1].value, equals('child2'));
    });
  });

  group('Error Handling', () {
    test('Empty data adapter', () {
      final adapter = PickerDataAdapter<String>(pickerData: []);
      expect(adapter.data, isEmpty);
    });

    test('Invalid number ranges handled gracefully', () {
      expect(
        () => NumberPickerColumn(begin: 10, end: 5), // Invalid range
        returnsNormally,
      );
    });

    test('Extreme date values', () {
      expect(
        () => DateTimePickerAdapter(
          type: PickerDateTimeType.kYMD,
          value: DateTime(1, 1, 1), // Very old date
        ),
        returnsNormally,
      );
    });
  });

  group('Performance Tests', () {
    test('Large dataset handling', () {
      final largeData = List.generate(1000, (i) => 'Item $i');
      
      final stopwatch = Stopwatch()..start();
      final adapter = PickerDataAdapter<String>(pickerData: largeData);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(adapter.data.length, equals(1000));
    });

    test('Deep hierarchical structure', () {
      final deepData = {
        'Level1': {
          'Level2': {
            'Level3': ['Item1', 'Item2']
          }
        }
      };

      expect(
        () => PickerDataAdapter<String>(pickerData: [deepData]),
        returnsNormally,
      );
    });
  });
}