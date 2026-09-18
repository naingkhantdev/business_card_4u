import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/card/card_provider.dart';
import '../theme/app_colors.dart';
import '../../data/vos/business_card_model.dart';
import '../widgets/card_item.dart';
import '../widgets/loading_view.dart';
import '../widgets/search_icon_button.dart';
import '../theme/wallet_tokens.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  bool _hasSearched = false;
  bool _isLoading = false;
  List<BusinessCardModel> _results = [];
  String? _error;

  String? _cityFilter;
  String? _stateFilter;
  String? _countryFilter;

  bool get _hasActiveFilters =>
      _cityFilter != null || _stateFilter != null || _countryFilter != null;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

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
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? Wallet.darkGround : const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          'Search Users',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Wallet.ink,
          ),
        ),
        backgroundColor: isDark ? Wallet.darkGround : Colors.white,
        elevation: 0,
        surfaceTintColor: isDark ? Wallet.darkGround : Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Wallet.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSearchFocused
                            ? AppColors.primary.withOpacity(.5)
                            : (isDark
                                ? Wallet.darkLine
                                : Colors.grey.withOpacity(.12)),
                        width: _isSearchFocused ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isSearchFocused
                              ? AppColors.primary.withOpacity(.08)
                              : Colors.black.withOpacity(isDark ? .18 : .05),
                          blurRadius: _isSearchFocused ? 20 : 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: _isSearchFocused
                              ? AppColors.primary
                              : (isDark
                                  ? Wallet.darkFaint
                                  : Colors.grey.shade400),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocusNode,
                            onSubmitted: (_) => _onSearch(),
                            textInputAction: TextInputAction.search,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(
                              fontSize: 14.5,
                              color: isDark ? Wallet.darkInk : Wallet.ink,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter name or email...",
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Wallet.darkFaint
                                    : Colors.grey.shade400,
                                fontSize: 14.5,
                              ),
                              // See card_page's search field: the app-wide
                              // InputDecorationTheme draws its own
                              // enabled/focused border on every field unless
                              // each variant is zeroed out here too, or it
                              // shows up as a second border inside this
                              // container's own pill border.
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Wallet.darkLine
                                      : Colors.grey.shade200,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 13,
                                  color: isDark
                                      ? Wallet.darkMuted
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SearchIconButton(
                  onTap: _onSearch,
                  isDark: isDark,
                  tooltip: 'Search',
                  filled: true,
                  icon: Icons.search_rounded,
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: _hasActiveFilters,
                  smallSize: 10,
                  child: SearchIconButton(
                    onTap: _openFilterSheet,
                    isDark: isDark,
                    tooltip: 'Filter by location',
                    active: _hasActiveFilters,
                    icon: Icons.tune_rounded,
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

    // The sheet is opened scroll-controlled, so on a short screen (landscape,
    // or portrait with the keyboard up) it has to scroll rather than run past
    // the bottom of the window.
    return SingleChildScrollView(
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
              color: isDark ? Colors.white : Wallet.ink,
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
