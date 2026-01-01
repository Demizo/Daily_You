import 'package:flutter/material.dart';

class SelectionProvider extends ChangeNotifier {
  final Set<DateTime> _selectedDates = {};

  bool get isSelectionMode => _selectedDates.isNotEmpty;
  Set<DateTime> get selectedDates => Set.unmodifiable(_selectedDates);
  int get selectedCount => _selectedDates.length;

  void toggleDate(DateTime date) {
    DateTime normalized = DateTime(date.year, date.month, date.day);
    if (_selectedDates.contains(normalized)) {
      _selectedDates.remove(normalized);
    } else {
      _selectedDates.add(normalized);
    }
    notifyListeners();
  }

  bool isSelected(DateTime date) {
    DateTime normalized = DateTime(date.year, date.month, date.day);
    return _selectedDates.contains(normalized);
  }

  void clearSelection() {
    _selectedDates.clear();
    notifyListeners();
  }
}
