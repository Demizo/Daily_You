import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/services/share_intent_service.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/share_image_preview.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// The entry-point page shown when the user shares images into Daily You.
///
/// Displays:
///  - a preview of the shared image(s)
///  - a date selection area (quick "Today" chip + calendar picker)
///  - Cancel / Add to Diary action buttons
///
/// On confirmation it compresses the images via [ShareIntentService] and
/// pushes [AddEditEntryPage] with the pre-loaded images.
class ShareToEntryPage extends StatefulWidget {
  /// Raw URI strings (content:// or file paths) for the incoming images.
  final List<String> sharedUris;

  const ShareToEntryPage({super.key, required this.sharedUris});

  @override
  State<ShareToEntryPage> createState() => _ShareToEntryPageState();
}

class _ShareToEntryPageState extends State<ShareToEntryPage> {
  late DateTime _selectedDate;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  bool get _isToday => TimeManager.isToday(_selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.utc(2000),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.day,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = _selectedDate.copyWith(
          year: picked.year,
          month: picked.month,
          day: picked.day,
        );
      });
    }
  }

  Future<void> _addToEntry() async {
    if (_processing) return;
    setState(() => _processing = true);

    final entriesProvider =
        Provider.of<EntriesProvider>(context, listen: false);
    final entryImagesProvider =
        Provider.of<EntryImagesProvider>(context, listen: false);

    // Resolved before the try block so the catch can roll back if needed.
    final existingEntry = entriesProvider.getEntryForDate(_selectedDate);

    // Promoted outside try so catch can reference it for rollback.
    Entry? targetEntry;

    try {
      final overrideDate = TimeManager.isToday(_selectedDate)
          ? DateTime.now()
          : TimeManager.currentTimeOnDifferentDate(_selectedDate);

      // Resolve (or create) the target entry so we have a real database id
      // before we store the images. This prevents entryId=-1 breaking the
      // image → entry association.
      targetEntry = existingEntry ??
          await entriesProvider.createNewEntry(overrideDate);
      final entryId = targetEntry!.id!;

      final savedImages = await ShareIntentService.instance
          .saveSharedImages(widget.sharedUris, entryId);

      if (!mounted) return;

      // If no images could be processed, inform the user and stay on the page.
      if (savedImages.isEmpty) {
        // Roll back the newly created entry if we made one and it's empty.
        if (existingEntry == null) {
          await entriesProvider.remove(targetEntry!);
        }
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shareErrorProcessing),
          ),
        );
        return;
      }

      // Persist the shared images via the provider so they are in the DB.
      for (final img in savedImages) {
        await entryImagesProvider.add(img);
      }

      if (!mounted) return;

      // Reload all images for the entry (existing + newly added) for the edit page.
      final allImages = entryImagesProvider.getForEntry(targetEntry!);

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          allowSnapshotting: false,
          builder: (_) => AddEditEntryPage(
            entry: targetEntry,
            overrideCreateDate: overrideDate,
            images: allImages,
          ),
        ),
      );
    } catch (_) {
      // Roll back a newly created entry so no empty record is left in the DB.
      // Only attempt rollback if targetEntry was assigned (i.e. createNewEntry
      // succeeded before the subsequent failure).
      if (existingEntry == null && targetEntry != null) {
        try {
          await entriesProvider.remove(targetEntry!);
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.shareErrorProcessing,
            ),
          ),
        );
      }
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = TimeManager.currentLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareToEntryTitle),
        leading: BackButton(onPressed: _cancel),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Image preview ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ShareImagePreview(paths: widget.sharedUris),
            ),

            const Divider(height: 1),

            // ── Date selection ────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.selectDate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Today quick-select chip
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          selected: _isToday,
                          label: Text(l10n.addToToday),
                          onSelected: (_) {
                            setState(() => _selectedDate = DateTime.now());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Calendar picker trigger + selected date display
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  DateFormat.yMMMEd(locale)
                                      .format(_selectedDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Action buttons ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _processing ? null : _cancel,
                      child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _processing ? null : _addToEntry,
                      icon: _processing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.book_rounded),
                      label: Text(l10n.addToEntry),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
