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
  String _query = "";
  bool _isLoading = false;
  List<BusinessCardModel> _results = [];
  String? _error;

  void _onSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _query = query;
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await ref.read(cardProvider.notifier).searchCards(query);
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
            fontWeight: FontWeight.w800,
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
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingView(size: 80))
                : _error != null
                    ? Center(child: Text(_error!))
                    : _query.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_search_rounded,
                                    size: 64,
                                    color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  "Search for people by name or email",
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
}
