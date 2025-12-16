import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

void main() {
  group('Picker Core Tests', () {
    testWidgets('Picker creates with required adapter',
        (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: ['Option 1', 'Option 2', 'Option 3'],
      );

      final picker = Picker(adapter: adapter);

      expect(picker.adapter, equals(adapter));
      expect(picker.selecteds, isNotNull);
    });

    testWidgets('Picker can be created and displayed',
        (WidgetTester tester) async {
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

    testWidgets('Picker displays cancel and confirm buttons by default',
        (WidgetTester tester) async {
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

    testWidgets('Picker calls onConfirm when confirm button tapped',
        (WidgetTester tester) async {
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

    testWidgets('Picker calls onCancel when cancel button tapped',
        (WidgetTester tester) async {
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

    testWidgets('Picker respects custom text styles',
        (WidgetTester tester) async {
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
        find
            .ancestor(
              of: find.text('Styled Text'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
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
          const NumberPickerColumn(
              begin: 0, end: 60, jump: 5), // Every 5 minutes
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
      expect(column.indexOf(15), equals(2)); // Not in sequence
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
    testWidgets('Picker with delimiters displays correctly',
        (WidgetTester tester) async {
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

    testWidgets('Picker selection updates correctly',
        (WidgetTester tester) async {
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

    testWidgets('Picker modal shows and dismisses correctly',
        (WidgetTester tester) async {
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

    testWidgets('Picker dialog shows and confirms correctly',
        (WidgetTester tester) async {
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

  // Tests for PR #22: Fix 3+ layer nested map parsing in _parsePickerDataItem
  // https://github.com/octologs/flutter_picker_plus/pull/22
  // Fixes issue #21: Hierarchical (Linkage) Picker show nothing for 3+ layers
  group('PR #22 - Deep Hierarchical Map Tests', () {
    test('PickerDataAdapter parses 3-layer nested map correctly', () {
      // This is the exact use case from issue #21 - 3 layer hierarchical data
      // Country -> State -> City
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          {
            'United States': {
              'California': ['Los Angeles', 'San Francisco', 'San Diego'],
              'Texas': ['Houston', 'Dallas', 'Austin'],
            },
            'Canada': {
              'Ontario': ['Toronto', 'Ottawa'],
              'Quebec': ['Montreal', 'Quebec City'],
            },
          }
        ],
      );

      // Verify top level - should have 2 countries
      expect(adapter.data.length, equals(2));
      expect(adapter.data[0].value, equals('United States'));
      expect(adapter.data[1].value, equals('Canada'));

      // Verify second level - United States should have 2 states
      expect(adapter.data[0].children, isNotNull);
      expect(adapter.data[0].children!.length, equals(2));
      expect(adapter.data[0].children![0].value, equals('California'));
      expect(adapter.data[0].children![1].value, equals('Texas'));

      // Verify third level - California should have 3 cities
      expect(adapter.data[0].children![0].children, isNotNull);
      expect(adapter.data[0].children![0].children!.length, equals(3));
      expect(adapter.data[0].children![0].children![0].value,
          equals('Los Angeles'));
      expect(adapter.data[0].children![0].children![1].value,
          equals('San Francisco'));
      expect(
          adapter.data[0].children![0].children![2].value, equals('San Diego'));

      // Verify Texas also has correct cities
      expect(adapter.data[0].children![1].children, isNotNull);
      expect(adapter.data[0].children![1].children!.length, equals(3));
      expect(
          adapter.data[0].children![1].children![0].value, equals('Houston'));

      // Verify maxLevel is 3 (country, state, city)
      expect(adapter.getMaxLevel(), equals(3));
    });

    test('PickerDataAdapter getSelectedValues works for 3-layer data', () {
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          {
            'Province1': {
              'City1': ['District1', 'District2'],
              'City2': ['District3', 'District4'],
            },
            'Province2': {
              'City3': ['District5', 'District6'],
            },
          }
        ],
      );

      final picker = Picker(adapter: adapter);
      adapter.picker = picker;
      // Must call getMaxLevel() first to calculate _maxLevel before initSelects()
      // This mimics what makePicker() does internally
      final maxLevel = adapter.getMaxLevel();
      expect(maxLevel, equals(3));
      adapter.initSelects();

      // Default selection should be [0, 0, 0] - first item at each level
      expect(picker.selecteds.length, equals(3));
      expect(picker.selecteds[0], equals(0));
      expect(picker.selecteds[1], equals(0));
      expect(picker.selecteds[2], equals(0));

      // getSelectedValues should return Province1, City1, District1
      final values = adapter.getSelectedValues();
      expect(values.length, equals(3));
      expect(values[0], equals('Province1'));
      expect(values[1], equals('City1'));
      expect(values[2], equals('District1'));

      // Change selection to second province, first city, second district
      picker.selecteds = [1, 0, 1];
      final values2 = adapter.getSelectedValues();
      expect(values2.length, equals(3));
      expect(values2[0], equals('Province2'));
      expect(values2[1], equals('City3'));
      expect(values2[2], equals('District6'));
    });

    test('PickerDataAdapter handles 4-layer nested map correctly', () {
      // Even deeper nesting to ensure the fix is robust
      // Continent -> Country -> State -> City
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          {
            'North America': {
              'United States': {
                'California': ['Los Angeles', 'San Francisco'],
              },
            },
            'Europe': {
              'Germany': {
                'Bavaria': ['Munich', 'Nuremberg'],
              },
            },
          }
        ],
      );

      // Verify 4 levels exist
      expect(adapter.getMaxLevel(), equals(4));
      expect(adapter.data.length, equals(2));

      // Verify all levels are correctly parsed
      expect(adapter.data[0].value, equals('North America'));
      expect(adapter.data[0].children![0].value, equals('United States'));
      expect(adapter.data[0].children![0].children![0].value,
          equals('California'));
      expect(adapter.data[0].children![0].children![0].children![0].value,
          equals('Los Angeles'));
    });

    test('PickerDataAdapter handles mixed map and list at different levels',
        () {
      // This tests the condition: (o is List || o is Map) && o.isNotEmpty
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          {
            'Category1': {
              'SubCategory1': ['Item1', 'Item2'], // Map -> Map -> List
            },
            'Category2': [
              'DirectItem1',
              'DirectItem2'
            ], // Map -> List (2 levels)
          }
        ],
      );

      expect(adapter.data.length, equals(2));
      expect(adapter.data[0].value, equals('Category1'));
      expect(adapter.data[1].value, equals('Category2'));

      // Category1 has nested map, so it has children with children
      expect(adapter.data[0].children, isNotNull);
      expect(adapter.data[0].children![0].value, equals('SubCategory1'));
      expect(adapter.data[0].children![0].children, isNotNull);
      expect(adapter.data[0].children![0].children!.length, equals(2));

      // Category2 has direct list, so it has children but no grandchildren
      expect(adapter.data[1].children, isNotNull);
      expect(adapter.data[1].children!.length, equals(2));
      expect(adapter.data[1].children![0].value, equals('DirectItem1'));
      expect(adapter.data[1].children![0].children, isNull);
    });

    testWidgets('Picker with 3-layer data displays all columns',
        (WidgetTester tester) async {
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          {
            'Province1': {
              'City1': ['District1', 'District2'],
            },
          }
        ],
      );

      final picker = Picker(
        adapter: adapter,
        title: const Text('Select Location'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: picker.makePicker(),
          ),
        ),
      );

      // Verify title is displayed
      expect(find.text('Select Location'), findsOneWidget);

      // Verify first column (province) item is displayed
      expect(find.text('Province1'), findsOneWidget);

      // Verify second column (city) item is displayed
      expect(find.text('City1'), findsOneWidget);

      // Verify third column (district) items are displayed
      expect(find.text('District1'), findsOneWidget);
      expect(find.text('District2'), findsOneWidget);
    });

    testWidgets('Picker modal with 3-layer data works correctly',
        (WidgetTester tester) async {
      List<int>? selectedIndices;
      Picker? confirmedPicker;

      final adapter = PickerDataAdapter<String>(
        pickerData: [
          {
            'Level1A': {
              'Level2A': ['Level3A', 'Level3B'],
            },
          }
        ],
      );

      final picker = Picker(
        adapter: adapter,
        onConfirm: (p, selected) {
          confirmedPicker = p;
          selectedIndices = selected;
        },
      );

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

      // Verify picker is shown with 3-layer data
      expect(find.text('Level1A'), findsOneWidget);
      expect(find.text('Level2A'), findsOneWidget);
      expect(find.text('Level3A'), findsOneWidget);

      // Confirm selection
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Verify callback was called with correct indices
      expect(selectedIndices, isNotNull);
      expect(selectedIndices!.length, equals(3));
      expect(selectedIndices![0], equals(0)); // Level1A
      expect(selectedIndices![1], equals(0)); // Level2A
      expect(selectedIndices![2], equals(0)); // Level3A

      // Verify selected values
      final values = confirmedPicker!.getSelectedValues();
      expect(values[0], equals('Level1A'));
      expect(values[1], equals('Level2A'));
      expect(values[2], equals('Level3A'));
    });

    test('PickerDataAdapter handles empty nested maps gracefully', () {
      final adapter = PickerDataAdapter<String>(
        pickerData: [
          {
            'NonEmpty': {
              'SubItem': ['Value1'],
            },
            'EmptyMap': <String, dynamic>{}, // Empty nested map
          }
        ],
      );

      // Should only parse non-empty items
      expect(adapter.data.length, equals(1));
      expect(adapter.data[0].value, equals('NonEmpty'));
    });

    test('Regression test: Issue #21 exact reproduction', () {
      // This reproduces the bug from issue #21 that was failing
      // Before PR #22, this would result in empty picker body
      // Original issue used Chinese location data, here we use English equivalent
      final pickerData = [
        {
          'California': {
            'Los Angeles': ['Downtown', 'Hollywood', 'Venice'],
            'San Francisco': ['Mission', 'Marina', 'SOMA'],
          },
          'New York': {
            'New York City': ['Manhattan', 'Brooklyn'],
            'Buffalo': ['Downtown', 'Elmwood'],
          },
        }
      ];

      final adapter = PickerDataAdapter<String>(pickerData: pickerData);

      // This should NOT be empty (was the bug in issue #21)
      expect(adapter.data, isNotEmpty);
      expect(adapter.data.length, equals(2));

      // Verify the hierarchical structure is correctly parsed
      expect(adapter.getMaxLevel(), equals(3));

      // Verify first state
      expect(adapter.data[0].value, equals('California'));
      expect(adapter.data[0].children, isNotNull);
      expect(adapter.data[0].children!.length, equals(2));

      // Verify first city under first state
      expect(adapter.data[0].children![0].value, equals('Los Angeles'));
      expect(adapter.data[0].children![0].children, isNotNull);
      expect(adapter.data[0].children![0].children!.length, equals(3));

      // Verify districts
      expect(
          adapter.data[0].children![0].children![0].value, equals('Downtown'));
    });
  });
}
