import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

enum SilkFieldSort { none, asc, desc }

enum _SilkGridDataLoadType { local, remote }

typedef FormatFieldText = String Function(int row, int col, SilkGridColumns columns, Map<String, dynamic> record);
typedef BuildCustomWidget = Widget Function(int row, int col, SilkGridColumns columns, Map<String, dynamic> record, TextStyle style);
typedef RowColor = Color? Function(int row, Map<String, dynamic> record);
typedef GridMouseEvent = Function(int row, int col, Map<String, dynamic> record, TapDownDetails details);
typedef ChangeRowEvent = Function(int row, int col, Map<String, dynamic> record);
typedef SelectionChanged = Function(List<int> selectedRows);

///
typedef LoadRows = Future<(List<dynamic>, int)> Function(int offset, int pageSize, SilkGridSortInfo? sortInfo);

class SilkGridSortInfo {
  final String field;
  final SilkFieldSort sort;

  SilkGridSortInfo({
    required this.field,
    required this.sort,
  });

  Map<String, dynamic> asMap() {
    return sort == SilkFieldSort.none
        ? {}
        : {
            "field": field,
            "sort": sort == SilkFieldSort.asc ? "asc" : "desc",
          };
  }
}

/// Field types
abstract class SilkGridField {
  final String label;
  final String field;
  final double? size;
  double minSize;
  final bool hidden;
  final bool sortable;
  final bool resizable;
  final Widget? render;
  final FormatFieldText? formatText;
  final BuildCustomWidget? cellBuilder;
  final Locale? locale;

  double _internalSize = 0;

  SilkGridField({
    required this.label,
    required this.field,
    this.size,
    this.minSize = 20,
    this.hidden = false,
    this.sortable = true,
    this.resizable = true,
    this.render,
    this.formatText,
    this.cellBuilder,
    this.locale,
  }) {
    if (size != null) {
      _internalSize = size!;
      minSize = size!;
    }
  }

  double get internalSize {
    return _internalSize;
  }

  String formatValue(dynamic value) {
    return "XXX $value";
  }

  Alignment get alignment {
    return Alignment.centerLeft;
  }

  SilkGridField copyWith({
    String? label,
    String? field,
    double? size,
    double? minSize,
    bool? hidden,
    bool? sortable,
    bool? resizable,
    Widget? render,
    FormatFieldText? formatText,
    BuildCustomWidget? cellBuilder,
    Locale? locale,
  });
}

class SilkGridStringField extends SilkGridField {
  SilkGridStringField({
    required super.label,
    required super.field,
    super.size,
    super.minSize = 20,
    super.hidden = false,
    super.sortable = true,
    super.resizable = true,
    super.render,
    super.formatText,
    super.cellBuilder,
    super.locale,
  });
  @override
  String formatValue(dynamic value) {
    if (value == null) return "";
    return "$value".replaceAll("\n", "");
  }

  @override
  SilkGridField copyWith({
    String? label,
    String? field,
    double? size,
    double? minSize,
    bool? hidden,
    bool? sortable,
    bool? resizable,
    Widget? render,
    FormatFieldText? formatText,
    BuildCustomWidget? cellBuilder,
    Locale? locale,
  }) {
    return SilkGridStringField(
      label: label ?? this.label,
      field: field ?? this.field,
      size: size ?? this.size,
      minSize: minSize ?? this.minSize,
      hidden: hidden ?? this.hidden,
      sortable: sortable ?? this.sortable,
      resizable: resizable ?? this.resizable,
      render: render ?? this.render,
      formatText: formatText ?? this.formatText,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      locale: locale ?? this.locale,
    );
  }
}

class SilkGridIntField extends SilkGridField {
  SilkGridIntField({
    required super.label,
    required super.field,
    super.size,
    super.minSize = 20,
    super.hidden = false,
    super.sortable = true,
    super.resizable = true,
    super.render,
    super.formatText,
    super.cellBuilder,
    super.locale,
  });
  @override
  String formatValue(dynamic value) {
    if (value == null) return "";
    if (locale == null) {
      return (value as int).toStringAsFixed(0);
    } else {
      return NumberFormat.decimalPattern(locale!.languageCode).format(value as int);
    }
  }

  @override
  Alignment get alignment {
    return Alignment.centerRight;
  }

  @override
  SilkGridField copyWith({
    String? label,
    String? field,
    double? size,
    double? minSize,
    bool? hidden,
    bool? sortable,
    bool? resizable,
    Widget? render,
    FormatFieldText? formatText,
    BuildCustomWidget? cellBuilder,
    Locale? locale,
  }) {
    return SilkGridIntField(
      label: label ?? this.label,
      field: field ?? this.field,
      size: size ?? this.size,
      minSize: minSize ?? this.minSize,
      hidden: hidden ?? this.hidden,
      sortable: sortable ?? this.sortable,
      resizable: resizable ?? this.resizable,
      render: render ?? this.render,
      formatText: formatText ?? this.formatText,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      locale: locale ?? this.locale,
    );
  }
}

class SilkGridDoubleField extends SilkGridField {
  final int precision;
  SilkGridDoubleField({
    required super.label,
    required super.field,
    this.precision = 3,
    super.size,
    super.minSize = 20,
    super.hidden = false,
    super.sortable = true,
    super.resizable = true,
    super.render,
    super.formatText,
    super.cellBuilder,
    super.locale,
  });
  @override
  String formatValue(dynamic value) {
    if (value == null) return "-";
    if (locale == null) {
      return (value as double).toStringAsFixed(precision);
    } else {
      return NumberFormat.decimalPatternDigits(locale: locale!.languageCode, decimalDigits: precision).format(value as double);
    }
  }

  @override
  Alignment get alignment {
    return Alignment.centerRight;
  }

  @override
  SilkGridField copyWith({
    String? label,
    String? field,
    int? precision,
    double? size,
    double? minSize,
    bool? hidden,
    bool? sortable,
    bool? resizable,
    Widget? render,
    FormatFieldText? formatText,
    BuildCustomWidget? cellBuilder,
    Locale? locale,
  }) {
    return SilkGridDoubleField(
      label: label ?? this.label,
      field: field ?? this.field,
      precision: precision ?? this.precision,
      size: size ?? this.size,
      minSize: minSize ?? this.minSize,
      hidden: hidden ?? this.hidden,
      sortable: sortable ?? this.sortable,
      resizable: resizable ?? this.resizable,
      render: render ?? this.render,
      formatText: formatText ?? this.formatText,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      locale: locale ?? this.locale,
    );
  }
}

class SilkGridMoneyField extends SilkGridField {
  SilkGridMoneyField({
    required super.label,
    required super.field,
    super.size,
    super.minSize = 20,
    super.hidden = false,
    super.sortable = true,
    super.resizable = true,
    super.render,
    super.formatText,
    super.cellBuilder,
    super.locale,
  });
  @override
  String formatValue(dynamic value) {
    if (value == null) return "-";
    if (locale == null) {
      return (value as double).toStringAsFixed(2);
    } else {
      return NumberFormat.simpleCurrency(locale: locale!.languageCode).format(value as double);
    }
  }

