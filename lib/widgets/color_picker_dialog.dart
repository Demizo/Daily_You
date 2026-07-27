import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

final List<Color> tagColorPalette = [
  Colors.red.shade500,
  Colors.pink.shade500,
  Colors.purple.shade500,
  Colors.deepPurple.shade500,
  Colors.indigo.shade500,
  Colors.blue.shade500,
  Colors.lightBlue.shade600,
  Colors.cyan.shade700,
  Colors.teal.shade600,
  Colors.green.shade600,
  Colors.lightGreen.shade700,
  Colors.lime.shade800,
  Colors.yellow.shade700,
  Colors.amber.shade700,
  Colors.orange.shade600,
  Colors.deepOrange.shade500,
  Colors.brown.shade500,
  Colors.blueGrey.shade500,
];

/// Result of [ColorPickerDialog]. Distinguishes "user picked no color" (only
/// possible when [ColorPickerDialog.showNoneOption] is true) from the dialog
/// being dismissed without a selection, which returns null instead.
class ColorPickerResult {
  final Color? color;

  const ColorPickerResult(this.color);
}

class ColorPickerDialog extends StatefulWidget {
  final Color? initialColor;

  final bool showNoneOption;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    this.showNoneOption = false,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _pickerColor =>
      _selectedColor ?? Theme.of(context).colorScheme.secondary;

  void _confirm() {
    Navigator.of(context).pop(ColorPickerResult(_selectedColor));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.colorPickerTitle),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.colorPickerPaletteTab),
                Tab(text: l10n.iconPickerCustomTab),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPaletteTab(context),
                  _buildCustomTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }

  Widget _buildNoneOption(BuildContext context) {
    final isSelected = _selectedColor == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _selectedColor = null),
        icon: Icon(isSelected ? Icons.check_rounded : Icons.block_rounded),
        label: Text(AppLocalizations.of(context)!.noTemplateTitle),
      ),
    );
  }

  Widget _buildPaletteTab(BuildContext context) {
    return Column(
      children: [
        if (widget.showNoneOption) _buildNoneOption(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 48,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: tagColorPalette.length,
              itemBuilder: (context, index) {
                final color = tagColorPalette[index];
                final isSelected = _selectedColor != null &&
                    color.toARGB32() == _selectedColor!.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 20,
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: HueRingPicker(
        enableAlpha: false,
        portraitOnly: true,
        pickerColor: _pickerColor,
        onColorChanged: (color) => setState(() => _selectedColor = color),
      ),
    );
  }
}
