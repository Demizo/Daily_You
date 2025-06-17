import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StreakCard extends StatelessWidget {
  final bool isVisible;
  final String title;
  final IconData icon;

  const StreakCard(
      {super.key,
      this.isVisible = false,
      this.title = "",
      this.icon = Icons.bolt});

  @override
  Widget build(BuildContext context) {
    // Find the number to style it
    final RegExp regex = RegExp(r'\d+');
    final match = regex.firstMatch(title);

    if (match == null) {
      return Container();
    }

    final formatter = NumberFormat('#,###');
    final int numberStart = match.start;
    final int numberEnd = match.end;

    return isVisible
        ? Card(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: title.substring(0, numberStart),
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary)),
                      TextSpan(
                        text: formatter.format(
                            int.parse(title.substring(numberStart, numberEnd))),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      TextSpan(
                          text: title.substring(numberEnd),
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary)),
                    ])),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }
}