  @override
  Alignment get alignment {
    return Alignment.centerRight;
  }

  @override
  SilkGridField copyWith({
    String? label,
    String? field,
    double? size,
    double? minSize,
    bool? hidden,
    bool? sortable,
    bool? resizable,
    Widget? render,
    FormatFieldText? formatText,
    BuildCustomWidget? cellBuilder,
    Locale? locale,
  }) {
    return SilkGridMoneyField(
      label: label ?? this.label,
      field: field ?? this.field,
      size: size ?? this.size,
      minSize: minSize ?? this.minSize,
      hidden: hidden ?? this.hidden,
      sortable: sortable ?? this.sortable,
      resizable: resizable ?? this.resizable,
      render: render ?? this.render,
      formatText: formatText ?? this.formatText,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      locale: locale ?? this.locale,
    );
  }
}

class SilkGridDateField extends SilkGridField {
  SilkGridDateField({
    required super.label,
    required super.field,
    super.size,
    super.minSize = 20,
    super.hidden = false,
    super.sortable = true,
    super.resizable = true,
    super.render,
    super.formatText,
    super.cellBuilder,
    super.locale,
  });

  @override
  String formatValue(dynamic value) {
    if (value == null) return "-";
    if (value is String) {
      if (locale != null) {
        DateTime dt = DateTime.parse(value);
        DateFormat f = DateFormat.yMd(locale!.languageCode);
        return f.format(dt.toLocal());
      } else {
        return value.toString();
      }
    } else {
      return value.toString();
    }
  }

  @override
  Alignment get alignment {
    return Alignment.centerRight;
  }

  @override
  SilkGridField copyWith({
    String? label,
    String? field,
    double? size,
    double? minSize,
    bool? hidden,
    bool? sortable,
    bool? resizable,
    Widget? render,
    FormatFieldText? formatText,
    BuildCustomWidget? cellBuilder,
    Locale? locale,
  }) {
    return SilkGridDateField(
      label: label ?? this.label,
      field: field ?? this.field,
      size: size ?? this.size,
      minSize: minSize ?? this.minSize,
      hidden: hidden ?? this.hidden,
      sortable: sortable ?? this.sortable,
      resizable: resizable ?? this.resizable,
      render: render ?? this.render,
      formatText: formatText ?? this.formatText,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      locale: locale ?? this.locale,
    );
  }
}

class SilkGridDateTimeField extends SilkGridField {
  SilkGridDateTimeField({
    required super.label,
    required super.field,
    super.size,
    super.minSize = 20,
    super.hidden = false,
    super.sortable = true,
    super.resizable = true,
    super.render,
    super.formatText,
    super.cellBuilder,
    super.locale,
  });
  @override
  String formatValue(dynamic value) {
    if (value == null) return "-";
    if (value is String) {
      if (locale != null) {
        DateTime dt = DateTime.parse(value);
        DateFormat f = DateFormat.yMd(locale!.languageCode);
        return "${DateFormat.yMd(locale!.languageCode).format(dt.toLocal())} ${DateFormat.Hms(locale!.languageCode).format(dt.toLocal())}";
      } else {
        return value.toString();
      }
    } else {
      return value.toString();
    }
  }

  @override
  Alignment get alignment {
    return Alignment.centerRight;
  }

  @override
  SilkGridField copyWith({
    String? label,
    String? field,
    double? size,
    double? minSize,
    bool? hidden,
    bool? sortable,
    bool? resizable,
    Widget? render,
    FormatFieldText? formatText,
    BuildCustomWidget? cellBuilder,
    Locale? locale,
  }) {
    return SilkGridDateTimeField(
      label: label ?? this.label,
      field: field ?? this.field,
      size: size ?? this.size,
      minSize: minSize ?? this.minSize,
      hidden: hidden ?? this.hidden,
      sortable: sortable ?? this.sortable,
      resizable: resizable ?? this.resizable,
      render: render ?? this.render,
      formatText: formatText ?? this.formatText,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      locale: locale ?? this.locale,
    );
  }
}

class SilkGridTimeField extends SilkGridField {
  SilkGridTimeField({
    required super.label,
    required super.field,
    super.size,
    super.minSize = 20,
    super.hidden = false,
    super.sortable = true,
    super.resizable = true,
    super.render,
    super.formatText,
    super.cellBuilder,
    super.locale,
  });
  @override
  String formatValue(dynamic value) {
    if (value == null) return "-";
    if (value is String) {
      if (locale != null) {
        DateTime dt = DateTime.parse(value);
        DateFormat f = DateFormat.yMd(locale!.languageCode);
        return DateFormat.Hms(locale!.languageCode).format(dt.toLocal());
      } else {
        return value.toString();
      }
    } else {
      return value.toString();
    }
  }

  @override
  Alignment get alignment {
    return Alignment.centerRight;
  }

  @override
  SilkGridField copyWith({
    String? label,
    String? field,
    double? size,
    double? minSize,
    bool? hidden,
    bool? sortable,
    bool? resizable,
    Widget? render,
    FormatFieldText? formatText,
    BuildCustomWidget? cellBuilder,
    Locale? locale,
  }) {
    return SilkGridTimeField(
      label: label ?? this.label,
      field: field ?? this.field,
      size: size ?? this.size,
      minSize: minSize ?? this.minSize,
      hidden: hidden ?? this.hidden,
      sortable: sortable ?? this.sortable,
      resizable: resizable ?? this.resizable,
      render: render ?? this.render,
      formatText: formatText ?? this.formatText,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      locale: locale ?? this.locale,
    );
  }
}

class SilkGridBoolField extends SilkGridField {
  SilkGridBoolField({
    required super.label,
    required super.field,
    super.size,
    super.minSize = 20,
    super.hidden = false,
    super.sortable = true,
    super.resizable = true,
    super.render,
    super.formatText,
    super.cellBuilder,
    super.locale,
  });
  @override
  String formatValue(dynamic value) {
    return "bool $value";
  }

  @override
  Alignment get alignment {
    return Alignment.center;
  }

  @override
  SilkGridField copyWith({
    String? label,
    String? field,
    double? size,
    double? minSize,
    bool? hidden,
    bool? sortable,
    bool? resizable,
    Widget? render,
    FormatFieldText? formatText,
    BuildCustomWidget? cellBuilder,
    Locale? locale,
  }) {
    return SilkGridBoolField(
      label: label ?? this.label,
      field: field ?? this.field,
      size: size ?? this.size,
      minSize: minSize ?? this.minSize,
      hidden: hidden ?? this.hidden,
      sortable: sortable ?? this.sortable,
      resizable: resizable ?? this.resizable,
      render: render ?? this.render,
      formatText: formatText ?? this.formatText,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      locale: locale ?? this.locale,
    );
  }
}

