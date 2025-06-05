import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'dart:async';
import 'picker_localizations.dart';

/// Callback function that is called when a picker item is selected.
///
/// Parameters:
/// * [picker] - The picker instance that triggered the selection
/// * [index] - The column index of the selected item
/// * [selected] - List of all selected indices across all columns
typedef PickerSelectedCallback = void Function(
    Picker picker, int index, List<int> selected);

/// Callback function that is called when the picker selection is confirmed.
///
/// Parameters:
/// * [picker] - The picker instance that was confirmed
/// * [selected] - List of all selected indices across all columns
typedef PickerConfirmCallback = void Function(
    Picker picker, List<int> selected);

/// Callback function that is called before confirming the picker selection.
///
/// This callback allows for validation or custom logic before confirmation.
/// Return `true` to proceed with confirmation, `false` to cancel.
///
/// Parameters:
/// * [picker] - The picker instance being confirmed
/// * [selected] - List of all selected indices across all columns
///
/// Returns a [Future<bool>] indicating whether to proceed with confirmation.
typedef PickerConfirmBeforeCallback = Future<bool> Function(
    Picker picker, List<int> selected);

/// Callback function for formatting picker values to display strings.
///
/// This is used to customize how values are displayed in the picker.
///
/// Parameters:
/// * [value] - The value to be formatted
///
/// Returns a formatted string representation of the value.
typedef PickerValueFormat<T> = String Function(T value);

/// Builder function for customizing the picker widget.
///
/// This allows complete customization of how the picker is presented.
///
/// Parameters:
/// * [context] - The build context
/// * [pickerWidget] - The default picker widget
///
/// Returns a customized widget wrapping or replacing the picker.
typedef PickerWidgetBuilder = Widget Function(
    BuildContext context, Widget pickerWidget);

/// Builder function for customizing individual picker items.
///
/// This callback is called for each item in the picker columns.
/// If `null` is returned, the default item builder is used.
///
/// Parameters:
/// * [context] - The build context
/// * [text] - The text content of the item (may be null)
/// * [child] - The default child widget for the item (may be null)
/// * [selected] - Whether this item is currently selected
/// * [col] - The column index of this item
/// * [index] - The row index of this item within the column
///
/// Returns a custom widget for the item, or `null` to use the default.
typedef PickerItemBuilder = Widget? Function(BuildContext context, String? text,
    Widget? child, bool selected, int col, int index);

/// A customizable picker widget for Flutter applications.
///
/// The [Picker] class provides a flexible and customizable way to present
/// selection interfaces to users. It supports multiple columns, various data
/// adapters, and extensive customization options.
///
/// ## Features
///
/// * Multiple column support with custom flex ratios
/// * Various data adapters (arrays, numbers, date/time)
/// * Extensive styling and theming options
/// * Multiple presentation modes (modal, dialog, bottom sheet)
/// * Internationalization support
/// * Custom item builders and formatting
/// * Loop scrolling and smooth animations
///
/// ## Basic Usage
///
/// ```dart
/// final picker = Picker(
///   adapter: PickerDataAdapter<String>(
///     pickerData: ['Option 1', 'Option 2', 'Option 3'],
///   ),
///   onConfirm: (picker, selected) {
///     print('Selected: ${picker.getSelectedValues()}');
///   },
/// );
///
/// picker.showModal<List<int>>(context);
/// ```
///
/// ## Advanced Usage with Multiple Columns
///
/// ```dart
/// final picker = Picker(
///   adapter: PickerDataAdapter<String>(
///     pickerData: [
///       {'Fruits': ['Apple', 'Banana', 'Orange']},
///       {'Colors': ['Red', 'Green', 'Blue']},
///     ],
///   ),
///   title: Text('Choose Fruit and Color'),
///   columnFlex: [2, 1], // First column takes 2/3, second takes 1/3
///   onConfirm: (picker, selected) {
///     final values = picker.getSelectedValues();
///     print('Selected fruit: ${values[0]}, color: ${values[1]}');
///   },
/// );
/// ```
///
/// See also:
/// * [PickerAdapter] for different data sources
/// * [PickerDataAdapter] for array-based data
/// * [NumberPickerAdapter] for numeric ranges
/// * [DateTimePickerAdapter] for date and time selection
class Picker {
  static const double defaultTextSize = 18.0;

  /// List of currently selected item indices for each column.
  ///
  /// Each index corresponds to the selected item in its respective column.
  /// For example, if [selecteds] is [0, 2, 1], it means:
  /// - Column 0: first item (index 0) is selected
  /// - Column 1: third item (index 2) is selected  
  /// - Column 2: second item (index 1) is selected
  late List<int> selecteds;

  /// The data adapter that provides content and manages the picker's data.
  ///
  /// The adapter determines what data is displayed in the picker columns
  /// and how many columns are shown. Different adapter types support
  /// different data sources:
  /// - [PickerDataAdapter]: For list/array data
  /// - [NumberPickerAdapter]: For numeric ranges
  /// - [DateTimePickerAdapter]: For date and time selection
  late PickerAdapter adapter;

  /// Optional list of delimiters to insert between picker columns.
  ///
  /// Delimiters allow you to add custom widgets (like text or icons)
  /// between columns to improve visual separation or add context.
  ///
  /// Example:
  /// ```dart
  /// delimiter: [
  ///   PickerDelimiter(child: Text(':'), column: 1),
  ///   PickerDelimiter(child: Text(' '), column: 2),
  /// ]
  /// ```
  final List<PickerDelimiter>? delimiter;

  final VoidCallback? onCancel;
  final PickerSelectedCallback? onSelect;
  final PickerConfirmCallback? onConfirm;
  final PickerConfirmBeforeCallback? onConfirmBefore;

  /// Whether to automatically scroll child columns to the first item when parent selection changes.
  ///
  /// When `true`, selecting a different item in a parent column will reset
  /// all child columns to their first item. This is useful for hierarchical
  /// data where child options depend on parent selections.
  ///
  /// Defaults to `false`.
  final bool changeToFirst;

  /// Custom flex values for each picker column.
  ///
  /// Controls the relative width of each column. For example:
  /// - `[1, 1, 1]`: All columns have equal width
  /// - `[2, 1, 1]`: First column is twice as wide as others
  /// - `[3, 2, 1]`: First column takes 3/6, second takes 2/6, third takes 1/6
  ///
  /// If `null` or shorter than the number of columns, remaining columns
  /// use flex value of 1.
  final List<int>? columnFlex;

  final Widget? title;
  final Widget? cancel;
  final Widget? confirm;
  final String? cancelText;
  final String? confirmText;

  final double height;

  /// The height of each picker item in logical pixels.
  ///
  /// This determines the vertical space each item occupies in the picker.
  /// Larger values create more spacing between items, smaller values create
  /// more compact layouts.
  ///
  /// Defaults to 28.0 pixels.
  final double itemExtent;

  final TextStyle? textStyle,
      cancelTextStyle,
      confirmTextStyle,
      selectedTextStyle;
  final TextAlign textAlign;
  final IconThemeData? selectedIconTheme;

  /// Controls how text in the picker scales with the system font size.
  ///
  /// When `null`, uses the ambient [MediaQuery.textScalerOf] from the
  /// build context. This allows the picker text to respect user
  /// accessibility settings for text size.
  final TextScaler? textScaler;

  final EdgeInsetsGeometry? columnPadding;
  final Color? backgroundColor, headerColor, containerColor;

  /// Whether to hide the picker header (title, cancel, and confirm buttons).
  ///
  /// When `true`, only the picker columns are shown without any header.
  /// This is useful when embedding the picker in custom UI or when you
  /// want to handle confirmation through other means.
  ///
  /// Defaults to `false`.
  final bool hideHeader;

  /// Whether to display picker columns in reverse order.
  ///
  /// When `true`, columns are displayed from right to left instead of
  /// left to right. This can be useful for right-to-left locales or
  /// specific design requirements.
  ///
  /// Defaults to `false`.
  final bool reversedOrder;

  /// Custom builder for the picker header.
  ///
  /// When provided, this builder replaces the default header (which contains
  /// title, cancel, and confirm buttons). The [hideHeader] property is ignored
  /// when this builder is used.
  ///
  /// This allows complete customization of the header area.
  ///
  /// Example:
  /// ```dart
  /// builderHeader: (context) => Container(
  ///   padding: EdgeInsets.all(16),
  ///   child: Text('Custom Header'),
  /// )
  /// ```
  final WidgetBuilder? builderHeader;

