import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/card/card_provider.dart';
import '../theme/app_colors.dart';
import '../../data/vos/business_card_model.dart';
import '../widgets/card_item.dart';
import '../widgets/loading_view.dart';
import '../widgets/theme_toggle_button.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _hasSearched = false;
  bool _isLoading = false;
  List<BusinessCardModel> _results = [];
  String? _error;

  String? _cityFilter;
  String? _stateFilter;
  String? _countryFilter;

  bool get _hasActiveFilters =>
      _cityFilter != null || _stateFilter != null || _countryFilter != null;

  void _onSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty && !_hasActiveFilters) return;

    setState(() {
      _hasSearched = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await ref.read(cardProvider.notifier).searchCards(
            query,
            city: _cityFilter,
            state: _stateFilter,
            country: _countryFilter,
          );
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "An error occurred while searching";
        _isLoading = false;
      });
    }
  }

  Future<void> _openFilterSheet() async {
    final applied = await showModalBottomSheet<_AddressFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressFilterSheet(
        initial: _AddressFilter(
          city: _cityFilter,
          state: _stateFilter,
          country: _countryFilter,
        ),
      ),
    );

    if (applied == null || !mounted) return;
    setState(() {
      _cityFilter = applied.city;
      _stateFilter = applied.state;
      _countryFilter = applied.country;
    });

    if (_searchCtrl.text.trim().isNotEmpty || _hasActiveFilters) {
      _onSearch();
    } else if (_hasSearched) {
      // Filters cleared and no query left: reset to the idle state.
      setState(() {
        _hasSearched = false;
        _results = [];
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF060B16) : const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          'Search Users',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0B1220),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF060B16) : Colors.white,
        elevation: 0,
        surfaceTintColor: isDark ? const Color(0xFF060B16) : Colors.white,
        actions: [
          ThemeToggleButton(color: isDark ? Colors.white : Colors.black87),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _onSearch(),
                    decoration: InputDecoration(
                      hintText: "Enter name or email...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF0D1426) : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  child: const Text("Search"),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: _hasActiveFilters,
                  smallSize: 10,
                  child: IconButton(
                    onPressed: _openFilterSheet,
                    tooltip: 'Filter by location',
                    style: IconButton.styleFrom(
                      backgroundColor: _hasActiveFilters
                          ? AppColors.primary.withOpacity(0.12)
                          : (isDark ? const Color(0xFF0D1426) : Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _hasActiveFilters
                              ? AppColors.primary
                              : (isDark
                                  ? const Color(0xFF1F2A44)
                                  : Colors.grey[300]!),
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: Icon(
                      Icons.tune_rounded,
                      color: _hasActiveFilters
                          ? AppColors.primary
                          : (isDark ? Colors.white : Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (_cityFilter != null)
                      _filterChip('City: $_cityFilter',
                          () => _removeFilter(() => _cityFilter = null)),
                    if (_stateFilter != null)
                      _filterChip('State: $_stateFilter',
                          () => _removeFilter(() => _stateFilter = null)),
                    if (_countryFilter != null)
                      _filterChip('Country: $_countryFilter',
                          () => _removeFilter(() => _countryFilter = null)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingView(size: 80))
                : _error != null
                    ? Center(child: Text(_error!))
                    : !_hasSearched
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_search_rounded,
                                    size: 64,
                                    color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  "Search by name, email or location",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : _results.isEmpty
                            ? const Center(child: Text("No users found"))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: CardItem(card: _results[index]),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }

  void _removeFilter(VoidCallback clear) {
    setState(clear);
    if (_searchCtrl.text.trim().isNotEmpty || _hasActiveFilters) {
      _onSearch();
    } else {
      setState(() {
        _hasSearched = false;
        _results = [];
      });
    }
  }

  Widget _filterChip(String label, VoidCallback onRemoved) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onRemoved,
      visualDensity: VisualDensity.compact,
      deleteIconColor: Colors.grey,
    );
  }
}

class _AddressFilter {
  final String? city;
  final String? state;
  final String? country;

  const _AddressFilter({this.city, this.state, this.country});
}

class _AddressFilterSheet extends StatefulWidget {
  final _AddressFilter initial;

  const _AddressFilterSheet({required this.initial});

  @override
  State<_AddressFilterSheet> createState() => _AddressFilterSheetState();
}

class _AddressFilterSheetState extends State<_AddressFilterSheet> {
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _countryCtrl;

  @override
  void initState() {
    super.initState();
    _cityCtrl = TextEditingController(text: widget.initial.city ?? '');
    _stateCtrl = TextEditingController(text: widget.initial.state ?? '');
    _countryCtrl = TextEditingController(text: widget.initial.country ?? '');
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  String? _valueOf(TextEditingController ctrl) {
    final text = ctrl.text.trim();
    return text.isEmpty ? null : text;
  }

  void _apply() {
    Navigator.of(context).pop(_AddressFilter(
      city: _valueOf(_cityCtrl),
      state: _valueOf(_stateCtrl),
      country: _valueOf(_countryCtrl),
    ));
  }

  void _clear() {
    Navigator.of(context).pop(const _AddressFilter());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by location',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0B1220),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stateCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'State / Region',
              prefixIcon: Icon(Icons.map_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _countryCtrl,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _apply(),
            decoration: const InputDecoration(
              labelText: 'Country',
              prefixIcon: Icon(Icons.public_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