///
class SilkGridColumns {
  final List<SilkGridField> listFields = [];
  final Locale? locale;
  int _visibleColumnCount = 0;

  SilkGridColumns({
    List<SilkGridField>? items,
    this.locale,
  }) {
    if (items != null) {
      for (SilkGridField itm in items) {
        if (!itm.hidden) _visibleColumnCount++;
        listFields.add(itm.copyWith(locale: locale));
      }
    }
  }

  int get length => listFields.length;

  int get visibleCount {
    return _visibleColumnCount;
  }

  SilkGridField operator [](int index) => listFields[index];

  List<SilkGridField> get visibleColumns {
    List<SilkGridField> result = [];
    for (SilkGridField itm in listFields) {
      if (!itm.hidden) result.add(itm);
    }
    return result;
  }

  SilkGridColumns copyWith({List<SilkGridField>? items, Locale? locale}) {
    return SilkGridColumns(
      items: items ?? listFields,
      locale: locale ?? this.locale,
    );
  }
}

abstract class _SilkGridFooterRowValue {
  final dynamic value;
  final TextStyle? textStyle;
  List<int> _fields = [];
  _SilkGridFooterRowValue({
    required this.value,
    this.textStyle,
  });

  @override
  String toString() {
    return "(class: $runtimeType, value: $value, _fields: $_fields) ";
  }
}

class SilkGridFooterFieldRowValue extends _SilkGridFooterRowValue {
  final String field;
  SilkGridFooterFieldRowValue({
    required this.field,
    required super.value,
    super.textStyle,
  });
  @override
  String toString() {
    return "(class: $runtimeType, field: $field, value: $value, _fields: $_fields)";
  }
}

class SilkGridFooterTextRowValue extends _SilkGridFooterRowValue {
  SilkGridFooterTextRowValue({
    required super.value,
    super.textStyle,
  });
}

class _SilkGridFooterJoinedTextRowValue extends _SilkGridFooterRowValue {
  final int columnsCount;
  _SilkGridFooterJoinedTextRowValue({
    required super.value,
    required this.columnsCount,
  });
  @override
  String toString() {
    return "(class: $runtimeType, columnCount: $columnsCount, value: $value, _fields: $_fields)";
  }
}

class SilkGridFooterRow {
  // ignore: library_private_types_in_public_api
  final List<_SilkGridFooterRowValue> values;
  SilkGridFooterRow({
    required this.values,
  });
}

class _SilkGridFooter extends StatefulWidget {
  final GlobalKey<_SilkGridSimpleViewState> gridKey;
  final List<SilkGridFooterRow> rows;
  // ignore: prefer_const_constructors_in_immutables
  _SilkGridFooter({
    super.key,
    required this.gridKey,
    required this.rows,
  });

  @override
  // ignore: no_logic_in_create_state
  State<_SilkGridFooter> createState() {
    return _SilkGridFooterState();
  }
}

class _SilkGridFooterState extends State<_SilkGridFooter> {
  final ScrollController _footerHorizontalController = ScrollController();
  late final List<SilkGridField> _columns;
  late final List<SilkGridFooterRow> rows;

  void _refreshGridColumsPosition() {
    widget.gridKey.currentState!._horizontalController.jumpTo(_footerHorizontalController.offset);
  }

  int _findFieldIndex(String field) {
    for (int idx = 0; idx < _columns.length; idx++) {
      if (_columns[idx].field == field) return idx;
    }
    return -1;
  }

  /// calculates for each [column] in the row its width
  double calculateColumnWidth(_SilkGridFooterRowValue column) {
    double iMin = -1;
    double iMax = -1;
    for (var col in column._fields) {
      double from;
      double to;
      (from, to) = widget.gridKey.currentState!._getColumnPosition(col + 1);
      if (iMin == -1) iMin = from;
      iMax = to;
      // print("---- $from - $to");
    }
    // print("-- $iMin - $iMax");
    return iMax - iMin;
  }

