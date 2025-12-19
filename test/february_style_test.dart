// Tests for Issue #24: February selectedTextStyle Bug
// https://github.com/octologs/flutter_picker_plus/issues/24
//
// Bug Description:
// When using DateTimePickerAdapter with a custom selectedTextStyle:
// - Case 1: Scrolling the month column to February doesn't apply the selectedTextStyle
// - Case 2: When on February, scrolling the year column doesn't apply selectedTextStyle to year
//
// Root Cause:
// In picker.dart's onSelectedItemChanged callback (lines 1030-1047), when
// needUpdatePrev(i) returns true (which happens for February), the current
// column is NOT rebuilt (condition j != i skips it), so the selectedTextStyle
// is not applied.
//
// These tests will:
// - FAIL before the fix is applied (proving the bug exists)
// - PASS after the fix is applied (validating the fix works)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

void main() {
  group('Issue #24: February selectedTextStyle Bug', () {
    // =========================================================================
    // Group 1: Unit Tests for needUpdatePrev behavior
    // These tests verify the special February handling exists in the code
    // =========================================================================
    group('needUpdatePrev behavior', () {
      // NOTE: needUpdatePrev only returns true when:
      // 1. _needUpdatePrev is true (day column comes before month/year column)
      // 2. value.month == 2 (February)
      // 3. columnType is 0 (year) or 1 (month)
      //
      // kDMY (type 12) has column order [2, 1, 0] = Day, Month, Year
      // In this layout, day (index 0) < month (index 1), so _needUpdatePrev = true

      test(
          'needUpdatePrev returns true for February when using kDMY and columnType is month',
          () {
        // kDMY has Day before Month, so _needUpdatePrev will be true
        final adapter = DateTimePickerAdapter(
          type: PickerDateTimeType
              .kDMY, // Column order: Day(0), Month(1), Year(2)
          value: DateTime(2024, 2, 15), // February
        );

        final picker = Picker(adapter: adapter);
        adapter.picker = picker;
        adapter.initSelects();

        // For kDMY type, column 1 is month (columnType = 1)
        // needUpdatePrev should return true because:
        // - _needUpdatePrev = true (day before month in layout)
        // - value.month == 2 (February)
        // - columnType is 1 (month)
        final result = adapter.needUpdatePrev(1); // Month column index

        expect(result, isTrue,
            reason:
                'needUpdatePrev should return true for February with kDMY when columnType is month (1)');
      });

      test(
          'needUpdatePrev returns true for February when using kDMY and columnType is year',
          () {
        final adapter = DateTimePickerAdapter(
          type: PickerDateTimeType.kDMY,
          value: DateTime(2024, 2, 15), // February
        );

        final picker = Picker(adapter: adapter);
        adapter.picker = picker;
        adapter.initSelects();

        // For kDMY type, column 2 is year (columnType = 0)
        final result = adapter.needUpdatePrev(2); // Year column index in kDMY

        expect(result, isTrue,
            reason:
                'needUpdatePrev should return true for February with kDMY when columnType is year (0)');
      });

      test('needUpdatePrev returns false for non-February months with kDMY',
          () {
        // Even with kDMY layout, needUpdatePrev should return false for non-February
        final adapter = DateTimePickerAdapter(
          type: PickerDateTimeType.kDMY,
          value: DateTime(2024, 3, 15), // March (not February)
        );

        final picker = Picker(adapter: adapter);
        adapter.picker = picker;
        adapter.initSelects();

        // Should return false for March even with _needUpdatePrev = true
        final resultMonth = adapter.needUpdatePrev(1); // Month column
        final resultYear = adapter.needUpdatePrev(2); // Year column

        expect(resultMonth, isFalse,
            reason:
                'needUpdatePrev should return false for March (non-February)');
        expect(resultYear, isFalse,
            reason:
                'needUpdatePrev should return false for March (non-February)');
      });

      test('needUpdatePrev returns false for kYMD layout (day after month)',
          () {
        // kYMD has Year, Month, Day - day is AFTER month, so _needUpdatePrev = false
        final adapter = DateTimePickerAdapter(
          type: PickerDateTimeType.kYMD,
          value: DateTime(2024, 2, 15), // February
        );

        final picker = Picker(adapter: adapter);
        adapter.picker = picker;
        adapter.initSelects();

        // Even in February, needUpdatePrev returns false because
        // _needUpdatePrev = false (day after month in kYMD layout)
        expect(adapter.needUpdatePrev(1), isFalse,
            reason:
                'needUpdatePrev should return false for kYMD even in February');
        expect(adapter.needUpdatePrev(0), isFalse);
      });
    });

    // =========================================================================
    // Group 2: Widget Tests for selectedTextStyle application
    // These tests verify the visual styling is correctly applied
    // =========================================================================
    group('selectedTextStyle application', () {
      // Distinctive style that's easy to verify
      const testSelectedStyle = TextStyle(
        color: Colors.red,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
      );

      testWidgets(
        'BUG TEST: selectedTextStyle should be applied to February after scrolling (kDMY)',
        (WidgetTester tester) async {
          // Use kDMY layout where needUpdatePrev returns true for February
          final adapter = DateTimePickerAdapter(
            type: PickerDateTimeType.kDMY, // Day, Month, Year order
            isNumberMonth: true, // Show "1", "2", "3" for months
            value: DateTime(2024, 1, 15), // Start in January
            monthSuffix: '',
            yearSuffix: '',
            daySuffix: '',
          );

          final picker = Picker(
            adapter: adapter,
            selectedTextStyle: testSelectedStyle,
            hideHeader: true,
            smooth: 0,
            height: 200,
            itemExtent: 40,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: picker.makePicker(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify January is initially displayed
          expect(find.text('1'), findsWidgets);

          // Find the month column text and scroll to February
          // In kDMY, the month is the middle column (index 1)
          final januaryFinder = find.text('1').first;

          // Scroll upward to move from January to February
          await tester.drag(januaryFinder, const Offset(0, -40));
          await tester.pumpAndSettle();

          // Find the "2" text that represents February
          final februaryFinder = find.text('2');
          expect(februaryFinder, findsWidgets,
              reason: 'February (2) should be visible after scrolling');

          // Check if selectedTextStyle is applied to February
          bool foundStyledFebruary = false;
          final februaryWidgets = tester.widgetList(februaryFinder);

          for (final widget in februaryWidgets) {
            if (widget is Text) {
              final style = widget.style;
              if (style != null &&
                  style.color == Colors.red &&
                  style.fontSize == 24.0) {
                foundStyledFebruary = true;
                break;
              }
            }
          }

          // If not found via Text.style, check DefaultTextStyle
          if (!foundStyledFebruary) {
            try {
              final defaultTextStyles = find.ancestor(
                of: februaryFinder.first,
                matching: find.byType(DefaultTextStyle),
              );

              if (defaultTextStyles.evaluate().isNotEmpty) {
                final defaultTextStyle =
                    tester.widget<DefaultTextStyle>(defaultTextStyles.first);
                if (defaultTextStyle.style.color == Colors.red &&
                    defaultTextStyle.style.fontSize == 24.0) {
                  foundStyledFebruary = true;
                }
              }
            } catch (_) {
              // Finder might fail, continue with assertion
            }
          }

          // This assertion will FAIL before the fix and PASS after the fix
          expect(foundStyledFebruary, isTrue,
              reason: 'BUG: February should have selectedTextStyle applied '
                  'after being selected, but the style is not applied because '
                  'the column is not rebuilt when needUpdatePrev returns true');
        },
      );

      testWidgets(
        'BUG TEST: selectedTextStyle should be applied to year when scrolled while on February (kDMY)',
        (WidgetTester tester) async {
          // Use kDMY layout - start with February date
          final adapter = DateTimePickerAdapter(
            type: PickerDateTimeType.kDMY,
            isNumberMonth: true,
            value: DateTime(2024, 2, 15), // Already February
            monthSuffix: '',
            yearSuffix: '',
            daySuffix: '',
            yearBegin: 2020,
            yearEnd: 2030,
          );

          final picker = Picker(
            adapter: adapter,
            selectedTextStyle: testSelectedStyle,
            hideHeader: true,
            smooth: 0,
            height: 200,
            itemExtent: 40,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: picker.makePicker(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify we're on February
          expect(adapter.value?.month, equals(2));

          // Find the year "2024" and scroll to a different year
          final yearFinder = find.text('2024');
          expect(yearFinder, findsWidgets);

          // Scroll to change year
          await tester.drag(yearFinder.first, const Offset(0, -40));
          await tester.pumpAndSettle();

          // Find the new year text
          final newYearFinder = find.text('2025');

          // Check if the new year has selectedTextStyle applied
          bool foundStyledYear = false;

          if (newYearFinder.evaluate().isNotEmpty) {
            final yearWidgets = tester.widgetList(newYearFinder);

            for (final widget in yearWidgets) {
              if (widget is Text) {
                final style = widget.style;
                if (style != null &&
                    style.color == Colors.red &&
                    style.fontSize == 24.0) {
                  foundStyledYear = true;
                  break;
                }
              }
            }

            if (!foundStyledYear) {
              try {
                final defaultTextStyles = find.ancestor(
                  of: newYearFinder.first,
                  matching: find.byType(DefaultTextStyle),
                );

                if (defaultTextStyles.evaluate().isNotEmpty) {
                  final defaultTextStyle =
                      tester.widget<DefaultTextStyle>(defaultTextStyles.first);
                  if (defaultTextStyle.style.color == Colors.red &&
                      defaultTextStyle.style.fontSize == 24.0) {
                    foundStyledYear = true;
                  }
                }
              } catch (_) {
                // Continue with assertion
              }
            }
          }

          // This assertion will FAIL before the fix and PASS after the fix
          expect(foundStyledYear, isTrue,
              reason: 'BUG: Year should have selectedTextStyle applied '
                  'after being selected while on February');
        },
      );

      testWidgets(
        'CONTROL TEST: selectedTextStyle works for non-February months (March)',
        (WidgetTester tester) async {
          // Start in February, scroll to March (needUpdatePrev returns false for March)
          final adapter = DateTimePickerAdapter(
            type: PickerDateTimeType.kDMY,
            isNumberMonth: true,
            value: DateTime(2024, 2, 15), // Start in February
            monthSuffix: '',
            yearSuffix: '',
            daySuffix: '',
          );

          final picker = Picker(
            adapter: adapter,
            selectedTextStyle: testSelectedStyle,
            hideHeader: true,
            smooth: 0,
            height: 200,
            itemExtent: 40,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: picker.makePicker(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Find February (month "2") and scroll to March (month "3")
          final februaryFinder = find.text('2');

          // Scroll up to go from February to March
          await tester.drag(februaryFinder.first, const Offset(0, -40));
          await tester.pumpAndSettle();

          // Verify adapter value changed to March
          expect(adapter.value?.month, equals(3),
              reason: 'Month should be March after scrolling');

          // Find March text and check style
          final marchFinder = find.text('3');
          bool foundStyledMarch = false;

          if (marchFinder.evaluate().isNotEmpty) {
            final marchWidgets = tester.widgetList(marchFinder);

            for (final widget in marchWidgets) {
              if (widget is Text) {
                final style = widget.style;
                if (style != null &&
                    style.color == Colors.red &&
                    style.fontSize == 24.0) {
                  foundStyledMarch = true;
                  break;
                }
              }
            }

            if (!foundStyledMarch) {
              try {
                final defaultTextStyles = find.ancestor(
                  of: marchFinder.first,
                  matching: find.byType(DefaultTextStyle),
                );

                if (defaultTextStyles.evaluate().isNotEmpty) {
                  final defaultTextStyle =
                      tester.widget<DefaultTextStyle>(defaultTextStyles.first);
                  if (defaultTextStyle.style.color == Colors.red &&
                      defaultTextStyle.style.fontSize == 24.0) {
                    foundStyledMarch = true;
                  }
                }
              } catch (_) {
                // Continue
              }
            }
          }

          // This should PASS both before and after the fix
          expect(foundStyledMarch, isTrue,
              reason: 'CONTROL: March should have selectedTextStyle applied '
                  '(needUpdatePrev returns false for March)');
        },
      );
    });

    // =========================================================================
    // Group 3: Callback Tests for onBuilderItem verification
    // These tests use the onBuilderItem callback to track isSel values
    // =========================================================================
    group('onBuilderItem callback verification', () {
      testWidgets(
        'BUG TEST: onBuilderItem should receive isSel=true for February after scrolling (kDMY)',
        (WidgetTester tester) async {
          // Track all buildItem calls and their isSel values
          int februaryBuildCount = 0;
          bool februaryWasSelectedOnLastBuild = false;

          final adapter = DateTimePickerAdapter(
            type: PickerDateTimeType.kDMY, // Day, Month, Year
            isNumberMonth: true,
            value: DateTime(2024, 1, 15), // Start in January
            monthSuffix: '',
            yearSuffix: '',
            daySuffix: '',
          );

          final picker = Picker(
            adapter: adapter,
            hideHeader: true,
            smooth: 0,
            height: 200,
            itemExtent: 40,
            onBuilderItem: (context, text, child, isSel, col, index) {
              // Track February specifically (col 1 = month, index 1 = February)
              if (col == 1 && index == 1) {
                februaryBuildCount++;
                februaryWasSelectedOnLastBuild = isSel;
              }

              return null; // Use default rendering
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: picker.makePicker(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Track only post-scroll builds
          final initialFebruaryBuildCount = februaryBuildCount;

          // Scroll from January to February
          final januaryFinder = find.text('1').first;
          await tester.drag(januaryFinder, const Offset(0, -40));
          await tester.pumpAndSettle();

          // After scrolling, February should be selected
          expect(picker.selecteds[1], equals(1),
              reason: 'February (index 1) should be selected in month column');

          // Check if February was rebuilt with isSel=true after the scroll
          final wasFebruaryRebuilt =
              februaryBuildCount > initialFebruaryBuildCount;

          // This will FAIL before fix (February column not rebuilt when needUpdatePrev=true)
          // and PASS after fix
          expect(wasFebruaryRebuilt && februaryWasSelectedOnLastBuild, isTrue,
              reason: 'BUG: After scrolling to February, the February item '
                  'should be rebuilt with isSel=true, but it was not rebuilt '
                  'because needUpdatePrev returned true and the current column '
                  'was skipped in the rebuild loop');
        },
      );

      testWidgets(
        'BUG TEST: onBuilderItem should receive isSel=true for year after scrolling while on February (kDMY)',
        (WidgetTester tester) async {
          int year2025BuildCount = 0;
          bool year2025WasSelectedOnLastBuild = false;

          final adapter = DateTimePickerAdapter(
            type: PickerDateTimeType.kDMY,
            isNumberMonth: true,
            value: DateTime(2024, 2, 15), // Start in February
            monthSuffix: '',
            yearSuffix: '',
            daySuffix: '',
            yearBegin: 2020,
            yearEnd: 2030,
          );

          final picker = Picker(
            adapter: adapter,
            hideHeader: true,
            smooth: 0,
            height: 200,
            itemExtent: 40,
            onBuilderItem: (context, text, child, isSel, col, index) {
              // Track 2025 specifically (col 2 = year in kDMY)
              if (col == 2 && text == '2025') {
                year2025BuildCount++;
                year2025WasSelectedOnLastBuild = isSel;
              }

              return null;
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: picker.makePicker(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final initialYear2025BuildCount = year2025BuildCount;

          // Scroll year from 2024 to 2025
          final yearFinder = find.text('2024').first;
          await tester.drag(yearFinder, const Offset(0, -40));
          await tester.pumpAndSettle();

          // Check if 2025 was rebuilt with isSel=true
          final wasYear2025Rebuilt =
              year2025BuildCount > initialYear2025BuildCount;

          expect(wasYear2025Rebuilt && year2025WasSelectedOnLastBuild, isTrue,
              reason: 'BUG: After scrolling to 2025 while on February, '
                  'the year item should be rebuilt with isSel=true');
        },
      );

      testWidgets(
        'CONTROL TEST: onBuilderItem receives correct isSel for non-February month scroll',
        (WidgetTester tester) async {
          int aprilBuildCount = 0;
          bool aprilWasSelectedOnLastBuild = false;

          final adapter = DateTimePickerAdapter(
            type: PickerDateTimeType.kDMY,
            isNumberMonth: true,
            value: DateTime(2024, 3, 15), // Start in March
            monthSuffix: '',
            yearSuffix: '',
            daySuffix: '',
          );

          final picker = Picker(
            adapter: adapter,
            hideHeader: true,
            smooth: 0,
            height: 200,
            itemExtent: 40,
            onBuilderItem: (context, text, child, isSel, col, index) {
              // Track April (col 1 = month, index 3 = April)
              if (col == 1 && index == 3) {
                aprilBuildCount++;
                aprilWasSelectedOnLastBuild = isSel;
              }
              return null;
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: picker.makePicker(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final initialAprilBuildCount = aprilBuildCount;

          // Scroll from March to April
          final marchFinder = find.text('3').first;
          await tester.drag(marchFinder, const Offset(0, -40));
          await tester.pumpAndSettle();

          final wasAprilRebuilt = aprilBuildCount > initialAprilBuildCount;

          // This should PASS both before and after fix
          expect(wasAprilRebuilt && aprilWasSelectedOnLastBuild, isTrue,
              reason: 'CONTROL: April should be rebuilt with isSel=true '
                  'when scrolled from March (needUpdatePrev returns false)');
        },
      );
    });

    // =========================================================================
    // Group 4: Direct state verification tests
    // =========================================================================
    group('Direct state verification', () {
      test('picker.selecteds is correctly updated when scrolling to February',
          () {
        final adapter = DateTimePickerAdapter(
          type: PickerDateTimeType.kDMY,
          isNumberMonth: true,
          value: DateTime(2024, 1, 15), // January
        );

        final picker = Picker(adapter: adapter);
        adapter.picker = picker;
        adapter.initSelects();

        // Verify initial state - January (index 0 for month in kDMY is column 1)
        expect(picker.selecteds[1], equals(0),
            reason: 'Initial month selection should be 0 (January)');

        // Simulate selecting February
        picker.selecteds[1] = 1; // February index
        adapter.doSelect(1, 1); // Column 1 (month), index 1 (February)

        // Verify adapter value updated
        expect(adapter.value?.month, equals(2),
            reason: 'Adapter value should be updated to February');

        // Verify selecteds updated
        expect(picker.selecteds[1], equals(1),
            reason: 'picker.selecteds[1] should be 1 (February)');
      });

      test('adapter.value is correctly updated for February date changes', () {
        final adapter = DateTimePickerAdapter(
          type: PickerDateTimeType.kDMY,
          isNumberMonth: true,
          value: DateTime(2024, 2, 29), // Leap year February
        );

        final picker = Picker(adapter: adapter);
        adapter.picker = picker;
        adapter.initSelects();

        // Verify February 29 is valid in leap year
        expect(adapter.value?.day, equals(29));
        expect(adapter.value?.month, equals(2));
      });
    });

    // =========================================================================
    // Group 5: Regression tests for the specific bug scenarios from issue #24
    // =========================================================================
    group('Issue #24 Specific Scenarios', () {
      testWidgets(
        'Scenario 1: Scroll month to February - onSelect should be called',
        (WidgetTester tester) async {
          final adapter = DateTimePickerAdapter(
            type: PickerDateTimeType.kDMY, // Use kDMY for this test
            isNumberMonth: true,
            value: DateTime(2024, 1, 15),
          );

          bool onSelectCalled = false;
          int? selectedMonthIndex;

          final picker = Picker(
            adapter: adapter,
            hideHeader: true,
            height: 210,
            itemExtent: 35,
            selectedTextStyle:
                const TextStyle(color: Colors.black, fontSize: 23),
            onSelect: (p, index, selected) {
              onSelectCalled = true;
              selectedMonthIndex = selected[1]; // Month column in kDMY
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: picker.makePicker(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Scroll to February
          final monthFinder = find.text('1').first;
          await tester.drag(monthFinder, const Offset(0, -35));
          await tester.pumpAndSettle();

          expect(onSelectCalled, isTrue);
          expect(selectedMonthIndex, equals(1),
              reason: 'February (index 1) should be selected');

          // Verify the adapter value
          expect(adapter.value?.month, equals(2),
              reason: 'Adapter should report February');
        },
      );

      testWidgets(
        'Scenario 2: On February, scroll year - onSelect should be called',
        (WidgetTester tester) async {
          final adapter = DateTimePickerAdapter(
            type: PickerDateTimeType.kDMY,
            isNumberMonth: true,
            value: DateTime(2024, 2, 15), // Start on February
            yearBegin: 2020,
            yearEnd: 2030,
          );

          bool onSelectCalled = false;

          final picker = Picker(
            adapter: adapter,
            hideHeader: true,
            height: 210,
            itemExtent: 35,
            selectedTextStyle:
                const TextStyle(color: Colors.black, fontSize: 23),
            onSelect: (p, index, selected) {
              onSelectCalled = true;
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: picker.makePicker(),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify we're on February
          expect(adapter.value?.month, equals(2));

          // Scroll year column
          final yearFinder = find.text('2024').first;
          await tester.drag(yearFinder, const Offset(0, -35));
          await tester.pumpAndSettle();

          expect(onSelectCalled, isTrue);

          // Verify year changed
          expect(adapter.value?.year, isNot(equals(2024)),
              reason: 'Year should have changed after scrolling');
        },
      );
    });
  });
}
