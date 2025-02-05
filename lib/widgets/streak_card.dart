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
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary)),
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0, right: 6.0),
                    child: Text(number.toString(),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }
}