  /// Custom builder for individual picker items.
  ///
  /// This callback is invoked for each item in every column, allowing
  /// complete customization of how items are displayed. If the callback
  /// returns `null`, the default item rendering is used.
  ///
  /// The builder receives information about the item's content, selection
  /// state, and position to enable context-aware customization.
  ///
  /// See [PickerItemBuilder] for detailed parameter information.
  final PickerItemBuilder? onBuilderItem;

  /// Whether picker items should loop infinitely when scrolling.
  ///
  /// When `true`, scrolling past the last item wraps to the first item,
  /// and scrolling before the first item wraps to the last item. This
  /// creates an infinite scrolling effect.
  ///
  /// When `false`, scrolling stops at the first and last items.
  ///
  /// Defaults to `false`.
  final bool looping;

  /// Delay in milliseconds before building picker content for smoother animations.
  ///
  /// This creates a brief delay before the picker content is rendered,
  /// which can make opening animations appear smoother, especially for
  /// complex pickers with many items.
  ///
  /// Recommended value is >= 200 milliseconds. Set to 0 to disable.
  ///
  /// Defaults to 0 (no delay).
  final int smooth;

  final Widget? footer;

  /// A widget overlaid on the picker to highlight the currently selected entry.
  final Widget selectionOverlay;

  final Decoration? headerDecoration;

  final double magnification;
  final double diameterRatio;
  final double squeeze;

  final bool printDebug;

  Widget? _widget;
  PickerWidgetState? _state;

  Picker(
      {required this.adapter,
      this.delimiter,
      List<int>? selecteds,
      this.height = 150.0,
      this.itemExtent = 28.0,
      this.columnPadding,
      this.textStyle,
      this.cancelTextStyle,
      this.confirmTextStyle,
      this.selectedTextStyle,
      this.selectedIconTheme,
      this.textAlign = TextAlign.start,
      this.textScaler,
      this.title,
      this.cancel,
      this.confirm,
      this.cancelText,
      this.confirmText,
      this.backgroundColor,
      this.containerColor,
      this.headerColor,
      this.builderHeader,
      this.changeToFirst = false,
      this.hideHeader = false,
      this.looping = false,
      this.reversedOrder = false,
      this.headerDecoration,
      this.columnFlex,
      this.footer,
      this.smooth = 0,
      this.magnification = 1.0,
      this.diameterRatio = 1.1,
      this.squeeze = 1.45,
      this.selectionOverlay = const CupertinoPickerDefaultSelectionOverlay(),
      this.onBuilderItem,
      this.onCancel,
      this.onSelect,
      this.onConfirmBefore,
      this.onConfirm,
      this.printDebug = false}) {
    this.selecteds = selecteds ?? <int>[];
  }

  Widget? get widget => _widget;
  PickerWidgetState? get state => _state;
  int _maxLevel = 1;

  /// Creates the picker widget with optional theme and modal configuration.
  ///
  /// This method builds the actual picker widget that can be embedded
  /// in your UI or displayed in dialogs/modals.
  ///
  /// Parameters:
  /// * [themeData] - Optional theme to override default styling
  /// * [isModal] - Whether the picker is displayed in a modal context
  /// * [key] - Optional widget key for the picker
  ///
  /// Returns the constructed picker widget.
  ///
  /// Example:
  /// ```dart
  /// Widget pickerWidget = picker.makePicker();
  /// ```
  Widget makePicker(
      [material.ThemeData? themeData, bool isModal = false, Key? key]) {
    _maxLevel = adapter.maxLevel;
    adapter.picker = this;
    adapter.initSelects();
    _widget = PickerWidget(
      key: key ?? ValueKey(this),
      data: this,
      child:
          _PickerWidget(picker: this, themeData: themeData, isModal: isModal),
    );
    return _widget!;
  }

  /// Shows the picker in a bottom sheet using the provided scaffold state.
  ///
  /// **Deprecated**: Use [showBottomSheet] instead, which works with BuildContext.
  ///
  /// Parameters:
  /// * [state] - The scaffold state to show the bottom sheet on
  /// * [themeData] - Optional theme for styling
  /// * [backgroundColor] - Background color of the bottom sheet
  /// * [builder] - Optional custom builder to wrap the picker
  void show(
    material.ScaffoldState state, {
    material.ThemeData? themeData,
    Color? backgroundColor,
    PickerWidgetBuilder? builder,
  }) {
    state.showBottomSheet((BuildContext context) {
      final picker = makePicker(themeData);
      return builder == null ? picker : builder(context, picker);
    }, backgroundColor: backgroundColor);
  }

  /// Shows the picker in a persistent bottom sheet.
  ///
  /// The bottom sheet remains visible until dismissed by user interaction
  /// or programmatically closed.
  ///
  /// Parameters:
  /// * [context] - Build context for showing the bottom sheet
  /// * [themeData] - Optional theme for styling
  /// * [backgroundColor] - Background color of the bottom sheet
  /// * [builder] - Optional custom builder to wrap the picker
  ///
  /// Example:
  /// ```dart
  /// picker.showBottomSheet(context);
  /// ```
  void showBottomSheet(
    BuildContext context, {
    material.ThemeData? themeData,
    Color? backgroundColor,
    PickerWidgetBuilder? builder,
  }) {
    material.Scaffold.of(context).showBottomSheet((BuildContext context) {
      final picker = makePicker(themeData);
      return builder == null ? picker : builder(context, picker);
    }, backgroundColor: backgroundColor);
  }

  /// Displays the picker in a modal bottom sheet.
  ///
  /// This is the most common way to show a picker. The modal appears
  /// from the bottom of the screen and can be dismissed by tapping
  /// outside or using the cancel button.
  ///
  /// Parameters:
  /// * [context] - Build context for showing the modal
  /// * [themeData] - Optional theme for styling
  /// * [isScrollControlled] - Whether the modal can scroll beyond 50% height
  /// * [useRootNavigator] - Whether to use the root navigator
  /// * [backgroundColor] - Background color of the modal
  /// * [shape] - Custom shape for the modal
  /// * [clipBehavior] - How to clip the modal content
  /// * [builder] - Optional custom builder to wrap the picker
  ///
  /// Returns a [Future] that completes when the modal is dismissed.
  /// The result contains the selected values or `null` if cancelled.
  ///
  /// Example:
  /// ```dart
  /// final result = await picker.showModal<List<int>>(context);
  /// if (result != null) {
  ///   print('Selected indices: $result');
  /// }
  /// ```
  Future<T?> showModal<T>(BuildContext context,
      {material.ThemeData? themeData,
      bool isScrollControlled = false,
      bool useRootNavigator = false,
      Color? backgroundColor,
      ShapeBorder? shape,
      Clip? clipBehavior,
      PickerWidgetBuilder? builder}) async {
    return await material.showModalBottomSheet<T>(
        context: context, //state.context,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        backgroundColor: backgroundColor,
        shape: shape,
        clipBehavior: clipBehavior,
        builder: (BuildContext context) {
          final picker = makePicker(themeData, true);
          return builder == null ? picker : builder(context, picker);
        });
  }

