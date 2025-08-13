import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showYearMonthPicker(
  BuildContext context, {
  DateTime? initialDate,
}) {
  final now = DateTime.now();
  int selectedYear = (initialDate ?? now).year;
  int selectedMonth = (initialDate ?? now).month;

  List<String> localizedMonths() {
    final formatter =
        DateFormat.MMMM(Localizations.localeOf(context).toString());
    return List.generate(
        12, (i) => formatter.format(DateTime(now.year, i + 1, 1)));
  }

  final months = localizedMonths();
  final years = List.generate(now.year - 2000 + 1, (i) => 2000 + i);

  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year Dropdown
            DropdownMenu<int>(
              initialSelection: selectedYear,
              dropdownMenuEntries: years
                  .map((y) => DropdownMenuEntry<int>(
                        value: y,
                        label: y.toString(),
                      ))
                  .toList(),
              onSelected: (value) {
                if (value != null) {
                  selectedYear = value;
                }
              },
            ),
            const SizedBox(height: 16),
            // Month Dropdown
            DropdownMenu<int>(
              initialSelection: selectedMonth,
              dropdownMenuEntries: List.generate(
                12,
                (i) => DropdownMenuEntry<int>(
                  value: i + 1,
                  label: months[i],
                ),
              ),
              onSelected: (value) {
                if (value != null) {
                  selectedMonth = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // cancel
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, DateTime(selectedYear, selectedMonth, 1));
            },
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      );
    },
  );
}