  Widget _generateRow(SilkGridFooterRow row) {
    List<Widget> result = [];
    for (_SilkGridFooterRowValue value in row.values) {
      double width = calculateColumnWidth(value);
      if (value is SilkGridFooterTextRowValue) {
        // print(" is SilkGridFooterTextRow $width");
        result.add(Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 4, right: 4),
          width: width,
          height: widget.gridKey.currentState!._rowHeight,
          child: value.value != null
              ? Text(
                  value.value.toString(),
                  style: value.textStyle ??
                      Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: widget.gridKey.currentState!._toolbarIconColor,
                            fontWeight: FontWeight.normal,
                            overflow: TextOverflow.ellipsis,
                          ),
                )
              : Container(),
        ));
      } else if (value is SilkGridFooterFieldRowValue) {
        // print(" is SilkGridFooterFieldRowValue $width");
        result.add(
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(left: 4, right: 4),
            width: width,
            height: widget.gridKey.currentState!._rowHeight,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: widget.gridKey.currentState!._borderColor),
                right: BorderSide(color: widget.gridKey.currentState!._borderColor),
              ),
            ),
            child: value.value != null
                ? Text(
                    value.value.toString(),
                    style: value.textStyle ??
                        Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: widget.gridKey.currentState!._toolbarIconColor,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                  )
                : Container(),
          ),
        );
      } else if (value is _SilkGridFooterJoinedTextRowValue) {
        List<Widget> texts = [];
        for (var element in (value.value as List)) {
          texts.add(Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: widget.gridKey.currentState!._borderColor),
                right: BorderSide(color: widget.gridKey.currentState!._borderColor),
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 4, right: 4),
            width: (width) / value.columnsCount,
            child: Text(
              element.toString(),
              style: value.textStyle ??
                  Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: widget.gridKey.currentState!._toolbarIconColor,
                        fontWeight: FontWeight.normal,
                        overflow: TextOverflow.ellipsis,
                      ),
            ),
          ));
        }
        result.add(
          SizedBox(
            width: width,
            height: widget.gridKey.currentState!._rowHeight,
            // color: myColors[i],
            child: Row(
              children: [...texts],
            ),
          ),
        );
      }
    }
    return Container(
      height: widget.gridKey.currentState!._rowHeight,
      decoration: BoxDecoration(
        color: widget.gridKey.currentState!._toolbarColor,
        border: Border(
          top: BorderSide(color: widget.gridKey.currentState!._borderColor),
        ),
        //border: Border.all(color: widget._owner._borderColor),
      ),
      child: Row(
        children: [...result],
      ),
    );
  }

  Widget _generateAllRows() {
    List<Widget> result = [];
    for (var row in rows) {
      // print("-----");
      result.add(_generateRow(row));
    }

    return Column(
      children: result,
    );
  }

  List<int> _generateList(int from, int to) {
    List<int> result = [];
    for (int j = from; j < to; j++) {
      result.add(j);
    }
    return result;
  }

  /// The method returns two parameters, the number of "user texts",
  ///  and the ID of the next "field".
  (int, int) _getNextField(int fromPos, List<_SilkGridFooterRowValue> aValues) {
    // print("----- ----- fromPos = $fromPos - length: ${aValues.length}");
    int counter = 1;
    int toPos = -1;
    for (int i = fromPos + 1; i < aValues.length; i++) {
      if (aValues[i] is SilkGridFooterFieldRowValue) {
        toPos = i;
        break;
      } else {
        counter++;
      }
    }
    if (toPos >= 0) {
      // print("----- ----- counter: $counter, toPos: $toPos,  - idx: ${_findFieldIndex((aValues[toPos] as SilkGridFooterFieldRowValue).field)} ${(aValues[toPos] as SilkGridFooterFieldRowValue).field} ");
      return (counter, _findFieldIndex((aValues[toPos] as SilkGridFooterFieldRowValue).field));
    }
    return (counter, _columns.length - 1);
  }

  /// The method optimizes the individual display fields in the row to correctly calculate
  /// the widths of the displayed elements.
  List<_SilkGridFooterRowValue> _optimizeRows(List<_SilkGridFooterRowValue> aValues) {
    List<_SilkGridFooterRowValue> result = [];

    /// Sort only fields.
    aValues.sort(
      (_SilkGridFooterRowValue a, _SilkGridFooterRowValue b) {
        if ((a is! SilkGridFooterFieldRowValue) || (b is! SilkGridFooterFieldRowValue)) return 0;
        if (_findFieldIndex(a.field) > _findFieldIndex(b.field)) return 1;
        if (_findFieldIndex(b.field) > _findFieldIndex(a.field)) return -1;
        if (_findFieldIndex(b.field) == _findFieldIndex(a.field)) return 0;
        return 0;
      },
    );

    for (int i = 0; i < aValues.length; i++) {
      _SilkGridFooterRowValue col = aValues[i];
      if (col is SilkGridFooterFieldRowValue) {
        /// it's a field, let's get the field id
        int fieldId = _findFieldIndex(col.field);
        col._fields.add(fieldId);

        /// if it is first in the sequence and not in the zero position,
        /// we have to put an empty [SilkGridFooterTextRowValue] before it to be able
        /// to correctly determine the total length
        if (result.isEmpty && fieldId > 0) {
          SilkGridFooterTextRowValue val = SilkGridFooterTextRowValue(value: null);
          val._fields = _generateList(0, fieldId);
          result.add(val);
          result.add(col);
        } else if (result.isNotEmpty && result.last is SilkGridFooterFieldRowValue && (fieldId - result.last._fields.last) > 1) {
          /// is not the first one, check if the previous one is also of type [SilkGridFooterFieldRowValue],
          /// if it is, and there is at least one column between them, add empty [SilkGridFooterFieldRowValue]
          SilkGridFooterTextRowValue val = SilkGridFooterTextRowValue(value: null);
          val._fields = _generateList(result.last._fields.last + 1, fieldId);
          result.add(val);
          result.add(col);

          if (col == aValues.last) {
            SilkGridFooterTextRowValue val = SilkGridFooterTextRowValue(value: null);
            val._fields = _generateList(fieldId + 1, _columns.length);
            result.add(val);
          }
        } else if (result.isNotEmpty && col == aValues.last) {
          result.add(col);

          /// if it is the last value and its id is not the same as the last column id,
          /// add [SilkGridFooterFieldRowValue] to the end
          SilkGridFooterTextRowValue val = SilkGridFooterTextRowValue(value: null);
          val._fields = _generateList(fieldId + 1, _columns.length);
          result.add(val);
        } else {
          result.add(col);
        }
      } else if (col is SilkGridFooterTextRowValue) {
        int numValues;
        int fieldId;
        if (result.isEmpty) {
          (numValues, fieldId) = _getNextField(i, aValues);
          if (numValues > 1) {
            List<dynamic> values = [];
            for (int j = 0; j < numValues; j++) {
              values.add(aValues[j].value);
            }
            _SilkGridFooterJoinedTextRowValue val = _SilkGridFooterJoinedTextRowValue(columnsCount: numValues, value: values);
            val._fields = _generateList(0, fieldId);
            result.add(val);
          } else {
            SilkGridFooterTextRowValue val = SilkGridFooterTextRowValue(value: col.value);
            val._fields = _generateList(0, fieldId);
            result.add(val);
          }
          i = numValues - 1;
        } else if (result.isNotEmpty) {
          (numValues, fieldId) = _getNextField(i, aValues);
          col._fields = (_generateList(result.last._fields.last + 1, fieldId + 1));
          result.add(col);
        }
      }
    }
    return result;
  }

  /// The method transfers user rows to State and optimizes them.
  List<SilkGridFooterRow> _prepareRows(List<SilkGridFooterRow> aRows) {
    List<SilkGridFooterRow> result = [];
    for (SilkGridFooterRow row in aRows) {
      result.add(SilkGridFooterRow(values: _optimizeRows(row.values)));
    }
    return result;
  }

  Future<bool> rebuild() async {
    if (!mounted) return false;

    // if there's a current frame,
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      // wait for the end of that frame.
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return false;
    }

    setState(() {});
    return true;
  }

  @override
  void initState() {
    super.initState();
    _columns = widget.gridKey.currentState!._columns.visibleColumns;
    rows = _prepareRows(widget.rows);
    // widget.gridKey.currentState!._horizontalController.addListener(_refreshColumsPosition);
    // widget._owner._footerRefresh = _refreshColuns;
    _footerHorizontalController.addListener(_refreshGridColumsPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: widget.gridKey.currentState!._inticatorWidth,
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _footerHorizontalController,
            child: _generateAllRows(),
          ),
        ),
      ],
    );
  }
}

class _SilkGridSimpleView extends StatefulWidget {
  final GlobalKey<_SilkGridFooterState> footerKey;
  final List<dynamic>? rows;
  final LoadRows? loadRows;
  final SilkGridColumns columns;
  final RowColor? onGetRowColor;
  final Locale locale;
  final ChangeRowEvent? onChangeRow;
  final SelectionChanged? selectionChanged;
  final GridMouseEvent? onRightBtnTap;
  final GridMouseEvent? onMiddleBtnTap;
  final GridMouseEvent? onBtnTap;
  final GridMouseEvent? onBtnDoubleTap;
  final bool multiselect;
  final Color? textColor;
  final Color? borderColor;
  final Color? headerColor;
  final Color? headerTextColor;
  final Color? actualRowColor;
  final Color? actualRowTextColor;
  final Color? actualColColor;
  final Color? actualColTextColor;
  final Color? toolbarColor;
  final Color? toolbarIconColor;
  final int pageSize;