  /// show dialog picker
  Future<List<int>?> showDialog(BuildContext context,
      {bool barrierDismissible = true,
      Color? backgroundColor,
      PickerWidgetBuilder? builder,
      Key? key}) {
    return material.showDialog<List<int>>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (BuildContext context) {
          final actions = <Widget>[];
          final theme = material.Theme.of(context);
          final cancelWidget = PickerWidgetState._buildButton(
              context, cancelText, cancel, cancelTextStyle, true, theme, () {
            Navigator.pop<List<int>>(context, null);
            if (onCancel != null) {
              onCancel!();
            }
          });
          if (cancelWidget != null) {
            actions.add(cancelWidget);
          }
          final confirmWidget = PickerWidgetState._buildButton(
              context, confirmText, confirm, confirmTextStyle, false, theme,
              () async {
            if (onConfirmBefore != null &&
                !(await onConfirmBefore!(this, selecteds))) {
              return; // Cancel;
            }
            if (context.mounted) {
              Navigator.pop<List<int>>(context, selecteds);
            }
            if (onConfirm != null) {
              onConfirm!(this, selecteds);
            }
          });
          if (confirmWidget != null) {
            actions.add(confirmWidget);
          }
          return material.AlertDialog(
            key: key ?? const Key('picker-dialog'),
            title: title,
            backgroundColor: backgroundColor,
            actions: actions,
            content: builder == null
                ? makePicker(theme)
                : builder(context, makePicker(theme)),
          );
        });
  }

  /// Gets the currently selected values from the picker.
  ///
  /// Returns a list containing the actual values (not indices) that are
  /// currently selected in each column. The type and format of values
  /// depends on the adapter being used.
  ///
  /// For [PickerDataAdapter]: Returns the actual data items
  /// For [NumberPickerAdapter]: Returns the numeric values
  /// For [DateTimePickerAdapter]: Returns DateTime components
  ///
  /// Example:
  /// ```dart
  /// final values = picker.getSelectedValues();
  /// print('Selected: $values'); // e.g., ['Apple', 'Red']
  /// ```
  List getSelectedValues() {
    return adapter.getSelectedValues();
  }

  /// Cancel
  void doCancel(BuildContext context) {
    Navigator.of(context).pop<List<int>>(null);
    if (onCancel != null) onCancel!();
    _widget = null;
  }

  /// Confirm
  void doConfirm(BuildContext context) async {
    if (onConfirmBefore != null && !(await onConfirmBefore!(this, selecteds))) {
      return; // Cancel;
    }
    if (context.mounted) {
      Navigator.of(context).pop<List<int>>(selecteds);
    }
    if (onConfirm != null) onConfirm!(this, selecteds);
    _widget = null;
  }

  /// Force update the content of specified column
  /// When modifying the content of columns before the current column in the onSelect event, this method can be called to update the display
  void updateColumn(int index, [bool all = false]) {
    if (all) {
      _state?.update();
      return;
    }
    if (_state?._keys[index] != null) {
      adapter.setColumn(index - 1);
      _state?._keys[index]!(() {});
    }
  }

  static material.ButtonStyle _getButtonStyle(material.ButtonThemeData? theme,
          [isCancelButton = false]) =>
      material.TextButton.styleFrom(
          minimumSize: Size(theme?.minWidth ?? 0.0, 42),
          textStyle: TextStyle(
            fontSize: Picker.defaultTextSize,
            color: isCancelButton ? null : theme?.colorScheme?.secondary,
          ),
          padding: theme?.padding);
}

/// A delimiter widget that can be inserted between picker columns.
///
/// Delimiters allow you to add visual separators or contextual elements
/// between picker columns to improve readability and user experience.
///
/// Example:
/// ```dart
/// delimiter: [
///   PickerDelimiter(child: Text(':'), column: 1),
///   PickerDelimiter(child: Icon(Icons.arrow_forward), column: 2),
/// ]
/// ```
class PickerDelimiter {
  /// The widget to display as a delimiter.
  ///
  /// This can be any Flutter widget such as Text, Icon, or Container.
  final Widget? child;

  /// The column position where this delimiter should be inserted.
  ///
  /// - Values < 0: Insert at the beginning (before first column)
  /// - Values >= number of columns: Insert at the end (after last column)  
  /// - Other values: Insert at the specified position
  ///
  /// Defaults to 1 (between first and second column).
  final int column;

  /// Creates a picker delimiter.
  ///
  /// Parameters:
  /// * [child] - The widget to display as delimiter
  /// * [column] - Position to insert the delimiter (defaults to 1)
  PickerDelimiter({required this.child, this.column = 1});
}

/// Represents a single item in a picker column with optional hierarchical children.
///
/// [PickerItem] is the fundamental data structure used by [PickerDataAdapter]
/// to represent selectable items. Items can have custom display widgets,
/// associated data values, and child items for hierarchical data structures.
///
/// ## Simple Items
///
/// ```dart
/// PickerItem<String>(
///   text: Text('Apple'),
///   value: 'apple',
/// )
/// ```
///
/// ## Hierarchical Items
///
/// ```dart
/// PickerItem<String>(
///   text: Text('Fruits'),
///   value: 'fruits',
///   children: [
///     PickerItem(text: Text('Apple'), value: 'apple'),
///     PickerItem(text: Text('Banana'), value: 'banana'),
///   ],
/// )
/// ```
class PickerItem<T> {
  /// The widget used to display this item in the picker.
  ///
  /// When `null`, the picker will use the string representation of [value]
  /// or a default text widget. Custom widgets allow for rich formatting,
  /// icons, or complex layouts.
  final Widget? text;

  /// The actual data value associated with this item.
  ///
  /// This is the value returned when this item is selected. It can be
  /// any type [T] such as String, int, or custom objects.
  final T? value;

  /// Child items for hierarchical data structures.
  ///
  /// When provided, selecting this item will reveal the children in
  /// subsequent columns, creating a drill-down navigation experience.
  /// Used for multi-level data like Country > State > City.
  final List<PickerItem<T>>? children;

  /// Creates a picker item.
  ///
  /// Parameters:
  /// * [text] - Widget to display in the picker (optional)
  /// * [value] - Data value associated with this item (optional) 
  /// * [children] - Child items for hierarchical structures (optional)
  ///
  /// At least one of [text] or [value] should be provided.
  PickerItem({this.text, this.value, this.children});
}

class PickerWidget<T> extends InheritedWidget {
  final Picker data;
  const PickerWidget({super.key, required this.data, required super.child});
  @override
  bool updateShouldNotify(covariant PickerWidget oldWidget) =>
      oldWidget.data != data;

  static PickerWidget of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PickerWidget>()
        as PickerWidget;
  }
}

class _PickerWidget<T> extends StatefulWidget {
  final Picker picker;
  final material.ThemeData? themeData;
  final bool isModal;
  const _PickerWidget(
      {super.key, required this.picker, this.themeData, required this.isModal});

  @override
  PickerWidgetState createState() => PickerWidgetState<T>();
}

class PickerWidgetState<T> extends State<_PickerWidget> {
  Picker get picker => widget.picker;
  material.ThemeData? get themeData => widget.themeData;

  material.ThemeData? theme;
  final List<FixedExtentScrollController> scrollController = [];
  final List<StateSetter?> _keys = [];

  @override
  void initState() {
    super.initState();
    picker._state = this;
    picker.adapter.doShow();

    if (scrollController.isEmpty) {
      for (int i = 0; i < picker._maxLevel; i++) {
        scrollController
            .add(FixedExtentScrollController(initialItem: picker.selecteds[i]));
        _keys.add(null);
      }
    }
  }

  void update() {
    setState(() {});
  }

