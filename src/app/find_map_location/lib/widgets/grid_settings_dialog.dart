import 'package:flutter/material.dart';

/// Dialog for configuring grid cell size.
///
/// Displays radio buttons for selecting one of the available cell sizes:
/// 250m, 500m, 1000m, or 2000m.
class GridSettingsDialog extends StatefulWidget {
  /// The currently selected cell size in meters.
  final int currentCellSizeMeters;

  const GridSettingsDialog({
    super.key,
    required this.currentCellSizeMeters,
  });

  @override
  State<GridSettingsDialog> createState() => _GridSettingsDialogState();
}

class _GridSettingsDialogState extends State<GridSettingsDialog> {
  late int _selectedSize;

  /// Available cell size options in meters.
  static const List<int> _availableSizes = [250, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.currentCellSizeMeters;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grid Cell Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _availableSizes.map((size) {
          return Semantics(
            label: 'Grid cell size $size meters${size == _selectedSize ? ", currently selected" : ""}',
            checked: size == _selectedSize,
            child: RadioListTile<int>(
              title: Text('${size}m'),
              value: size,
              groupValue: _selectedSize,
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _selectedSize = value;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cancel - return null
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedSize); // Return selected size
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