  const _SilkGridSimpleView({
    super.key,
    required this.footerKey,
    this.rows,
    this.loadRows,
    required this.columns,
    this.locale = const Locale("EN-us"),
    this.onChangeRow,
    this.selectionChanged,
    this.onRightBtnTap,
    this.onMiddleBtnTap,
    this.onBtnTap,
    this.onBtnDoubleTap,
    this.multiselect = false,
    this.textColor,
    this.borderColor,
    this.headerColor,
    this.headerTextColor,
    this.actualRowColor,
    this.actualRowTextColor,
    this.actualColColor,
    this.actualColTextColor,
    this.toolbarColor,
    this.toolbarIconColor,
    this.onGetRowColor,
    this.pageSize = 200,
  }) : assert(rows != null || loadRows != null || pageSize < 10);

  @override
  State<_SilkGridSimpleView> createState() => _SilkGridSimpleViewState();
}

class _SilkGridSimpleViewState<T extends _SilkGridSimpleView> extends State<_SilkGridSimpleView> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  //
  // _InternalRefreshFooter? _footerRefresh;
  //
  late SilkGridColumns _columns;
  List<dynamic> _rowBuff = []; // Window to actual data frame
  int _rowBuffPos = 0;
  final int _rowBuffSize = 500;

  int _rowCount = -1;

  //
  bool _loadingData = false;
  //
  SilkGridSortInfo? _sort;
  _SilkGridDataLoadType _gridDataLoadType = _SilkGridDataLoadType.local;
  //
  final _rowHeight = 27.0;
  final _inticatorWidth = 24.0;
  int _actualRow = 1;
  int _actualCol = 1;
  //
  bool keyCtrl = false;
  bool keyShift = false;
  // Selection
  // ignore: prefer_final_fields
  List<int> _selectedRows = [];
  //
  late Color _borderColor;
  late Color _headerColor;
  late Color _headerTextColor;
  late Color _actualRowColor;
  late Color _actualRowTextColor;
  late Color _actualColColor;
  late Color _actualColTextColor;
  late Color _toolbarColor;
  late Color _toolbarIconColor;
  late Color _textColor;
  //
  (double, double) _getColumnPosition(int col) {
    if (col > 0 && col - 1 < _columns.visibleCount) {
      double from = 0;
      double to = _inticatorWidth;
      for (int idx = 1; idx <= col; idx++) {
        from = to;
        to += _getFieldWidth(idx);
      }
      // print("col : $col from: $from to: $to");
      return (from, to);
    }
    return (0, 0);
    // throw ("ERROR in _getColumnPosition - col out of range - $col / ${_columns.visibleCount}");
  }

  (double, double) _getRowPosition(int row) {
    double from = (row * _rowHeight);
    double to = from + _rowHeight;
    return (from, to);
  }

  void _refreshFooterColumsPosition() {
    widget.footerKey.currentState!._footerHorizontalController.jumpTo(_horizontalController.offset);
  }

  //
  Alignment _getFieldAlignment(int column) {
    return _columns.visibleColumns[column].alignment;
  }

  double _getFieldWidth(int column) {
    if (column == 0) {
      return _inticatorWidth;
    } else {
      if (_columns.visibleColumns[column - 1].size != null) {
        return _columns.visibleColumns[column - 1].size!;
      } else {
        double size = _columns.visibleColumns[column - 1]._internalSize;
        if (size < _columns.visibleColumns[column - 1].minSize) size = _columns.visibleColumns[column - 1].minSize;
        return size;
      }
    }
  }

  void _recalculateColumnsWidth(BoxConstraints constraints) {
    List<SilkGridField> autosizedCols = [];
    double fixedColsWidth = 0;
    for (int i = 0; i < _columns.length; i++) {
      if (_columns[i].size == null) {
        autosizedCols.add(_columns[i]);
      } else {
        fixedColsWidth += _columns[i].size!;
      }
    }
    if (autosizedCols.isNotEmpty) {
      double calculatedWidthRatio = 1 / autosizedCols.length;
      // double remainingSpace = (constraints.maxWidth + _inticatorWidth + (_columns.visibleCount - 1)) - fixedColsWidth;
      double remainingSpace = (constraints.maxWidth + _inticatorWidth + 12) - fixedColsWidth;
      for (SilkGridField element in autosizedCols) {
        element._internalSize = remainingSpace * calculatedWidthRatio;
      }
    }
    // Refresh footer sizes
    widget.footerKey.currentState!.rebuild();
  }

  void _changeSelectedColumn(int newColumn, {bool setCursor = true}) {
    if (newColumn > 0 && newColumn <= _columns.visibleCount) {
      double screenFrom = _horizontalController.offset;
      double screenTo = _horizontalController.position.extentInside;
      var (colFrom, colTo) = _getColumnPosition(newColumn);
      if (colTo > (screenTo + screenFrom)) {
        _horizontalController.jumpTo(screenFrom + (colTo - (screenTo + screenFrom)));
      }
      if (colFrom < screenFrom) {
        _horizontalController.jumpTo(colFrom - _inticatorWidth);
      }
      if (setCursor) {
        setState(() {
          _actualCol = newColumn;
        });
      }
    }
  }

  void _changeSelectedRow(int newRow) {
    if (newRow > 0 && newRow < _rowCount) {
      double screenFrom = _verticalController.offset + _rowHeight;
      double screenTo = _verticalController.position.extentInside - _rowHeight;
      var (rowFrom, rowTo) = _getRowPosition(newRow);
      if (rowTo > (screenTo + screenFrom)) {
        _verticalController.jumpTo((screenFrom + (rowTo - (screenTo + screenFrom))) - _rowHeight);
      }
      if (rowFrom < screenFrom) {
        _verticalController.jumpTo(rowFrom - _rowHeight);
      }
      if (newRow != _actualRow) {
        setState(() {
          _actualRow = newRow;
        });

        if (widget.onChangeRow != null) widget.onChangeRow!(_actualRow, _actualCol, getActualRow);
      }
      if (keyCtrl) {
        _selectionCheckboxChanged(_actualRow);
      }
    }
  }

  void _pageDown() {
    double screenHeight = _verticalController.position.extentInside - _rowHeight;
    int rowsOnScreen = (screenHeight / _rowHeight).round() - 1;
    if ((_actualRow + rowsOnScreen) < _rowCount) {
      _changeSelectedRow(_actualRow + rowsOnScreen);
    } else {
      _changeSelectedRow(_rowCount - 2);
    }
  }

  void _pageUp() {
    double screenHeight = _verticalController.position.extentInside - _rowHeight;
    int rowsOnScreen = (screenHeight / _rowHeight).round() - 1;
    if ((_actualRow - rowsOnScreen) > 0) {
      _changeSelectedRow(_actualRow - rowsOnScreen);
    } else {
      _changeSelectedRow(1);
    }
  }

  void _keyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey.keyLabel == "Control Left" || event.logicalKey.keyLabel == "Control Right") keyCtrl = true;
      if (event.logicalKey.keyLabel == "Shift Left" || event.logicalKey.keyLabel == "Shift Right") keyShift = true;
    }
    if (event is KeyUpEvent) {
      if (event.logicalKey.keyLabel == "Control Left" || event.logicalKey.keyLabel == "Control Right") keyCtrl = false;
      if (event.logicalKey.keyLabel == "Shift Left" || event.logicalKey.keyLabel == "Shift Right") keyShift = false;
    }
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      // print("KEY = ${event.logicalKey.keyLabel}");
      switch (event.logicalKey.keyLabel) {
        case 'Arrow Up':
          _changeSelectedRow(_actualRow - 1);
          break;
        case 'Arrow Down':
          _changeSelectedRow(_actualRow + 1);
          break;
        case 'Page Down':
          _pageDown();
          break;
        case 'Page Up':
          _pageUp();
          break;
        case 'Home':
          _changeSelectedRow(1);
          break;
        case 'End':
          _changeSelectedRow(_rowCount - 1);
          break;
        case 'Arrow Left':
          _changeSelectedColumn(_actualCol - 1);
          break;
        case 'Arrow Right':
          _changeSelectedColumn(_actualCol + 1);
          break;
        case " ":
          _selectionCheckboxChanged(_actualRow);
          _changeSelectedRow(_actualRow + 1);
      }
    }
  }

  void _sortBuffer() {
    if (_sort != null) {
      _rowBuff.sort(
        (a, b) {
          if (_sort!.sort == SilkFieldSort.asc) {
            return a[_sort!.field].toString().compareTo(b[_sort!.field].toString());
          } else {
            return b[_sort!.field].toString().compareTo(a[_sort!.field].toString());
          }
        },
      );
    }
  }

  void _headerCellClick(int column) {
    if (column > 0) {
      SilkGridField actCol = _columns.visibleColumns[column - 1];
      if (_sort != null) {
        if (_sort!.field == actCol.field) {
          switch (_sort!.sort) {
            case SilkFieldSort.none:
              _sort = SilkGridSortInfo(field: actCol.field, sort: SilkFieldSort.asc);
              break;
            case SilkFieldSort.asc:
              _sort = SilkGridSortInfo(field: actCol.field, sort: SilkFieldSort.desc);
              break;
            case SilkFieldSort.desc:
              _sort = null;
          }
        } else {
          _sort = SilkGridSortInfo(field: actCol.field, sort: SilkFieldSort.asc);
        }
      } else {
        _sort = SilkGridSortInfo(field: actCol.field, sort: SilkFieldSort.asc);
      }
      if (_gridDataLoadType == _SilkGridDataLoadType.remote) {
        _rowBuff = [];
        _changeSelectedRow(1);
      } else {
        _sortBuffer();
        setState(() {});
      }
    } else {
      if (widget.multiselect && _columns.visibleColumns.isNotEmpty) {
        if (_selectedRows.isNotEmpty) {
          _selectedRows.clear();
        } else {
          for (int i = 1; i <= _rowCount; i++) {
            if (!_selectedRows.contains(i)) _selectedRows.add(i);
          }
        }
        setState(() {});
        if (widget.selectionChanged != null) widget.selectionChanged!(_selectedRows);
      }
    }
  }

  void _internalLoadData(int row) {
    if (!_loadingData) {
      if (widget.loadRows != null) {
        int tmpOffset = ((row / _rowBuffSize)).floor() * _rowBuffSize;
        _loadingData = true;
        widget.loadRows!(tmpOffset, _rowBuffSize, _sort).then((value) {
          List<dynamic> idata = [];
          int pocet = -1;
          (idata, pocet) = value;
          // print("Loaded $tmpOffset - $pocet, ${idata.length}");
          if (pocet >= 0) {
            _rowCount = pocet;
          }
          _rowBuff = List<dynamic>.filled(_rowBuffSize, null, growable: true);
          _rowBuff.replaceRange(0, idata.length, idata);
          setState(() {
            _rowBuffPos = tmpOffset;
            _loadingData = false;
          });
        });
      }
    }
  }

  Map<String, dynamic>? _getDataRow(int row) {
    // print("-- _getDataRow $row - $_rowBuffPos");
    int frameRow = row - _rowBuffPos;
    Map<String, dynamic>? result;
    if (frameRow >= 0 && frameRow < _rowBuff.length) {
      result = _rowBuff[frameRow];
    }
    if (result == null) {
      if (_gridDataLoadType == _SilkGridDataLoadType.remote) {
        _internalLoadData(row);
      }
    }
    return result;
  }

  Map<String, dynamic>? _getDataRowSafe(int row) {
    // print("-- _getDataRow $row - $_rowBuffPos");
    int frameRow = row - _rowBuffPos;
    Map<String, dynamic>? result;
    if (frameRow >= 0 && frameRow < _rowBuff.length) {
      result = _rowBuff[frameRow];
    }
    return result;
  }

  void _onRowTap(int column, Offset position) {
    double pos = position.dy + _verticalController.offset;
    int row = 0;
    if (position.dy >= _rowHeight) row = (pos / _rowHeight).floor();
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    if (row == 0) {
      _changeSelectedColumn(column, setCursor: false);
      _headerCellClick(column);
    } else {
      _changeSelectedRow(row);
      _changeSelectedColumn(column);
      if (column == 0) {
        _selectionCheckboxChanged(row);
      }
    }
  }

  Widget _drawHeaderCell(BuildContext context, TableVicinity vicinity) {
    if (vicinity.column == 0) {
      return widget.multiselect && _columns.visibleColumns.isNotEmpty
          ? Icon(
              size: 14,
              color: _headerTextColor,
              _selectedRows.isEmpty
                  ? Icons.check_box_outline_blank
                  : _selectedRows.length < _rowCount
                      ? Icons.indeterminate_check_box_outlined
                      : Icons.check_box_outlined,
            )
          : Container();
    } else {
      SilkGridField col = _columns.visibleColumns[vicinity.column - 1];
      String text = col.label;
      TextStyle textStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
            color: _headerTextColor,
            fontWeight: FontWeight.bold,
            overflow: TextOverflow.ellipsis,
          );
      SilkFieldSort columnSort = SilkFieldSort.none;
      if (_sort != null) {
        if (_sort!.field == col.field) {
          columnSort = _sort!.sort;
        }
      }
      return Padding(
        padding: const EdgeInsets.only(left: 3.0, right: 3.0),
        child: Row(
          children: [
            columnSort != SilkFieldSort.none
                ? columnSort == SilkFieldSort.asc
                    ? Icon(
                        Icons.keyboard_double_arrow_up,
                        size: 14,
                        color: _headerTextColor,
                      )
                    : Icon(
                        Icons.keyboard_double_arrow_down,
                        size: 14,
                        color: _headerTextColor,
                      )
                : Container(),
            columnSort != SilkFieldSort.none ? const SizedBox(width: 2) : Container(),
            Expanded(
              child: Center(
                child: Text(
                  text,
                  style: textStyle,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _selectionCheckboxChanged(int row) {
    if (widget.multiselect && _columns.visibleColumns.isNotEmpty) {
      if (_selectedRows.contains(row)) {
        _selectedRows.remove(row);
      } else {
        _selectedRows.add(row);
      }
      setState(() {});
      if (widget.selectionChanged != null) widget.selectionChanged!(_selectedRows);
    }
  }

  Widget _drawRowIndicator(BuildContext context, TableVicinity vicinity) {
    return _selectedRows.isEmpty
        ? vicinity.row == _actualRow
            ? Container(
                alignment: Alignment.centerLeft,
                child: const Icon(Icons.arrow_right),
              )
            : Container()
        : Icon(
            size: 14,
            color: _actualColTextColor,
            _selectedRows.contains(vicinity.row) ? Icons.check_box_outlined : Icons.check_box_outline_blank,
          );
  }

  Widget _drawSingleDataCell(BuildContext context, TableVicinity vicinity) {
    String text = "";
    TextStyle textStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
          color: vicinity.row == _actualRow
              ? vicinity.column == _actualCol
                  ? _actualColTextColor
                  : _actualRowTextColor
              : _textColor,
          fontWeight: FontWeight.normal,
          overflow: TextOverflow.ellipsis,
        );
    Map<String, dynamic>? data = _getDataRow(vicinity.row - 1);
    if (data != null) {
      SilkGridField col = _columns.visibleColumns[vicinity.column - 1];
      if (col.formatText != null) {
        text = col.formatText!(vicinity.row + 1, vicinity.column - 1, _columns, data);
      } else {
        if (data[col.field] != null) {
          text = col.formatValue(data[col.field]);
        } else {
          text = "";
        }
      }
    }
    return Container(
      color: vicinity.row == _actualRow && vicinity.column == _actualCol ? _actualColColor : null,
      child: Padding(
        padding: const EdgeInsets.only(left: 3.0, right: 3.0),
        child: Container(
          alignment: _getFieldAlignment(vicinity.column - 1),
          child: _columns.visibleColumns[vicinity.column - 1].cellBuilder != null && data != null
              ? _columns.visibleColumns[vicinity.column - 1].cellBuilder!(vicinity.row + 1, vicinity.column - 1, _columns, data, textStyle)
              : Text(
                  text,
                  style: textStyle,
                ),
        ),
      ),
    );
  }

  Widget _drawDataCell(BuildContext context, TableVicinity vicinity) {
    if (vicinity.column == 0) {
      return _drawRowIndicator(context, vicinity);
    } else {
      return _drawSingleDataCell(context, vicinity);
    }
  }

  Widget _cellBuilder(BuildContext context, TableVicinity vicinity) {
    if (vicinity.row == 0) {
      return _drawHeaderCell(context, vicinity);
    } else {
      return _drawDataCell(context, vicinity);
    }
  }

  TableSpan _columnBuilder(int column) {
    return TableSpan(
      extent: FixedTableSpanExtent(column == 0 ? _inticatorWidth : _getFieldWidth(column)),
      backgroundDecoration: TableSpanDecoration(
        border: TableSpanBorder(
          trailing: BorderSide(color: _borderColor),
        ),
      ),
      recognizerFactories: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (TapGestureRecognizer t) {
            t.onTapDown = (TapDownDetails details) {
              double pos = details.localPosition.dy + _verticalController.offset;
              int row = 0;
              if (details.localPosition.dy >= _rowHeight) row = (pos / _rowHeight).floor();
              _onRowTap(column, details.localPosition);
              if (widget.onBtnTap != null) widget.onBtnTap!(row, column, getActualRow, details);
            };
            t.onSecondaryTapDown = (TapDownDetails details) {
              double pos = details.localPosition.dy + _verticalController.offset;
              int row = 0;
              if (details.localPosition.dy >= _rowHeight) row = (pos / _rowHeight).floor();
              _onRowTap(column, details.localPosition);
              if (widget.onMiddleBtnTap != null) widget.onMiddleBtnTap!(row, column, getActualRow, details);
            };
            t.onTertiaryTapDown = (TapDownDetails details) {
              double pos = details.localPosition.dy + _verticalController.offset;
              int row = 0;
              if (details.localPosition.dy >= _rowHeight) row = (pos / _rowHeight).floor();
              _onRowTap(column, details.localPosition);
              if (widget.onRightBtnTap != null) widget.onRightBtnTap!(row, column, getActualRow, details);
            };
          },
        ),
        DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
          () => DoubleTapGestureRecognizer(),
          (DoubleTapGestureRecognizer t) {
            //
            t.onDoubleTapDown = (TapDownDetails details) {
              double pos = details.localPosition.dy + _verticalController.offset;
              int row = 0;
              if (details.localPosition.dy >= _rowHeight) row = (pos / _rowHeight).floor();
              _onRowTap(column, details.localPosition);
              if (widget.onBtnDoubleTap != null) widget.onBtnDoubleTap!(row, column, getActualRow, details);
            };
          },
        ),
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(() => LongPressGestureRecognizer(), (LongPressGestureRecognizer t) {
          t.onLongPress = () {
            _selectionCheckboxChanged(_actualRow);
          };
        }),
      },
    );
  }

  TableSpan _rowBuilder(int index) {
    Map<String, dynamic>? data = _getDataRowSafe(index - 1);
    return TableSpan(
      extent: FixedTableSpanExtent(_rowHeight),
      backgroundDecoration: TableSpanDecoration(
        color: (index == 0)
            ? _headerColor
            : index == _actualRow
                ? _actualRowColor
                : widget.onGetRowColor != null && data != null
                    ? widget.onGetRowColor!(index, data)
                    : null,
        border: TableSpanBorder(
          trailing: BorderSide(color: _borderColor),
        ),
      ),
    );
  }

  ///
  Map<String, dynamic> get getActualRow {
    return _rowBuff[_actualRow];
  }

  ///
  @override
  void initState() {
    super.initState();
    _columns = widget.columns.copyWith(locale: widget.locale);
    if (widget.rows != null) {
      _rowBuff = List.from(widget.rows!);
      _rowCount = _rowBuff.length + 1;
      _gridDataLoadType = _SilkGridDataLoadType.local;
    } else {
      if (widget.loadRows != null) {
        _gridDataLoadType = _SilkGridDataLoadType.remote;
      } else {
        _gridDataLoadType = _SilkGridDataLoadType.local;
        throw ("You must specify [rows] or the [loadRows] method.");
      }
    }
    _horizontalController.addListener(_refreshFooterColumsPosition);
    initializeDateFormatting(widget.locale.toLanguageTag(), null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Theme.of(context).brightness == Brightness.light) {
      _textColor = widget.textColor ?? Theme.of(context).colorScheme.onBackground;
      _borderColor = widget.borderColor ?? Theme.of(context).focusColor;
      _headerColor = widget.headerColor ?? Theme.of(context).buttonTheme.colorScheme!.primary;
      _headerTextColor = widget.headerTextColor ?? Theme.of(context).buttonTheme.colorScheme!.onPrimary;
      _actualColColor = widget.actualColColor ?? Theme.of(context).buttonTheme.colorScheme!.inversePrimary;
      _actualColTextColor = widget.actualColTextColor ?? Theme.of(context).buttonTheme.colorScheme!.onPrimaryContainer;
      _actualRowColor = widget.actualRowColor ?? Theme.of(context).buttonTheme.colorScheme!.secondaryContainer;
      _actualRowTextColor = widget.actualRowTextColor ?? Theme.of(context).buttonTheme.colorScheme!.onSecondaryContainer;
      _toolbarColor = widget.toolbarColor ?? Theme.of(context).colorScheme.surfaceVariant;
      _toolbarIconColor = widget.toolbarIconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    } else {
      _textColor = widget.textColor ?? Theme.of(context).colorScheme.onBackground;
      _borderColor = widget.borderColor ?? Theme.of(context).focusColor;
      _headerColor = widget.headerColor ?? Theme.of(context).buttonTheme.colorScheme!.primaryContainer;
      _headerTextColor = widget.headerTextColor ?? Theme.of(context).buttonTheme.colorScheme!.onPrimaryContainer;
      _actualColColor = widget.actualColColor ?? Theme.of(context).buttonTheme.colorScheme!.primaryContainer;
      _actualColTextColor = widget.actualColTextColor ?? Theme.of(context).buttonTheme.colorScheme!.onPrimaryContainer;
      _actualRowColor = widget.actualRowColor ?? Theme.of(context).buttonTheme.colorScheme!.secondaryContainer;
      _actualRowTextColor = widget.actualRowTextColor ?? Theme.of(context).buttonTheme.colorScheme!.onSecondaryContainer;
      _toolbarColor = widget.toolbarColor ?? Theme.of(context).colorScheme.surfaceVariant;
      _toolbarIconColor = widget.toolbarIconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    }
    // print("--- didChangeDependencies");
  }

  @override
  Widget build(BuildContext context) {
    // disableContextMenu();
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // print("----- $constraints");
          _recalculateColumnsWidth(constraints);
          return KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _keyEvent,
            child: TableView.builder(
              verticalDetails: ScrollableDetails.vertical(controller: _verticalController),
              horizontalDetails: ScrollableDetails.horizontal(controller: _horizontalController),
              columnCount: _columns.visibleCount + 1,
              rowCount: _rowCount <= 0 ? 2 : _rowCount,
              pinnedRowCount: 1,
              pinnedColumnCount: 1,
              cacheExtent: (_columns.visibleCount + 1) * 110,
              cellBuilder: _cellBuilder,
              columnBuilder: _columnBuilder,
              rowBuilder: _rowBuilder,
            ),
          );
        },
      ),
    );
  }
}

