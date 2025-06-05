import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

void main() {
  group('Picker Core Tests', () {
    testWidgets('Picker creates with required adapter', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Option 1', 'Option 2', 'Option 3'],
      );
      
      final picker = Picker(adapter: adapter);
      
      expect(picker.adapter, equals(adapter));
      expect(picker.selecteds, isNotNull);
    });

    testWidgets('Picker can be created and displayed', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Apple', 'Banana', 'Orange'],
      );
      
      final picker = Picker(
        adapter: adapter,
        title: const Text('Select Fruit'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      expect(find.text('Select Fruit'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Orange'), findsOneWidget);
    });

    testWidgets('Picker displays cancel and confirm buttons by default', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Test'],
      );
      
      final picker = Picker(adapter: adapter);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('Picker can hide header', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Test'],
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

      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Confirm'), findsNothing);
    });

    testWidgets('Picker calls onConfirm when confirm button tapped', (WidgetTester tester) async {
      bool confirmCalled = false;
      List<int>? selectedIndices;
      
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Option 1', 'Option 2'],
      );
      
      final picker = Picker(
        adapter: adapter,
        onConfirm: (picker, selected) {
          confirmCalled = true;
          selectedIndices = selected;
        },
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

      expect(confirmCalled, isTrue);
      expect(selectedIndices, isNotNull);
      expect(selectedIndices!.length, equals(1));
    });

    testWidgets('Picker calls onCancel when cancel button tapped', (WidgetTester tester) async {
      bool cancelCalled = false;
      
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Option 1', 'Option 2'],
      );
      
      final picker = Picker(
        adapter: adapter,
        onCancel: () {
          cancelCalled = true;
        },
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

      expect(cancelCalled, isTrue);
    });

    testWidgets('Picker respects custom text styles', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Styled Text'],
      );
      
      final picker = Picker(
        adapter: adapter,
        textStyle: const TextStyle(fontSize: 24, color: Colors.red),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      final textWidget = tester.widget<DefaultTextStyle>(
        find.ancestor(
          of: find.text('Styled Text'),
          matching: find.byType(DefaultTextStyle),
        ).first,
      );

      expect(textWidget.style.fontSize, equals(24));
      expect(textWidget.style.color, equals(Colors.red));
    });
  });

  group('PickerDataAdapter Tests', () {
    test('PickerDataAdapter creates with simple string array', () {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['A', 'B', 'C'],
      );

      expect(adapter.data.length, equals(3));
      expect(adapter.data[0].value, equals('A'));
      expect(adapter.data[1].value, equals('B'));
      expect(adapter.data[2].value, equals('C'));
    });

    test('PickerDataAdapter handles hierarchical data', () {
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          {
            'Fruits': ['Apple', 'Banana'],
            'Vegetables': ['Carrot', 'Broccoli'],
          }
        ],
      );

      expect(adapter.data.length, equals(2));
      expect(adapter.data[0].value, equals('Fruits'));
      expect(adapter.data[0].children?.length, equals(2));
      expect(adapter.data[0].children?[0].value, equals('Apple'));
    });

    test('PickerDataAdapter handles array mode correctly', () {
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          ['Red', 'Green', 'Blue'],
          ['Small', 'Medium', 'Large'],
        ],
        isArray: true,
      );

      expect(adapter.data.length, equals(2));
      expect(adapter.data[0].children?.length, equals(3));
      expect(adapter.data[1].children?.length, equals(3));
    });

    test('PickerDataAdapter getSelectedValues returns correct values', () {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['First', 'Second', 'Third'],
      );
      
      final picker = Picker(adapter: adapter);
      // Connect adapter to picker and initialize
      adapter.picker = picker;
      adapter.initSelects();
      picker.selecteds = [1]; // Select 'Second'
      
      final values = adapter.getSelectedValues();
      expect(values.length, equals(1));
      expect(values[0], equals('Second'));
    });

    test('PickerDataAdapter handles custom PickerItem objects', () {
      final adapter = PickerDataAdapter<String>(
        data: [
          PickerItem<String>(
            text: const Text('Custom Item'),
            value: 'custom_value',
          ),
        ],
      );

      expect(adapter.data.length, equals(1));
      expect(adapter.data[0].value, equals('custom_value'));
      expect(adapter.data[0].text, isA<Text>());
    });
  });

  group('NumberPickerAdapter Tests', () {
    test('NumberPickerAdapter creates with numeric range', () {
      final adapter = NumberPickerAdapter(
        data: [
          const NumberPickerColumn(begin: 1, end: 10),
        ],
      );

      expect(adapter.getMaxLevel(), equals(1));
      expect(adapter.data[0].begin, equals(1));
      expect(adapter.data[0].end, equals(10));
    });

    test('NumberPickerAdapter handles multiple columns', () {
      final adapter = NumberPickerAdapter(
        data: [
          const NumberPickerColumn(begin: 1, end: 12), // Months
          const NumberPickerColumn(begin: 1, end: 31), // Days
        ],
      );

      expect(adapter.getMaxLevel(), equals(2));
      
      // Test column configurations
      expect(adapter.data[0].begin, equals(1));
      expect(adapter.data[0].end, equals(12));
      expect(adapter.data[1].begin, equals(1));
      expect(adapter.data[1].end, equals(31));
    });

    test('NumberPickerAdapter handles jump values correctly', () {
      final adapter = NumberPickerAdapter(
        data: [
          const NumberPickerColumn(begin: 0, end: 60, jump: 5), // Every 5 minutes
        ],
      );

      expect(adapter.getMaxLevel(), equals(1)); // Should have 1 column
      // Test the column configuration
      expect(adapter.data[0].begin, equals(0));
      expect(adapter.data[0].end, equals(60));
      expect(adapter.data[0].jump, equals(5));
    });

    test('NumberPickerAdapter valueOf returns correct values', () {
      final column = NumberPickerColumn(begin: 10, end: 20, jump: 2);
      
      expect(column.valueOf(0), equals(10));
      expect(column.valueOf(1), equals(12));
      expect(column.valueOf(2), equals(14));
    });

    test('NumberPickerAdapter indexOf returns correct indices', () {
      final column = NumberPickerColumn(begin: 10, end: 20, jump: 2);
      
      expect(column.indexOf(10), equals(0));
      expect(column.indexOf(12), equals(1));
      expect(column.indexOf(14), equals(2));
      expect(column.indexOf(15), equals(-1)); // Not in sequence
    });
  });

  group('DateTimePickerAdapter Tests', () {
    test('DateTimePickerAdapter creates with date type', () {
      final adapter = DateTimePickerAdapter(
        type: PickerDateTimeType.kYMD,
        value: DateTime(2023, 6, 15),
      );

      expect(adapter.getMaxLevel(), equals(3)); // Year, Month, Day
      expect(adapter.value?.year, equals(2023));
      expect(adapter.value?.month, equals(6));
      expect(adapter.value?.day, equals(15));
    });

    test('DateTimePickerAdapter handles time type', () {
      final adapter = DateTimePickerAdapter(
        type: PickerDateTimeType.kHM,
        value: DateTime(2023, 1, 1, 14, 30),
      );

      expect(adapter.getMaxLevel(), equals(2)); // Hour, Minute
    });

    test('DateTimePickerAdapter respects year range', () {
      final adapter = DateTimePickerAdapter(
        type: PickerDateTimeType.kY,
        yearBegin: 2000,
        yearEnd: 2030,
        value: DateTime(2023),
      );

      expect(adapter.getMaxLevel(), equals(1)); // Year only
      expect(adapter.yearBegin, equals(2000));
      expect(adapter.yearEnd, equals(2030));
      expect(adapter.value?.year, equals(2023));
    });

    test('DateTimePickerAdapter handles minute intervals', () {
      final adapter = DateTimePickerAdapter(
        type: PickerDateTimeType.kHM,
        minuteInterval: 15,
        value: DateTime(2023, 1, 1, 10, 0),
      );

      expect(adapter.getMaxLevel(), equals(2)); // Hour, Minute
      expect(adapter.minuteInterval, equals(15));
      expect(adapter.value?.hour, equals(10));
      expect(adapter.value?.minute, equals(0));
    });

    test('DateTimePickerAdapter validates min/max values', () {
      final minDate = DateTime(2020, 1, 1);
      final maxDate = DateTime(2025, 12, 31);
      
      final adapter = DateTimePickerAdapter(
        type: PickerDateTimeType.kYMD,
        minValue: minDate,
        maxValue: maxDate,
        value: DateTime(2019, 6, 15), // Before min
      );

      // Should clamp to min value
      expect(adapter.value?.year, equals(2020));
      expect(adapter.value?.month, equals(1));
      expect(adapter.value?.day, equals(1));
    });
  });

  group('PickerItem Tests', () {
    test('PickerItem creates with text and value', () {
      final item = PickerItem<String>(
        text: const Text('Display Text'),
        value: 'stored_value',
      );

      expect(item.text, isA<Text>());
      expect(item.value, equals('stored_value'));
      expect(item.children, isNull);
    });

    test('PickerItem can have children for hierarchical data', () {
      final parent = PickerItem<String>(
        value: 'parent',
        children: [
          PickerItem<String>(value: 'child1'),
          PickerItem<String>(value: 'child2'),
        ],
      );

      expect(parent.children?.length, equals(2));
      expect(parent.children?[0].value, equals('child1'));
      expect(parent.children?[1].value, equals('child2'));
    });
  });

  group('PickerDelimiter Tests', () {
    test('PickerDelimiter creates with widget and column', () {
      final delimiter = PickerDelimiter(
        child: const Text(':'),
        column: 1,
      );

      expect(delimiter.child, isA<Text>());
      expect(delimiter.column, equals(1));
    });

    test('PickerDelimiter has default column value', () {
      final delimiter = PickerDelimiter(
        child: const Icon(Icons.arrow_forward),
      );

      expect(delimiter.column, equals(1));
    });
  });

  group('Picker Integration Tests', () {
    testWidgets('Picker with delimiters displays correctly', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          ['10', '11', '12'],
          ['00', '15', '30', '45'],
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

    testWidgets('Picker selection updates correctly', (WidgetTester tester) async {
      int selectedIndex = -1;
      
      final adapter = PickerDataAdapter<String>(
        pickerData: ['First', 'Second', 'Third'],
      );
      
      final picker = Picker(
        adapter: adapter,
        onSelect: (picker, index, selected) {
          selectedIndex = selected[0];
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      // Simulate scrolling to select different item
      await tester.drag(find.text('First'), const Offset(0, -50));
      await tester.pumpAndSettle();

      // onSelect should have been called
      expect(selectedIndex, greaterThanOrEqualTo(0));
    });

    testWidgets('Picker modal shows and dismisses correctly', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Option 1', 'Option 2'],
      );
      
      final picker = Picker(adapter: adapter);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => picker.showModal(context),
                child: const Text('Show Picker'),
              ),
            ),
          ),
        ),
      );

      // Show the picker
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Verify picker is shown
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Dismiss with cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify picker is dismissed
      expect(find.text('Option 1'), findsNothing);
    });

    testWidgets('Picker dialog shows and confirms correctly', (WidgetTester tester) async {
      List<int>? result;
      
      final adapter = PickerDataAdapter<String>(
        pickerData: ['A', 'B', 'C'],
      );
      
      final picker = Picker(
        adapter: adapter,
        onConfirm: (picker, selected) {
          result = selected;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => picker.showDialog(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('A'), findsOneWidget);

      // Confirm selection (find the confirm button in the dialog)
      await tester.tap(find.text('Confirm').last);
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.length, equals(1));
      expect(result![0], equals(0)); // First item selected
    });
  });

  group('Accessibility Tests', () {
    testWidgets('Picker has proper semantics', (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Accessible Option 1', 'Accessible Option 2'],
      );
      
      final picker = Picker(
        adapter: adapter,
        title: const Text('Accessible Picker'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      // Verify semantic elements exist
      expect(find.text('Accessible Picker'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      
      // These should be accessible to screen readers
      expect(tester.getSemantics(find.text('Cancel')), isNotNull);
      expect(tester.getSemantics(find.text('Confirm')), isNotNull);
    });
  });

  group('Error Handling Tests', () {
    test('Picker handles empty data gracefully', () {
      final adapter = PickerDataAdapter<String>(pickerData: []);
      final picker = Picker(adapter: adapter);
      
      expect(adapter.data, isEmpty);
      // Empty data might cause issues, so we just check it doesn't crash during creation
      expect(picker.adapter, equals(adapter));
    });

    test('NumberPickerAdapter handles invalid ranges', () {
      expect(
        () => NumberPickerColumn(begin: 10, end: 5), // Invalid range
        returnsNormally, // Should not throw
      );
    });

    test('DateTimePickerAdapter handles invalid dates gracefully', () {
      expect(
        () => DateTimePickerAdapter(
          type: PickerDateTimeType.kYMD,
          value: DateTime(2023, 13, 32), // Invalid date
        ),
        returnsNormally,
      );
    });
  });
}