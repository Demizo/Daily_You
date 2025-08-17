import 'package:daily_you/widgets/settings_dropdown.dart';
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
      return StatefulBuilder(
        builder: (BuildContext context, setState) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Year Dropdown
              DropdownButton<int>(
                underline: Container(),
                elevation: 1,
                isDense: false,
                isExpanded: false,
                alignment: AlignmentDirectional.centerEnd,
                borderRadius: BorderRadius.circular(20),
                value: selectedYear,
                items: years
                    .map((y) => DropdownMenuItem<int>(
                          value: y,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: y == selectedYear
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                y.toString()),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedYear = value;
                      if (selectedYear == DateTime.now().year &&
                          selectedMonth > DateTime.now().month) {
                        selectedMonth = DateTime.now().month;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Month Dropdown
              DropdownButton<int>(
                underline: Container(),
                elevation: 1,
                isDense: false,
                isExpanded: false,
                alignment: AlignmentDirectional.centerEnd,
                borderRadius: BorderRadius.circular(20),
                value: selectedMonth,
                items: List.generate(
                  selectedYear == DateTime.now().year
                      ? DateTime.now().month
                      : 12,
                  (i) => DropdownMenuItem<int>(
                    value: i + 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: i + 1 == selectedMonth
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          months[i]),
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedMonth = value;
                    });
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
                Navigator.pop(
                    context, DateTime(selectedYear, selectedMonth, 1));
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
    },
  );
}