class SilkGridFooter {
  final List<SilkGridFooterRow> rows;
  SilkGridFooter({
    required this.rows,
  });
}

class SilkGridView extends StatelessWidget {
  //
  final GlobalKey<_SilkGridSimpleViewState> _gridKey = GlobalKey<_SilkGridSimpleViewState>();
  final GlobalKey<_SilkGridFooterState> _footerKey = GlobalKey<_SilkGridFooterState>();
  //
  final List<dynamic>? rows;
  final LoadRows? loadRows;
  final SilkGridColumns columns;
  final SilkGridFooter? footerRows;
  final RowColor? onGetRowColor;
  final Locale locale;
  final List<Widget>? actions;
  final ChangeRowEvent? onChangeRow;
  final SelectionChanged? selectionChanged;
  final GridMouseEvent? onRightBtnTap;
  final GridMouseEvent? onMiddleBtnTap;
  final GridMouseEvent? onBtnTap;
  final GridMouseEvent? onBtnDoubleTap;
  final bool multiselect;
  final Color? textColor;
  final Color? borderColor;
  final Color? headerColor;
  final Color? headerTextColor;
  final Color? actualRowColor;
  final Color? actualRowTextColor;
  final Color? actualColColor;
  final Color? actualColTextColor;
  final Color? toolbarColor;
  final Color? toolbarIconColor;
  final int pageSize;