  // var ref = 0;
  @override
  Widget build(BuildContext context) {
    // print("picker build ${ref++}");
    theme = themeData ?? material.Theme.of(context);

    if (_wait && picker.smooth > 0) {
      Future.delayed(Duration(milliseconds: picker.smooth), () {
        if (!_wait) return;
        setState(() {
          _wait = false;
        });
      });
    } else {
      _wait = false;
    }

    final bodyWidgets = <Widget>[];
    if (!picker.hideHeader) {
      if (picker.builderHeader != null) {
        bodyWidgets.add(picker.headerDecoration == null
            ? picker.builderHeader!(context)
            : DecoratedBox(
                decoration: picker.headerDecoration!,
                child: picker.builderHeader!(context)));
      } else {
        bodyWidgets.add(DecoratedBox(
          decoration: picker.headerDecoration ??
              BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme!.dividerColor, width: 0.5),
                  bottom: BorderSide(color: theme!.dividerColor, width: 0.5),
                ),
                color: picker.headerColor ?? theme?.bottomAppBarTheme.color,
              ),
          child: Row(
            children: _buildHeaderViews(context),
          ),
        ));
      }
    }

    bodyWidgets.add(_wait
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildViews(),
          )
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildViews(),
            ),
          ));

    if (picker.footer != null) bodyWidgets.add(picker.footer!);
    Widget v = Column(
      mainAxisSize: MainAxisSize.min,
      children: bodyWidgets,
    );
    if (widget.isModal) {
      return GestureDetector(
        onTap: () {},
        child: v,
      );
    }
    return v;
  }

  List<Widget>? _headerItems;

  List<Widget> _buildHeaderViews(BuildContext context) {
    if (_headerItems != null) {
      return _headerItems!;
    }
    theme ??= material.Theme.of(context);
    List<Widget> items = [];

    final cancelWidget = _buildButton(context, picker.cancelText, picker.cancel,
        picker.cancelTextStyle, true, theme, () => picker.doCancel(context));
    if (cancelWidget != null) {
      items.add(cancelWidget);
    }

    items.add(Expanded(
      child: picker.title == null
          ? const SizedBox()
          : DefaultTextStyle(
              style: theme!.textTheme.titleLarge?.copyWith(
                    fontSize: Picker.defaultTextSize,
                  ) ??
                  const TextStyle(fontSize: Picker.defaultTextSize),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              child: picker.title!),
    ));

    final confirmWidget = _buildButton(
        context,
        picker.confirmText,
        picker.confirm,
        picker.confirmTextStyle,
        false,
        theme,
        () => picker.doConfirm(context));
    if (confirmWidget != null) {
      items.add(confirmWidget);
    }

    _headerItems = items;
    return items;
  }

  static Widget? _buildButton(
      BuildContext context,
      String? text,
      Widget? widget,
      TextStyle? textStyle,
      bool isCancel,
      material.ThemeData? theme,
      VoidCallback? onPressed) {
    if (widget == null) {
      String? txt = text ??
          (isCancel
              ? PickerLocalizations.of(context).cancelText
              : PickerLocalizations.of(context).confirmText);
      if (txt == null || txt.isEmpty) {
        return null;
      }
      return material.TextButton(
          style: Picker._getButtonStyle(
              material.ButtonTheme.of(context), isCancel),
          onPressed: onPressed,
          child: Text(txt,
              overflow: TextOverflow.ellipsis,
              textScaler: MediaQuery.of(context).textScaler,
              style: textStyle));
    } else {
      return textStyle == null
          ? widget
          : DefaultTextStyle(style: textStyle, child: widget);
    }
  }

  bool _changing = false;
  bool _wait = true;
  final Map<int, int> lastData = {};

  List<Widget> _buildViews() {
    // ignore: avoid_print
    if (picker.printDebug) print("_buildViews");
    theme ??= material.Theme.of(context);
    for (int j = 0; j < _keys.length; j++) {
      _keys[j] = null;
    }

    List<Widget> items = [];
    PickerAdapter? adapter = picker.adapter;
    adapter.setColumn(-1);

    final decoration = BoxDecoration(
      color: picker.containerColor ?? theme!.dialogTheme.backgroundColor,
    );

    if (adapter.length > 0) {
      for (int i = 0; i < picker._maxLevel; i++) {
        Widget view = Expanded(
          flex: adapter.getColumnFlex(i),
          child: Container(
            padding: picker.columnPadding,
            height: picker.height,
            decoration: decoration,
            child: _wait
                ? null
                : StatefulBuilder(
                    builder: (context, state) {
                      _keys[i] = state;
                      adapter.setColumn(i - 1);
                      // ignore: avoid_print
                      if (picker.printDebug) print("builder. col: $i");

                      // Last time was empty list
                      final lastIsEmpty = scrollController[i].hasClients &&
                          !scrollController[i].position.hasContentDimensions;

                      final length = adapter.length;
                      final viewWidget = _buildCupertinoPicker(
                          context,
                          i,
                          length,
                          adapter,
                          lastIsEmpty ? ValueKey(length) : null);

                      if (lastIsEmpty ||
                          (!picker.changeToFirst &&
                              picker.selecteds[i] >= length)) {
                        Timer(const Duration(milliseconds: 100), () {
                          if (!mounted) return;
                          // ignore: avoid_print
                          if (picker.printDebug) print("timer last");
                          var len = adapter.length;
                          var idx = (len < length ? len : length) - 1;
                          if (scrollController[i]
                              .position
                              .hasContentDimensions) {
                            scrollController[i].jumpToItem(idx);
                          } else {
                            scrollController[i] =
                                FixedExtentScrollController(initialItem: idx);
                            if (_keys[i] != null) {
                              _keys[i]!(() {});
                            }
                          }
                        });
                      }

                      return viewWidget;
                    },
                  ),
          ),
        );
        items.add(view);
      }
    }

    if (picker.delimiter != null && !_wait) {
      for (int i = 0; i < picker.delimiter!.length; i++) {
        var o = picker.delimiter![i];
        if (o.child == null) continue;
        var item = SizedBox(
            height: picker.height,
            child: DecoratedBox(
              decoration: decoration,
              child: o.child,
            ));
        if (o.column < 0) {
          items.insert(0, item);
        } else if (o.column >= items.length) {
          items.add(item);
        } else {
          items.insert(o.column, item);
        }
      }
    }

    if (picker.reversedOrder) return items.reversed.toList();

    return items;
  }

  Widget _buildCupertinoPicker(BuildContext context, int i, int length,
      PickerAdapter adapter, Key? key) {
    return CupertinoPicker.builder(
      key: key,
      backgroundColor: picker.backgroundColor,
      scrollController: scrollController[i],
      itemExtent: picker.itemExtent,
      // looping: picker.looping,
      magnification: picker.magnification,
      diameterRatio: picker.diameterRatio,
      squeeze: picker.squeeze,
      selectionOverlay: picker.selectionOverlay,
      childCount: picker.looping ? null : length,
      itemBuilder: (context, index) {
        adapter.setColumn(i - 1);
        return adapter.buildItem(context, index % length);
      },
      onSelectedItemChanged: (int idx) {
        if (length <= 0) return;
        var index = idx % length;
        if (picker.printDebug) {
          // ignore: avoid_print
          print("onSelectedItemChanged. col: $i, row: $index");
        }
        picker.selecteds[i] = index;
        updateScrollController(i);
        adapter.doSelect(i, index);
        if (picker.changeToFirst) {
          for (int j = i + 1; j < picker.selecteds.length; j++) {
            picker.selecteds[j] = 0;
            scrollController[j].jumpTo(0.0);
          }
        }
        if (picker.onSelect != null) {
          picker.onSelect!(picker, i, picker.selecteds);
        }

        if (adapter.needUpdatePrev(i)) {
          for (int j = 0; j < picker.selecteds.length; j++) {
            if (j != i && _keys[j] != null) {
              adapter.setColumn(j - 1);
              _keys[j]!(() {});
            }
          }
          // setState(() {});
        } else {
          if (_keys[i] != null) _keys[i]!(() {});
          if (adapter.isLinkage) {
            for (int j = i + 1; j < picker.selecteds.length; j++) {
              if (j == i) continue;
              adapter.setColumn(j - 1);
              _keys[j]?.call(() {});
            }
          }
        }
      },
    );
  }

  void updateScrollController(int col) {
    if (_changing || picker.adapter.isLinkage == false) return;
    _changing = true;
    for (int j = 0; j < picker.selecteds.length; j++) {
      if (j != col) {
        if (scrollController[j].hasClients &&
            scrollController[j].position.hasContentDimensions) {
          scrollController[j].position.notifyListeners();
        }
      }
    }
    _changing = false;
  }

  @override
  void debugFillProperties(properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('_changing', _changing));
  }
}

/// Abstract base class for picker data adapters.
///
/// [PickerAdapter] defines the interface that all picker data sources must
/// implement. Different adapters provide different types of data and behaviors:
///
/// * [PickerDataAdapter] - For array/list based data with hierarchical support
/// * [NumberPickerAdapter] - For numeric ranges and sequences  
/// * [DateTimePickerAdapter] - For date and time selection
///
/// ## Custom Adapters
///
/// You can create custom adapters by extending this class:
///
/// ```dart
/// class MyCustomAdapter extends PickerAdapter<MyDataType> {
///   @override
///   int getLength() => myData.length;
///   
///   @override
///   int getMaxLevel() => 1;
///   
///   @override
///   Widget buildItem(BuildContext context, int index) {
///     return Text(myData[index].toString());
///   }
///   
///   // ... implement other required methods
/// }
/// ```
///
/// See also:
/// * [PickerDataAdapter] for the most common use cases
/// * [NumberPickerAdapter] for numeric data
/// * [DateTimePickerAdapter] for date/time selection
abstract class PickerAdapter<T> {
  /// Reference to the picker widget using this adapter.
  ///
  /// This is set automatically when the adapter is assigned to a picker.
  Picker? picker;

  /// Returns the number of items in the current column.
  ///
  /// This method is called to determine how many items should be displayed
  /// in the currently active column.
  int getLength();

