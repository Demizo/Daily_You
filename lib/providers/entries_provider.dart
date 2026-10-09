import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:material_ui/material_ui.dart';

enum OrderBy { date, mood, tracker }

enum SortOrder { ascending, descending }

class EntriesProvider with ChangeNotifier {
  static final EntriesProvider instance = EntriesProvider._init();

  EntriesProvider._init() {
    _store.addListener(_onStoreChanged);
  }

  final EntryStore _store = EntryStore.instance;

  List<Entry> get entries => _store.entries;

  List<Entry> _filteredEntries = [];

  String _searchText = "";
  String get searchText => _searchText;

  set searchText(String newSearchText) {
    if (_searchText == newSearchText) return;
    _searchText = newSearchText;
    _calculateFilteredEntries();
    notifyListeners();
  }

  DateTime? _startDate;
  DateTime? get startDate => _startDate;
  set startDate(DateTime? date) {
    if (_startDate == date) return;
    _startDate = date;
    _calculateFilteredEntries();
    notifyListeners();
  }

  DateTime? _endDate;
  DateTime? get endDate => _endDate;
  set endDate(DateTime? date) {
    if (_endDate == date) return;
    _endDate = date;
    _calculateFilteredEntries();
    notifyListeners();
  }

  Set<int> _filterTagIds = {};
  Set<int> get filterTagIds => _filterTagIds;
  set filterTagIds(Set<int> ids) {
    _filterTagIds = ids;
    _calculateFilteredEntries();
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _searchText.isNotEmpty ||
      _startDate != null ||
      _endDate != null ||
      _filterTagIds.isNotEmpty;

  void clearFilters() {
    _searchText = "";
    _startDate = null;
    _endDate = null;
    _filterTagIds = {};
    _calculateFilteredEntries();
    notifyListeners();
  }

  OrderBy _orderBy = OrderBy.date;
  OrderBy get orderBy => _orderBy;

  set orderBy(OrderBy newOrderBy) {
    if (_orderBy == newOrderBy) return;
    _orderBy = newOrderBy;
    _calculateFilteredEntries();
    notifyListeners();
  }

  int? _trackerSortTagId;
  int? get trackerSortTagId => _trackerSortTagId;
  set trackerSortTagId(int? id) {
    if (_trackerSortTagId == id) return;
    _trackerSortTagId = id;
    notifyListeners();
  }

  SortOrder _sortOrder = SortOrder.descending;
  SortOrder get sortOrder => _sortOrder;

  set sortOrder(SortOrder newSortOrder) {
    if (_sortOrder == newSortOrder) return;
    _sortOrder = newSortOrder;
    _calculateFilteredEntries();
    notifyListeners();
  }

  Future<void> load() => _store.load();

  Future<Entry> add(Entry entry, {bool skipUpdate = false}) =>
      _store.add(entry, skipUpdate: skipUpdate);

  Future<void> deleteAll(Function(String) updateStatus) =>
      _store.deleteAll(updateStatus);

  int getIndexOfEntry(int entryId) => _store.getIndexOfEntry(entryId);

  Entry? getEntryForToday() => _store.getEntryForToday();

  Entry? getEntryForDate(DateTime date) => _store.getEntryForDate(date);

  List<Entry> getEntriesForDate(DateTime date) =>
      _store.getEntriesForDate(date);

  int getEntryDayCount() => _store.getEntryDayCount();

  bool hasEntryAtTimestamp(DateTime timestamp) =>
      _store.hasEntryAtTimestamp(timestamp);

  List<Entry> getFilteredEntries() => _filteredEntries;

  void _onStoreChanged() {
    _calculateFilteredEntries();
    notifyListeners();
  }

  void _calculateFilteredEntries() {
    List<Entry> filteredEntries = entries.where((entry) {
      if (_searchText.isNotEmpty &&
          !entry.text.toLowerCase().contains(_searchText.toLowerCase())) {
        return false;
      }
      if (_startDate != null && entry.timeCreate.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && entry.timeCreate.isAfter(_endDate!)) {
        return false;
      }
      if (_filterTagIds.isNotEmpty) {
        final entryTags =
            TagsProvider.instance.getEntryTagsForEntry(entry.id ?? -1);
        final tagIds = entryTags.map((et) => et.tagId).toSet();
        if (!tagIds.any((id) => _filterTagIds.contains(id))) {
          return false;
        }
      }
      return true;
    }).toList();

    if (_orderBy == OrderBy.mood) {
      filteredEntries.sort((a, b) {
        var aValue = a.mood ?? -999;
        var bValue = b.mood ?? -999;
        return bValue.compareTo(aValue);
      });
    }

    if (_sortOrder == SortOrder.ascending) {
      filteredEntries = filteredEntries.reversed.toList();
    }

    _filteredEntries = filteredEntries;
  }
}
