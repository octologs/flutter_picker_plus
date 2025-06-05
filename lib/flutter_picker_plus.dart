/// A customizable picker widget library for Flutter applications.
///
/// Flutter Picker Plus provides a comprehensive and highly customizable picker
/// widget that supports multiple data types, presentation modes, and extensive
/// styling options. It's a continuation and enhancement of the original
/// flutter_picker package.
///
/// ## Key Features
///
/// * **Multiple Data Sources**: Support for arrays, numeric ranges, and date/time
/// * **Flexible Presentation**: Modal, dialog, and bottom sheet display modes
/// * **Hierarchical Data**: Multi-level selection with linked columns
/// * **Customization**: Extensive styling, theming, and custom item builders
/// * **Internationalization**: Built-in support for 20+ languages
/// * **Performance**: Optimized scrolling with optional infinite looping
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_picker_plus/flutter_picker_plus.dart';
///
/// // Simple string picker
/// final picker = Picker(
///   adapter: PickerDataAdapter<String>(
///     pickerData: ['Option 1', 'Option 2', 'Option 3'],
///   ),
///   onConfirm: (picker, selected) {
///     print('Selected: ${picker.getSelectedValues()}');
///   },
/// );
///
/// // Show the picker
/// picker.showModal<List<int>>(context);
/// ```
///
/// ## Common Use Cases
///
/// ### Date and Time Selection
/// ```dart
/// final datePicker = Picker(
///   adapter: DateTimePickerAdapter(
///     type: PickerDateTimeType.kYMD,
///     value: DateTime.now(),
///   ),
/// );
/// ```
///
/// ### Numeric Range Selection
/// ```dart
/// final numberPicker = Picker(
///   adapter: NumberPickerAdapter(
///     data: [
///       NumberPickerColumn(begin: 1, end: 100), // 1-100
///       NumberPickerColumn(begin: 0, end: 59),  // 0-59
///     ],
///   ),
/// );
/// ```
///
/// ### Multi-Level Category Selection
/// ```dart
/// final categoryPicker = Picker(
///   adapter: PickerDataAdapter<String>(
///     pickerData: [
///       {
///         'Electronics': ['Phone', 'Laptop', 'Tablet'],
///         'Clothing': ['Shirt', 'Pants', 'Shoes'],
///         'Books': ['Fiction', 'Science', 'History'],
///       }
///     ],
///   ),
/// );
/// ```
///
/// See also:
/// * [Picker] - Main picker widget class
/// * [PickerDataAdapter] - For array-based data
/// * [NumberPickerAdapter] - For numeric ranges
/// * [DateTimePickerAdapter] - For date and time selection
/// * [PickerLocalizations] - For internationalization support
library;

export 'picker.dart';
export 'picker_localizations.dart';
export 'picker_localizations_delegate.dart';
