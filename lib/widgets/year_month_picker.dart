import 'package:daily_you/time_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

Future<DateTime?> showYearMonthPicker(
  BuildContext context, {
  DateTime? initialDate,
  bool isJalali = false,
}) {
  final now = DateTime.now();
  final locale = Localizations.localeOf(context).toString();

  if (isJalali) {
    return _showJalaliPicker(context, initialDate: initialDate, locale: locale);
  } else {
    return _showGregorianPicker(context, initialDate: initialDate, now: now,
        locale: locale);
  }
}

Future<DateTime?> _showGregorianPicker(
  BuildContext context, {
  required DateTime? initialDate,
  required DateTime now,
  required String locale,
}) {
  int selectedYear = (initialDate ?? now).year;
  int selectedMonth = (initialDate ?? now).month;

  List<String> localizedMonths() {
    final formatter = DateFormat.MMMM(locale);
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
                      if (selectedYear == now.year &&
                          selectedMonth > now.month) {
                        selectedMonth = now.month;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButton<int>(
                underline: Container(),
                elevation: 1,
                isDense: false,
                isExpanded: false,
                alignment: AlignmentDirectional.centerEnd,
                borderRadius: BorderRadius.circular(20),
                value: selectedMonth,
                items: List.generate(
                  selectedYear == now.year ? now.month : 12,
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
              onPressed: () => Navigator.pop(context),
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

Future<DateTime?> _showJalaliPicker(
  BuildContext context, {
  required DateTime? initialDate,
  required String locale,
}) {
  final nowJ = Jalali.now();
  final firstDateJ = Jalali.fromDateTime(DateTime(2000, 1, 1));

  final initJ = initialDate != null
      ? Jalali.fromDateTime(initialDate)
      : nowJ;

  int selectedYear = initJ.year;
  int selectedMonth = initJ.month;

  final years = List.generate(
      nowJ.year - firstDateJ.year + 1, (i) => firstDateJ.year + i);

  final months = List.generate(
      12, (i) => TimeManager.jalaliMonthName(i + 1, locale));

  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, setState) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                      if (selectedYear == nowJ.year &&
                          selectedMonth > nowJ.month) {
                        selectedMonth = nowJ.month;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButton<int>(
                underline: Container(),
                elevation: 1,
                isDense: false,
                isExpanded: false,
                alignment: AlignmentDirectional.centerEnd,
                borderRadius: BorderRadius.circular(20),
                value: selectedMonth,
                items: List.generate(
                  selectedYear == nowJ.year ? nowJ.month : 12,
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
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context, Jalali(selectedYear, selectedMonth, 1).toDateTime());
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
    },
  );
}
