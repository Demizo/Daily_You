import 'package:flutter/material.dart';

class EntryTextEditor extends StatefulWidget {
  final String text;
  final ValueChanged<String> onChangedText;

  const EntryTextEditor(
      {super.key, this.text = '', required this.onChangedText});

  @override
  State<EntryTextEditor> createState() => _EntryTextEditorState();
}

class _EntryTextEditorState extends State<EntryTextEditor> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      minLines: 5,
      maxLines: null,
      initialValue: widget.text,
      style: const TextStyle(fontSize: 16),
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Type something... (supports markdown)',
      ),
      onChanged: widget.onChangedText,
    );
  }
}