  /// Returns the maximum number of columns (levels) this adapter supports.
  ///
  /// For simple single-column data, return 1.
  /// For hierarchical data, return the maximum depth.
  int getMaxLevel();

  /// Sets the active column for subsequent operations.
  ///
  /// This method is called before [getLength] and [buildItem] to specify
  /// which column is being processed. The index is typically 0-based.
  ///
  /// Parameters:
  /// * [index] - The column index to activate
  void setColumn(int index);

  /// Initializes the selected indices for all columns.
  ///
  /// This method is called once when the picker is first displayed to
  /// set up default selections for each column.
  void initSelects();

  /// Builds the widget for a specific item in the current column.
  ///
  /// This method is called for each visible item in the picker to create
  /// the widget that represents that item.
  ///
  /// Parameters:
  /// * [context] - The build context
  /// * [index] - The item index within the current column
  ///
  /// Returns a widget representing the item.
  Widget buildItem(BuildContext context, int index);

  /// Need to update previous columns
  bool needUpdatePrev(int curIndex) {
    return false;
  }

  Widget makeText(Widget? child, String? text, bool isSel) {
    final theme = picker!.textStyle != null || picker!.state?.context == null
        ? null
        : material.Theme.of(picker!.state!.context);
    return Center(
        child: DefaultTextStyle(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: picker!.textAlign,
            style: picker!.textStyle ??
                TextStyle(
                    color: theme?.brightness == Brightness.dark
                        ? material.Colors.white
                        : material.Colors.black87,
                    fontFamily: theme == null
                        ? ""
                        : theme.textTheme.titleLarge?.fontFamily,
                    fontSize: Picker.defaultTextSize),
            child: child != null
                ? (isSel && picker!.selectedIconTheme != null
                    ? IconTheme(
                        data: picker!.selectedIconTheme!,
                        child: child,
                      )
                    : child)
                : Text(text ?? "",
                    textScaler: picker!.textScaler,
                    style: (isSel ? picker!.selectedTextStyle : null))));
  }

  Widget makeTextEx(
      Widget? child, String text, Widget? postfix, Widget? suffix, bool isSel) {
    List<Widget> items = [];
    if (postfix != null) items.add(postfix);
    items.add(
        child ?? Text(text, style: (isSel ? picker!.selectedTextStyle : null)));
    if (suffix != null) items.add(suffix);
    final theme = picker!.textStyle != null || picker!.state?.context == null
        ? null
        : material.Theme.of(picker!.state!.context);
    Color? txtColor = theme?.brightness == Brightness.dark
        ? material.Colors.white
        : material.Colors.black87;
    double? txtSize = Picker.defaultTextSize;
    if (isSel && picker!.selectedTextStyle != null) {
      if (picker!.selectedTextStyle!.color != null) {
        txtColor = picker!.selectedTextStyle!.color;
      }
      if (picker!.selectedTextStyle!.fontSize != null) {
        txtSize = picker!.selectedTextStyle!.fontSize;
      }
    }

    return Center(
        child: DefaultTextStyle(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: picker!.textAlign,
            style: picker!.textStyle ??
                TextStyle(
                    color: txtColor,
                    fontSize: txtSize,
                    fontFamily: theme == null
                        ? ""
                        : theme.textTheme.titleLarge?.fontFamily),
            child: Wrap(
              children: items,
            )));
  }

  String getText() {
    return getSelectedValues().toString();
  }

  List<T> getSelectedValues() {
    return [];
  }

  void doShow() {}
  void doSelect(int column, int index) {}

  int getColumnFlex(int column) {
    if (picker!.columnFlex != null && column < picker!.columnFlex!.length) {
      return picker!.columnFlex![column];
    }
    return 1;
  }

  int get maxLevel => getMaxLevel();

  /// Content length of current column
  int get length => getLength();

  String get text => getText();

  // Whether linked, i.e., subsequent columns are affected by data in previous columns
  bool get isLinkage => getIsLinkage();

  @override
  String toString() {
    return getText();
  }

  bool getIsLinkage() {
    return true;
  }

  /// Notify adapter of data changes
  void notifyDataChanged() {
    if (picker?.state != null) {
      picker!.adapter.doShow();
      picker!.adapter.initSelects();
      for (int j = 0; j < picker!.selecteds.length; j++) {
        picker!.state!.scrollController[j].jumpToItem(picker!.selecteds[j]);
      }
    }
  }
}

/// A picker adapter for array-based and hierarchical data structures.
///
/// [PickerDataAdapter] is the most commonly used adapter that supports
/// both simple arrays and complex hierarchical data. It can handle:
///
/// * Simple lists: `['Option 1', 'Option 2', 'Option 3']`
/// * Multi-dimensional arrays for independent columns
/// * Hierarchical maps for linked columns: `{'Category': ['Item1', 'Item2']}`
/// * Mixed data types with custom [PickerItem] objects
///
/// ## Simple Array Example
///
/// ```dart
/// final adapter = PickerDataAdapter<String>(
///   pickerData: ['Apple', 'Banana', 'Orange'],
/// );
/// ```
///
/// ## Multi-Column Array Example (Independent Columns)
///
/// ```dart
/// final adapter = PickerDataAdapter<String>(
///   pickerData: [
///     ['Red', 'Green', 'Blue'],     // Column 1: Colors
///     ['Small', 'Medium', 'Large'], // Column 2: Sizes
///   ],
///   isArray: true,
/// );
/// ```
///
/// ## Hierarchical Example (Linked Columns)
///
/// ```dart
/// final adapter = PickerDataAdapter<String>(
///   pickerData: [
///     {
///       'Fruits': ['Apple', 'Banana', 'Orange'],
///       'Vegetables': ['Carrot', 'Broccoli', 'Spinach'],
///     }
///   ],
/// );
/// ```
///
/// ## Custom PickerItem Example
///
/// ```dart
/// final adapter = PickerDataAdapter<String>(
///   data: [
///     PickerItem<String>(
///       text: Row(children: [Icon(Icons.apple), Text('Apple')]),
///       value: 'apple',
///     ),
///     PickerItem<String>(
///       text: Row(children: [Icon(Icons.android), Text('Banana')]),
///       value: 'banana', 
///     ),
///   ],
/// );
/// ```
class PickerDataAdapter<T> extends PickerAdapter<T> {
  late List<PickerItem<T>> data;
  List<PickerItem<dynamic>>? _datas;
  int _maxLevel = -1;
  int _col = 0;
  final bool isArray;

  PickerDataAdapter(
      {List? pickerData, List<PickerItem<T>>? data, this.isArray = false}) {
    this.data = data ?? <PickerItem<T>>[];
    _parseData(pickerData);
  }

  @override
  bool getIsLinkage() {
    return !isArray;
  }

  void _parseData(List? pickerData) {
    if (pickerData != null && pickerData.isNotEmpty && (data.isEmpty)) {
      if (isArray) {
        _parseArrayPickerDataItem(pickerData, data);
      } else {
        _parsePickerDataItem(pickerData, data);
      }
    }
  }

  void _parseArrayPickerDataItem(List? pickerData, List<PickerItem> data) {
    if (pickerData == null) return;
    var len = pickerData.length;
    for (int i = 0; i < len; i++) {
      var v = pickerData[i];
      if (v is! List) continue;
      List lv = v;
      if (lv.isEmpty) continue;

      PickerItem item = PickerItem<T>(children: <PickerItem<T>>[]);
      data.add(item);

      for (int j = 0; j < lv.length; j++) {
        var o = lv[j];
        if (o is T) {
          item.children!.add(PickerItem<T>(value: o));
        } else if (T == String) {
          String str = o.toString();
          item.children!.add(PickerItem<T>(value: str as T));
        }
      }
    }
    // ignore: avoid_print
    if (picker?.printDebug == true) print("data.length: ${data.length}");
  }

  void _parsePickerDataItem(List? pickerData, List<PickerItem> data) {
    if (pickerData == null) return;
    var len = pickerData.length;
    for (int i = 0; i < len; i++) {
      var item = pickerData[i];
      if (item is T) {
        data.add(PickerItem<T>(value: item));
      } else if (item is Map) {
        final Map map = item;
        if (map.isEmpty) continue;

        List<T> mapList = map.keys.toList().cast();
        for (int j = 0; j < mapList.length; j++) {
          var o = map[mapList[j]];
          if (o is List && o.isNotEmpty) {
            List<PickerItem<T>> children = <PickerItem<T>>[];
            //print('add: ${data.runtimeType.toString()}');
            data.add(PickerItem<T>(value: mapList[j], children: children));
            _parsePickerDataItem(o, children);
          }
        }
      } else if (T == String && item is! List) {
        String v = item.toString();
        //print('add: $_v');
        data.add(PickerItem<T>(value: v as T));
      }
    }
  }

