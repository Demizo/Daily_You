import 'package:flutter/material.dart';

class StreakCard extends StatelessWidget {
  final bool isVisible;
  final String title;
  final int number;
  final IconData icon;

  const StreakCard(
      {super.key,
      this.isVisible = false,
      this.title = "",
      this.number = -1,
      this.icon = Icons.bolt});

  @override
  Widget build(BuildContext context) {
    return isVisible
        ? Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Icon(icon,
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.secondary)),
                  Text(number.toString(),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
          )
        : Container();
  }
}
