import 'package:flutter/material.dart';

class SettingsCategory extends StatelessWidget {
  final String title;
  final String? hint;
  final IconData icon;
  final Widget page;

  const SettingsCategory({
    super.key,
    required this.title,
    this.hint,
    required this.icon,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
      ),
      subtitle: hint != null ? Text(hint!) : null,
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        child: Icon(
          icon,
        ),
      ),
      minVerticalPadding: 18,
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
          allowSnapshotting: false,
          builder: (context) => page,
        ));
      },
    );
  }
}