  SilkGridView({
    super.key,
    this.rows,
    this.loadRows,
    required this.columns,
    this.footerRows,
    this.onGetRowColor,
    this.locale = const Locale("EN-us"),
    this.actions,
    this.onChangeRow,
    this.selectionChanged,
    this.onRightBtnTap,
    this.onMiddleBtnTap,
    this.onBtnTap,
    this.onBtnDoubleTap,
    this.multiselect = false,
    this.textColor,
    this.borderColor,
    this.headerColor,
    this.headerTextColor,
    this.actualRowColor,
    this.actualRowTextColor,
    this.actualColColor,
    this.actualColTextColor,
    this.toolbarColor,
    this.toolbarIconColor,
    this.pageSize = 200,
  }) : assert(rows != null || loadRows != null || pageSize < 10);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Toolbar
        actions != null && actions!.isNotEmpty
            ? Container(
                alignment: Alignment.center,
                height: 50,
                color: Theme.of(context).brightness == Brightness.light
                    ? toolbarColor ?? Theme.of(context).colorScheme.surfaceVariant
                    : toolbarColor ?? Theme.of(context).colorScheme.surfaceVariant,
                child: SingleChildScrollView(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [...actions!],
                  ),
                ),
              )
            : Container(),

        /// Grid
        _SilkGridSimpleView(
          key: _gridKey,
          footerKey: _footerKey,
          rows: rows,
          loadRows: loadRows,
          columns: columns,
          locale: locale,
          onChangeRow: onChangeRow,
          selectionChanged: selectionChanged,
          onRightBtnTap: onRightBtnTap,
          onMiddleBtnTap: onMiddleBtnTap,
          onBtnTap: onBtnTap,
          onBtnDoubleTap: onBtnDoubleTap,
          multiselect: multiselect,
          textColor: textColor,
          borderColor: borderColor,
          headerColor: headerColor,
          headerTextColor: headerTextColor,
          actualRowColor: actualRowColor,
          actualRowTextColor: actualRowTextColor,
          actualColColor: actualColColor,
          actualColTextColor: actualColTextColor,
          toolbarColor: toolbarColor,
          toolbarIconColor: toolbarIconColor,
          onGetRowColor: onGetRowColor,
          pageSize: pageSize,
        ),

        /// footer
        footerRows != null
            ? _SilkGridFooter(
                key: _footerKey,
                gridKey: _gridKey,
                rows: footerRows!.rows,
              )
            : Container(),
      ],
    );
  }
}