  @override
  void setColumn(int index) {
    if (_datas != null && _col == index + 1) return;
    _col = index + 1;
    if (isArray) {
      // ignore: avoid_print
      if (picker!.printDebug) print("index: $index");
      if (_col < data.length) {
        _datas = data[_col].children;
      } else {
        _datas = null;
      }
      return;
    }
    if (index < 0) {
      _datas = data;
    } else {
      _datas = data;
      // Too many columns will have performance issues
      for (int i = 0; i <= index; i++) {
        var j = picker!.selecteds[i];
        if (_datas != null && _datas!.length > j) {
          _datas = _datas![j].children;
        } else {
          _datas = null;
          break;
        }
      }
    }
  }

  @override
  int getLength() => _datas?.length ?? 0;

  @override
  getMaxLevel() {
    if (_maxLevel == -1) _checkPickerDataLevel(data, 1);
    return _maxLevel;
  }

  @override
  Widget buildItem(BuildContext context, int index) {
    final PickerItem item = _datas![index];
    final isSel = index == picker!.selecteds[_col];
    final theme = Theme.of(context);

    if (picker!.onBuilderItem != null) {
      final v = picker!.onBuilderItem!(
          context, item.value.toString(), item.text, isSel, _col, index);
      if (v != null) return makeText(v, null, isSel);
    }
    if (item.text != null) {
      return isSel && picker!.selectedTextStyle != null
          ? Center(
              child: DefaultTextStyle(
                  style: picker!.selectedTextStyle!,
                  textAlign: picker!.textAlign,
                  child: picker!.selectedIconTheme != null
                      ? IconTheme(
                          data: picker!.selectedIconTheme!,
                          child: item.text!,
                        )
                      : item.text!),
            )
          : Center(
              child: DefaultTextStyle(
                style: picker!.textStyle ??
                    TextStyle(
                      color: theme.brightness == Brightness.dark
                          ? material.Colors.white
                          : material.Colors.black87,
                      fontFamily: theme.textTheme.titleLarge?.fontFamily,
                      fontSize: Picker.defaultTextSize,
                    ),
                textAlign: picker!.textAlign,
                child: picker!.selectedIconTheme != null
                    ? IconTheme(
                        data: picker!.selectedIconTheme!,
                        child: item.text!,
                      )
                    : item.text!,
              ),
            );
    }
    return makeText(
        item.text, item.text != null ? null : item.value.toString(), isSel);
  }

  @override
  void initSelects() {
    // ignore: unnecessary_null_comparison
    if (picker!.selecteds == null) picker!.selecteds = <int>[];
    if (picker!.selecteds.isEmpty) {
      for (int i = 0; i < _maxLevel; i++) {
        picker!.selecteds.add(0);
      }
    }
  }

  @override
  List<T> getSelectedValues() {
    List<T> items = [];
    var sLen = picker!.selecteds.length;
    if (isArray) {
      for (int i = 0; i < sLen; i++) {
        int j = picker!.selecteds[i];
        if (j < 0 ||
            data[i].children == null ||
            j >= data[i].children!.length) {
          break;
        }
        T val = data[i].children![j].value as T;
        if (val != null) {
          items.add(val);
        }
      }
    } else {
      List<PickerItem<dynamic>>? datas = data;
      for (int i = 0; i < sLen; i++) {
        int j = picker!.selecteds[i];
        if (j < 0 || j >= datas!.length) break;
        items.add(datas[j].value);
        datas = datas[j].children;
        if (datas == null || datas.isEmpty) break;
      }
    }
    return items;
  }

  void _checkPickerDataLevel(List<PickerItem>? data, int level) {
    if (data == null) return;
    if (isArray) {
      _maxLevel = data.length;
      return;
    }
    for (int i = 0; i < data.length; i++) {
      if (data[i].children != null && data[i].children!.isNotEmpty) {
        _checkPickerDataLevel(data[i].children, level + 1);
      }
    }
    if (_maxLevel < level) _maxLevel = level;
  }
}

class NumberPickerColumn {
  final List<int>? items;
  final int begin;
  final int end;
  final int? initValue;
  final int columnFlex;
  final int jump;
  final Widget? postfix, suffix;
  final PickerValueFormat<int>? onFormatValue;

  const NumberPickerColumn({
    this.begin = 0,
    this.end = 9,
    this.items,
    this.initValue,
    this.jump = 1,
    this.columnFlex = 1,
    this.postfix,
    this.suffix,
    this.onFormatValue,
  });

  int indexOf(int? value) {
    if (value == null) return -1;
    if (items != null) return items!.indexOf(value);
    if (value < begin || value > end) return -1;
    return (value - begin) ~/ (jump == 0 ? 1 : jump);
  }

  int valueOf(int index) {
    if (items != null) {
      return items![index];
    }
    return begin + index * (jump == 0 ? 1 : jump);
  }

  String getValueText(int index) {
    return onFormatValue == null
        ? "${valueOf(index)}"
        : onFormatValue!(valueOf(index));
  }

  int count() {
    var v = (end - begin) ~/ (jump == 0 ? 1 : jump) + 1;
    if (v < 1) return 0;
    return v;
  }
}

class NumberPickerAdapter extends PickerAdapter<int> {
  NumberPickerAdapter({required this.data});

  final List<NumberPickerColumn> data;
  NumberPickerColumn? cur;
  int _col = 0;

  @override
  int getLength() {
    if (cur == null) return 0;
    if (cur!.items != null) return cur!.items!.length;
    return cur!.count();
  }

  @override
  int getMaxLevel() => data.length;

  @override
  bool getIsLinkage() {
    return false;
  }

  @override
  void setColumn(int index) {
    if (index != -1 && _col == index + 1) return;
    _col = index + 1;
    if (_col >= data.length) {
      cur = null;
    } else {
      cur = data[_col];
    }
  }

  @override
  void initSelects() {
    int maxLevel = getMaxLevel();
    // ignore: unnecessary_null_comparison
    if (picker!.selecteds == null) picker!.selecteds = <int>[];
    if (picker!.selecteds.isEmpty) {
      for (int i = 0; i < maxLevel; i++) {
        int v = data[i].indexOf(data[i].initValue);
        if (v < 0) v = 0;
        picker!.selecteds.add(v);
      }
    }
  }

  @override
  Widget buildItem(BuildContext context, int index) {
    final txt = cur!.getValueText(index);
    final isSel = index == picker!.selecteds[_col];
    if (picker!.onBuilderItem != null) {
      final v = picker!.onBuilderItem!(context, txt, null, isSel, _col, index);
      if (v != null) return makeText(v, null, isSel);
    }
    if (cur!.postfix == null && cur!.suffix == null) {
      return makeText(null, txt, isSel);
    } else {
      return makeTextEx(null, txt, cur!.postfix, cur!.suffix, isSel);
    }
  }

  @override
  int getColumnFlex(int column) {
    return data[column].columnFlex;
  }

  @override
  List<int> getSelectedValues() {
    List<int> items = [];
    for (int i = 0; i < picker!.selecteds.length; i++) {
      int j = picker!.selecteds[i];
      int v = data[i].valueOf(j);
      items.add(v);
    }
    return items;
  }
}

/// Picker DateTime Adapter Type
class PickerDateTimeType {
  static const int kMDY = 0; // m, d, y
  static const int kHM = 1; // hh, mm
  static const int kHMS = 2; // hh, mm, ss
  // ignore: constant_identifier_names
  static const int kHM_AP = 3; // hh, mm, ap(AM/PM)
  static const int kMDYHM = 4; // m, d, y, hh, mm
  // ignore: constant_identifier_names
  static const int kMDYHM_AP = 5; // m, d, y, hh, mm, AM/PM
  static const int kMDYHMS = 6; // m, d, y, hh, mm, ss

  static const int kYMD = 7; // y, m, d
  static const int kYMDHM = 8; // y, m, d, hh, mm
  static const int kYMDHMS = 9; // y, m, d, hh, mm, ss
  // ignore: constant_identifier_names
  static const int kYMD_AP_HM = 10; // y, m, d, ap, hh, mm

