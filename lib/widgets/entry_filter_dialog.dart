// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class EntryFilterDialog extends StatefulWidget {
  const EntryFilterDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const EntryFilterDialog(),
    );
  }

  @override
  State<EntryFilterDialog> createState() => _EntryFilterDialogState();
}

class _EntryFilterDialogState extends State<EntryFilterDialog> {
  late TextEditingController _searchController;
  late Set<int> _selectedTagIds;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final provider = EntriesProvider.instance;
    _searchController = TextEditingController(text: provider.searchText);
    _selectedTagIds = Set.from(provider.filterTagIds);
    _startDate = provider.startDate;
    _endDate = provider.endDate;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: initialRange,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  void _applyFilters() {
    final provider = EntriesProvider.instance;
    provider.searchText = _searchController.text.trim();
    provider.startDate = _startDate;
    provider.endDate = _endDate;
    provider.filterTagIds = _selectedTagIds;
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    EntriesProvider.instance.clearFilters();
    setState(() {
      _searchController.clear();
      _selectedTagIds.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagsProvider = Provider.of<TagsProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    String dateRangeLabel = 'All Dates';
    if (_startDate != null && _endDate != null) {
      dateRangeLabel =
          '${TimeManager.formatDate(_startDate!, context)} - ${TimeManager.formatDate(_endDate!, context)}';
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Entries',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Content search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l10n.searchLogsHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            // Date range button
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range_rounded),
              title: const Text('Date Range'),
              subtitle: Text(dateRangeLabel),
              trailing: _startDate != null
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      }),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: _pickDateRange,
            ),
            const Divider(),
            // Tag filters
            Text(
              l10n.selectTagTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (tagsProvider.tags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No tags created yet',
                  style: TextStyle(color: theme.disabledColor),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in tagsProvider.tags)
                    FilterChip(
                      label: Text(tag.name),
                      selected: _selectedTagIds.contains(tag.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTagIds.add(tag.id!);
                          } else {
                            _selectedTagIds.remove(tag.id!);
                          }
                        });
                      },
                    ),
                ],
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
