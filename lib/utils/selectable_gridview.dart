import 'package:flutter/material.dart';

/// A customizable grid view widget that allows for selection and padding.
///
/// The `SelectableGridview` widget provides a flexible and reusable way to create
/// a grid layout with custom padding, grid delegation, item count, and item builder.
class SelectableGridview extends StatefulWidget {
  /// The padding around the grid items.
  final EdgeInsets padding;

  /// The delegate that controls the layout of the grid items.
  ///
  /// This can be any subclass of `SliverGridDelegate`, such as
  /// `SliverGridDelegateWithFixedCrossAxisCount` or
  /// `SliverGridDelegateWithMaxCrossAxisExtent`.
  final SliverGridDelegate gridDelegate;

  /// The total number of items in the grid.
  final int itemCount;

  /// The builder function to create each grid item.
  ///
  /// This function is called with the current `BuildContext` and the index
  /// of the item to be built. It should return a widget for the grid item.
  /// If `null` is returned, the grid will show nothing for that position.
  final Widget? Function(BuildContext, int) itemBuilder;

  /// Creates a `SelectableGridview`.
  ///
  /// - [padding]: The padding around the grid view.
  /// - [gridDelegate]: The delegate that controls the layout of the grid items.
  /// - [itemCount]: The total number of items in the grid.
  /// - [itemBuilder]: A function to build the items in the grid.
  ///
  /// All parameters are required.
  const SelectableGridview({
    super.key,
    required this.padding,
    required this.gridDelegate,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<SelectableGridview> createState() => _SelectableGridviewState();
}

class _SelectableGridviewState extends State<SelectableGridview> {
  bool _isSelection = false;
  Set _selectedIndices = {};
  late EdgeInsets _padding = const EdgeInsets.all(0);
  double changePadding = 3;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: widget.padding,
      gridDelegate: widget.gridDelegate,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return selectableItem(index);
      },
    );
  }

  GestureDetector selectableItem(int index) {
    Widget child = widget.itemBuilder(context, index)!;
    return GestureDetector(
        onLongPress: () {
          setState(() {
            if (_isSelection) {
              _isSelection = false;
              _padding = const EdgeInsets.all(0);
              return;
            } else {
              _isSelection = true;
              _padding = EdgeInsets.all(changePadding);
            }
          });
          _selectedIndices.clear();
        },
        onTap: () {
          setState(() {
            if (!_selectedIndices.contains(index)) {
              _selectedIndices.add(index);
            } else {
              _selectedIndices.remove(index);
            }
          });
        },
        child: Container(
          padding: _padding,
          child: Stack(children: [
            child,
            if (_isSelection)
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _selectedIndices.contains(index)
                        ? Colors.black87
                        : Colors.black38),
                alignment: Alignment.center,
                child: _selectedIndices.contains(index)
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                      )
                    : Container(),
              )
          ]),
        ));
  }
}