  static const int kYM = 11; // y, m
  static const int kDMY = 12; // d, m, y
  static const int kY = 13; // y
}

class DateTimePickerAdapter extends PickerAdapter<DateTime> {
  /// display type, ref: [columnType]
  final int type;

  /// Whether to display the month in numerical form.If true, months is not used.
  final bool isNumberMonth;

  /// custom months strings
  final List<String>? months;

  /// Custom AM, PM strings
  final List<String>? strAMPM;

  /// year begin...end.
  final int? yearBegin, yearEnd;

  /// hour min ... max, min >= 0, max <= 23, max > min
  final int? minHour, maxHour;

  /// minimum datetime
  final DateTime? minValue, maxValue;

  /// jump minutes, user could select time in intervals of 30min, 5mins, etc....
  final int? minuteInterval;

  /// Year, month, day suffix
  final String? yearSuffix,
      monthSuffix,
      daySuffix,
      hourSuffix,
      minuteSuffix,
      secondSuffix;

  /// use two-digit year, 2019, displayed as 19
  final bool twoDigitYear;

  /// year 0, month 1, day 2, hour 3, minute 4, sec 5, am/pm 6, hour-ap: 7
  final List<int>? customColumnType;

  static const List<String> monthsListEN = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];

  static const List<String> monthsListENL = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  DateTimePickerAdapter({
    Picker? picker,
    this.type = 0,
    this.isNumberMonth = false,
    this.months = monthsListEN,
    this.strAMPM,
    this.yearBegin = 1900,
    this.yearEnd = 2100,
    this.value,
    this.minValue,
    this.maxValue,
    this.minHour,
    this.maxHour,
    this.secondSuffix,
    this.minuteSuffix,
    this.hourSuffix,
    this.yearSuffix,
    this.monthSuffix,
    this.daySuffix,
    this.minuteInterval,
    this.customColumnType,
    this.twoDigitYear = false,
  }) : assert(minuteInterval == null ||
            (minuteInterval >= 1 &&
                minuteInterval <= 30 &&
                (60 % minuteInterval == 0))) {
    super.picker = picker;
    _yearBegin = yearBegin ?? 0;
    if (minValue != null && minValue!.year > _yearBegin) {
      _yearBegin = minValue!.year;
    }
    // Judge whether the day is in front of the month
    // If in the front, set "needUpdatePrev" = true
    List<int> colType;
    if (customColumnType != null) {
      colType = customColumnType!;
    } else {
      colType = columnType[type];
    }
    var month = colType.indexWhere((element) => element == 1);
    var day = colType.indexWhere((element) => element == 2);
    _needUpdatePrev =
        day < month || day < colType.indexWhere((element) => element == 0);
    if (!_needUpdatePrev) {
      // check am/pm before hour-ap
      var ap = colType.indexWhere((element) => element == 6);
      if (ap > colType.indexWhere((element) => element == 7)) {
        _apBeforeHourAp = true;
        _needUpdatePrev = true;
      }
    }
    value ??= DateTime.now();
    _existSec = existSec();
    _verificationMinMaxValue();
  }

  bool _existSec = false;
  int _col = 0;
  int _colAP = -1;
  int _colHour = -1;
  int _colDay = -1;
  int _yearBegin = 0;
  bool _needUpdatePrev = false;
  bool _apBeforeHourAp = false;

  /// Currently selected value
  DateTime? value;

  // but it can improve the performance, so keep it.
  static const List<List<int>> lengths = [
    [12, 31, 0],
    [24, 60],
    [24, 60, 60],
    [12, 60, 2],
    [12, 31, 0, 24, 60],
    [12, 31, 0, 12, 60, 2],
    [12, 31, 0, 24, 60, 60],
    [0, 12, 31],
    [0, 12, 31, 24, 60],
    [0, 12, 31, 24, 60, 60],
    [0, 12, 31, 2, 12, 60],
    [0, 12],
    [31, 12, 0],
    [0],
  ];

  static const Map<int, int> columnTypeLength = {
    0: 0,
    1: 12,
    2: 31,
    3: 24,
    4: 60,
    5: 60,
    6: 2,
    7: 12
  };

  /// year 0, month 1, day 2, hour 3, minute 4, sec 5, am/pm 6, hour-ap: 7
  static const List<List<int>> columnType = [
    [1, 2, 0],
    [3, 4],
    [3, 4, 5],
    [7, 4, 6],
    [1, 2, 0, 3, 4],
    [1, 2, 0, 7, 4, 6],
    [1, 2, 0, 3, 4, 5],
    [0, 1, 2],
    [0, 1, 2, 3, 4],
    [0, 1, 2, 3, 4, 5],
    [0, 1, 2, 6, 7, 4],
    [0, 1],
    [2, 1, 0],
    [0],
  ];

  // static const List<int> leapYearMonths = const <int>[1, 3, 5, 7, 8, 10, 12];

  // Get the type of current column
  int getColumnType(int index) {
    if (customColumnType != null) return customColumnType![index];
    List<int> items = columnType[type];
    if (index >= items.length) return -1;
    return items[index];
  }

  // Check if seconds exist
  bool existSec() {
    final columns =
        customColumnType == null ? columnType[type] : customColumnType!;
    return columns.contains(5);
  }

  @override
  int getLength() {
    int v = (customColumnType == null
        ? lengths[type][_col]
        : columnTypeLength[customColumnType![_col]])!;
    if (v == 0) {
      int ye = yearEnd!;
      if (maxValue != null) ye = maxValue!.year;
      return ye - _yearBegin + 1;
    }
    if (v == 31) return _calcDateCount(value!.year, value!.month);
    int columnType = getColumnType(_col);
    switch (columnType) {
      case 3: // hour
        if ((minHour != null && minHour! >= 0) ||
            (maxHour != null && maxHour! <= 23)) {
          return (maxHour ?? 23) - (minHour ?? 0) + 1;
        }
        break;
      case 4: // minute
        if (minuteInterval != null && minuteInterval! > 1) {
          return v ~/ minuteInterval!;
        }
        break;
      case 7: // hour am/pm
        if ((minHour != null && minHour! >= 0) ||
            (maxHour != null && maxHour! <= 23)) {
          if (_colAP < 0) {
            // I don't know AM or PM
            return 12;
          } else {
            var min = 0;
            var max = 0;
            if (picker!.selecteds[_colAP] == 0) {
              // am
              min = minHour == null
                  ? 1
                  : minHour! >= 12
                      ? 12
                      : minHour! + 1;
              max = maxHour == null
                  ? 12
                  : maxHour! >= 12
                      ? 12
                      : maxHour! + 1;
            } else {
              // pm
              min = minHour == null
                  ? 1
                  : minHour! >= 12
                      ? 24 - minHour! - 12
                      : 1;
              max = maxHour == null
                  ? 12
                  : maxHour! >= 12
                      ? maxHour! - 12
                      : 1;
            }
            return max > min ? max - min + 1 : min - max + 1;
          }
        }
    }
    return v;
  }

  @override
  int getMaxLevel() {
    return customColumnType == null
        ? lengths[type].length
        : customColumnType!.length;
  }

  @override
  bool needUpdatePrev(int curIndex) {
    if (_needUpdatePrev) {
      if (value?.month == 2) {
        // Only February needs to be dealt with
        var curentColumnType = getColumnType(curIndex);
        return curentColumnType == 1 || curentColumnType == 0;
      } else if (_apBeforeHourAp) {
        return getColumnType(curIndex) == 6;
      }
    }
    return false;
  }

  @override
  void setColumn(int index) {
    //print("setColumn index: $index");
    _col = index + 1;
    if (_col < 0) _col = 0;
  }

  @override
  void initSelects() {
    _colAP = _getAPColIndex();
    int maxLevel = getMaxLevel();
    // ignore: unnecessary_null_comparison
    if (picker!.selecteds == null) picker!.selecteds = <int>[];
    if (picker!.selecteds.isEmpty) {
      for (int i = 0; i < maxLevel; i++) {
        picker!.selecteds.add(0);
      }
    }
  }

  @override
  Widget buildItem(BuildContext context, int index) {
    String text = "";
    int colType = getColumnType(_col);
    switch (colType) {
      case 0:
        if (twoDigitYear) {
          text = "${_yearBegin + index}";
          var txtLength = text.length;
          text =
              "${text.substring(txtLength - (txtLength - 2), txtLength)}${_checkStr(yearSuffix)}";
        } else {
          text = "${_yearBegin + index}${_checkStr(yearSuffix)}";
        }
        break;
      case 1:
        if (isNumberMonth) {
          text = "${index + 1}${_checkStr(monthSuffix)}";
        } else {
          if (months != null) {
            text = months![index];
          } else {
            List months =
                PickerLocalizations.of(context).months ?? monthsListEN;
            text = "${months[index]}";
          }
        }
        break;
      case 2:
        text = "${index + 1}${_checkStr(daySuffix)}";
        break;
      case 3:
        text = "${intToStr(index + (minHour ?? 0))}${_checkStr(hourSuffix)}";
        break;
      case 5:
        text = "${intToStr(index)}${_checkStr(secondSuffix)}";
        break;
      case 4:
        if (minuteInterval == null || minuteInterval! < 2) {
          text = "${intToStr(index)}${_checkStr(minuteSuffix)}";
        } else {
          text =
              "${intToStr(index * minuteInterval!)}${_checkStr(minuteSuffix)}";
        }
        break;
      case 6:
        final apStr = strAMPM ??
            PickerLocalizations.of(context).ampm ??
            const ['AM', 'PM'];
        text = "${apStr[index]}";
        break;
      case 7:
        text = intToStr(index +
            (minHour == null
                ? 0
                : (picker!.selecteds[_colAP] == 0 ? minHour! : 0)) +
            1);
        break;
    }

    final isSel = picker!.selecteds[_col] == index;
    if (picker!.onBuilderItem != null) {
      var v = picker!.onBuilderItem!(context, text, null, isSel, _col, index);
      if (v != null) return makeText(v, null, isSel);
    }
    return makeText(null, text, isSel);
  }

  @override
  String getText() {
    return value.toString();
  }

  @override
  int getColumnFlex(int column) {
    if (picker!.columnFlex != null && column < picker!.columnFlex!.length) {
      return picker!.columnFlex![column];
    }
    if (getColumnType(column) == 0) return 3;
    return 2;
  }

  @override
  void doShow() {
    if (_yearBegin == 0) getLength();
    var maxLevel = getMaxLevel();
    final sh = value!.hour;
    for (int i = 0; i < maxLevel; i++) {
      int colType = getColumnType(i);
      switch (colType) {
        case 0:
          picker!.selecteds[i] = yearEnd != null && value!.year > yearEnd!
              ? yearEnd! - _yearBegin
              : value!.year - _yearBegin;
          break;
        case 1:
          picker!.selecteds[i] = value!.month - 1;
          break;
        case 2:
          picker!.selecteds[i] = value!.day - 1;
          break;
        case 3:
          var h = sh;
          if ((minHour != null && minHour! >= 0) ||
              (maxHour != null && maxHour! <= 23)) {
            if (minHour != null) {
              h = h > minHour! ? h - minHour! : 0;
            } else {
              h = (maxHour ?? 23) - (minHour ?? 0) + 1;
            }
          }
          picker!.selecteds[i] = h;
          break;
        case 4:
          // minute
          if (minuteInterval == null || minuteInterval! < 2) {
            picker!.selecteds[i] = value!.minute;
          } else {
            picker!.selecteds[i] = value!.minute ~/ minuteInterval!;
            final m = picker!.selecteds[i] * minuteInterval!;
            if (m != value!.minute) {
              // Need to update value
              var s = value!.second;
              if (type != 2 && type != 6) s = 0;
              final h = _colAP >= 0 ? _calcHourOfAMPM(sh, m) : sh;
              value = DateTime(value!.year, value!.month, value!.day, h, m, s);
            }
          }
          break;
        case 5:
          picker!.selecteds[i] = value!.second;
          break;
        case 6:
          // am/pm
          picker!.selecteds[i] = (sh > 12 ||
                  (sh == 12 && (value!.minute > 0 || value!.second > 0)))
              ? 1
              : 0;
          break;
        case 7:
          picker!.selecteds[i] = sh == 0
              ? 11
              : (sh > 12)
                  ? sh - 12 - 1
                  : sh - 1;
          break;
      }
    }
  }

  @override
  void doSelect(int column, int index) {
    int year, month, day, h, m, s;
    year = value!.year;
    month = value!.month;
    day = value!.day;
    h = value!.hour;
    m = value!.minute;
    s = _existSec ? value!.second : 0;

    int colType = getColumnType(column);
    switch (colType) {
      case 0:
        year = _yearBegin + index;
        break;
      case 1:
        month = index + 1;
        break;
      case 2:
        day = index + 1;
        break;
      case 3:
        h = index + (minHour ?? 0);
        break;
      case 4:
        m = (minuteInterval == null || minuteInterval! < 2)
            ? index
            : index * minuteInterval!;
        if (_colAP >= 0) {
          h = _calcHourOfAMPM(h, m);
        }
        break;
      case 5:
        s = index;
        break;
      case 6:
        h = _calcHourOfAMPM(h, m);
        if (minHour != null || maxHour != null) {
          if (minHour != null && _colHour >= 0) {
            if (h < minHour!) {
              picker!.selecteds[_colHour] = 0;
              picker!.updateColumn(_colHour);
              return;
            }
          }
          if (maxHour != null && h > maxHour!) h = maxHour!;
        }
        break;
      case 7:
        h = index +
            (minHour == null
                ? 0
                : (picker!.selecteds[_colAP] == 0 ? minHour! : 0)) +
            1;
        if (_colAP >= 0) {
          h = _calcHourOfAMPM(h, m);
        }
        if (h > 23) h = 0;
        break;
    }
    int dayCount = _calcDateCount(year, month);

    bool isChangeDay = false;
    if (day > dayCount) {
      day = dayCount;
      isChangeDay = true;
    }
    value = DateTime(year, month, day, h, m, s);

    if (_verificationMinMaxValue()) {
      notifyDataChanged();
    } else if (isChangeDay && _colDay >= 0) {
      doShow();
      picker!.updateColumn(_colDay);
    }
  }

  bool _verificationMinMaxValue() {
    DateTime? minV = minValue;
    DateTime? maxV = maxValue;
    if (minV == null && yearBegin != null) {
      minV = DateTime(yearBegin!, 1, 1, minHour ?? 0);
    }
    if (maxV == null && yearEnd != null) {
      maxV = DateTime(yearEnd!, 12, 31, maxHour ?? 23, 59, 59);
    }
    if (minV != null &&
        (value!.millisecondsSinceEpoch < minV.millisecondsSinceEpoch)) {
      value = minV;
      return true;
    } else if (maxV != null &&
        value!.millisecondsSinceEpoch > maxV.millisecondsSinceEpoch) {
      value = maxV;
      return true;
    }
    return false;
  }

  // Calculate am/pm time transfer
  int _calcHourOfAMPM(int h, int m) {
    // 12:00 AM , 00:00:000
    // 12:30 AM , 12:30:000
    // 12:00 PM , 12:00:000
    // 12:30 PM , 00:30:000
    if (picker!.selecteds[_colAP] == 0) {
      // am
      if (h == 12 && m == 0) {
        h = 0;
      } else if (h == 0 && m > 0) {
        h = 12;
      }
      if (h > 12) h = h - 12;
    } else {
      // pm
      if (h > 0 && h < 12) h = h + 12;
      if (h == 12 && m > 0) {
        h = 0;
      } else if (h == 0 && m == 0) {
        h = 12;
      }
    }
    return h;
  }

  int _getAPColIndex() {
    List<int> items = customColumnType ?? columnType[type];
    _colHour = items.indexWhere((e) => e == 7);
    _colDay = items.indexWhere((e) => e == 2);
    for (int i = 0; i < items.length; i++) {
      if (items[i] == 6) return i;
    }
    return -1;
  }

  int _calcDateCount(int year, int month) {
    switch (month) {
      case 1:
      case 3:
      case 5:
      case 7:
      case 8:
      case 10:
      case 12:
        return 31;
      case 2:
        {
          if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
            return 29;
          }
          return 28;
        }
    }
    return 30;
  }

  String intToStr(int v) {
    return (v < 10) ? "0$v" : "$v";
  }

  String _checkStr(String? v) {
    return v ?? "";
  }
}
