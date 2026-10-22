import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_typography.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../../data/vos/business_card_model.dart';
import '../../utils/image_upload.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import '../widgets/card_item.dart';
import '../widgets/image_source_sheet.dart';
import '../widgets/my_qr_panel.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/search_icon_button.dart';
import '../widgets/profession_picker.dart';
import '../../utils/user_drawer.dart';
import 'add_card_page.dart';
import 'scan_page.dart'; // Added import
import 'search_page.dart'; // Added import
import 'friend_requests_page.dart';
import '../theme/wallet_tokens.dart';

class CardPage extends ConsumerStatefulWidget {
  const CardPage({super.key});

  @override
  ConsumerState<CardPage> createState() => _CardPageState();
}

class _CardPageState extends ConsumerState<CardPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedCompanyFilter; // null means "All"
  String? _selectedProfession; // null means "All"

  /// The server's answer for the active filters, or null when there is none
  /// yet (no filter, request still in flight, or the request failed) — in
  /// which case the list falls back to filtering what's already loaded.
  List<BusinessCardModel>? _apiResults;
  bool _isFiltering = false;

  /// Bumped on every new filter request, so an older response that lands
  /// after a newer one was sent is dropped instead of overwriting it.
  int _filterRequestId = 0;
  Timer? _queryDebounce;
  String? _lastShownMessage;
  TabController? _tabController;
  late final AnimationController _bellController;
  late final Animation<double> _bellRotation;
  int _previousNotificationCount = 0;
  bool _hasSeenInitialNotificationCount = false;

  @override
  void initState() {
    super.initState();
    _initTabController();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bellRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -.12, end: .12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: .12, end: -.10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -.10, end: .08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: .08, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeOut),
    );

    // No fetch here: watching cardProvider in build() runs its `build`, which
    // loads cards and friend requests together. Fetching again in parallel
    // races that future, and the value it returns wins — which is what made
    // the list show up only after a pull-to-refresh.
  }

  void _initTabController() {
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (mounted) {
        // Reset search + company filter when switching tabs.
        // Otherwise filters from one tab leak into the other and hide cards.
        setState(() {
          _query = "";
          _searchController.clear();
          _searchFocusNode.unfocus();
          _selectedCompanyFilter = null;
          _selectedProfession = null;
          _dropApiResults();
        });
      }
    });
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    _bellController.dispose();
    _tabController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static bool _isSavedTabCard(BusinessCardModel c, int? currentUserId) {
    if (c.cardType != 'saved_card') return false;
    if (currentUserId == null) return true;
    final creatorId = c.createdBy ?? c.user?.id;
    return creatorId == currentUserId;
  }

  static bool _isFriendsTabCard(BusinessCardModel c, int? currentUserId) {
    if (c.cardType != 'user_card') return false;
    if (!c.isFriend) return false;
    if (currentUserId != null && c.user?.id == currentUserId) return false;
    return true;
  }

  /// What one tab shows: [cards] is that tab's full list, [onTab] says
  /// whether a card belongs on it. With a filter active, the server's
  /// matches are used once they arrive; until then (or if the request
  /// failed) the loaded cards are filtered on the device.
  List<BusinessCardModel> _filterCards(List<BusinessCardModel> cards,
      bool Function(BusinessCardModel) onTab) {
    if (!_hasActiveFilter) return cards;
    final apiResults = _apiResults;
    if (apiResults != null) return apiResults.where(onTab).toList();
    return _filterLocally(cards);
  }

  /// Forgets any server answer and cancels whatever request is in flight —
  /// for every place that resets the filters. Call inside setState.
  void _dropApiResults() {
    _queryDebounce?.cancel();
    _filterRequestId++;
    _apiResults = null;
    _isFiltering = false;
  }

  int? _selectedCompanyId() {
    final name = _selectedCompanyFilter;
    if (name == null) return null;
    final cards = ref.read(cardProvider).valueOrNull?.cards ?? const [];
    for (final c in cards) {
      if (c.company?.name == name) return c.company!.id;
    }
    return null;
  }

  /// Asks the server for the cards matching the current filters. The list
  /// shows the on-device result straight away and swaps in the server's
  /// answer when it lands; the full list stays loaded throughout, so there
  /// is no spinner and nothing to refetch when the filter is cleared.
  Future<void> _runFilter() async {
    _queryDebounce?.cancel();
    final requestId = ++_filterRequestId;
    final companyId = _selectedCompanyId();

    // No filter, or a company we can't resolve to an id: nothing to ask the
    // server — filter locally rather than send a query that ignores it.
    if (!_hasActiveFilter ||
        (_selectedCompanyFilter != null && companyId == null)) {
      setState(() {
        _apiResults = null;
        _isFiltering = false;
      });
      return;
    }

    setState(() {
      _apiResults = null;
      _isFiltering = true;
    });

    final query = _query.trim();
    final results = await ref.read(cardProvider.notifier).filterCards(
          query: query.isEmpty ? null : query,
          companyId: companyId,
          profession: _selectedProfession,
        );
    if (!mounted || requestId != _filterRequestId) return;
    setState(() {
      _apiResults = results; // null on failure → local fallback
      _isFiltering = false;
    });
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _queryDebounce?.cancel();
    _queryDebounce = Timer(const Duration(milliseconds: 350), _runFilter);
  }

  List<BusinessCardModel> _filterLocally(List<BusinessCardModel> cards) {
    var filtered = cards;

    // 1. Company Filter
    if (_selectedCompanyFilter != null) {
      filtered = filtered
          .where((c) => c.company?.name == _selectedCompanyFilter)
          .toList();
    }

    // 2. Profession Filter
    final profession = _selectedProfession?.toLowerCase();
    if (profession != null) {
      filtered = filtered
          .where((c) => c.profession?.toLowerCase() == profession)
          .toList();
    }

    // 3. Search Query — name or position, same as the server's.
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return filtered;
    return filtered
        .where((card) =>
            card.fullName.toLowerCase().contains(query) ||
            card.position.toLowerCase().contains(query))
        .toList();
  }

  /// Company names on the given tab, for the filter sheet's chip list.
  List<String> _companyNamesFor(List<BusinessCardModel> cards) {
    return cards
        .where((c) => c.company != null)
        .map((c) => c.company!.name)
        .toSet()
        .toList()
      ..sort();
  }

  /// Recomputes this tab's card list straight from whatever `cardProvider`
  /// holds right now — used right after a refresh so the filter sheet's
  /// company list reflects what was just fetched rather than whatever
  /// build() last saw. Mirrors the tab split in build(); kept separate
  /// because that method also needs both tabs' lists at once for the
  /// TabBarView, not just the active one.
  List<BusinessCardModel> _currentTabCards() {
    final cardState = ref.read(cardProvider).valueOrNull ?? CardState();
    final userId = ref.read(authProvider).valueOrNull?.currentUser?.id;
    final onTab = (_tabController?.index ?? 0) == 0
        ? (BusinessCardModel c) => _isFriendsTabCard(c, userId)
        : (BusinessCardModel c) => _isSavedTabCard(c, userId);
    return cardState.cards.where(onTab).toList();
  }

  /// States which company the list is filtered to, since the search bar's
  /// filter icon only shows *that* something is filtered (a badge dot), not
  /// *what*. Tapping the pill itself reopens the sheet to change it; the ✕
  /// clears it without a trip through the sheet.
  Widget _buildActiveCompanyFilterPill(
      bool isDark, List<BusinessCardModel> currentTabCards) {
    final name = _selectedCompanyFilter!;
    return GestureDetector(
      onTap: _showCompanyFilterSheet,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: Wallet.accentOf(isDark).withOpacity(isDark ? .16 : .08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Wallet.accentOf(isDark).withOpacity(.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apartment_rounded,
                size: 13, color: Wallet.accentOf(isDark)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Wallet.accentOf(isDark),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() => _selectedCompanyFilter = null);
                _runFilter();
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Wallet.accentOf(isDark).withOpacity(.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    size: 11, color: Wallet.accentOf(isDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens straight from the cards already in memory. It used to refetch
  /// first, which put the whole list back into its loading state and made
  /// every tap on the filter wait on the network; pull-to-refresh is the
  /// place to pick up companies added elsewhere.
  Future<void> _showCompanyFilterSheet() async {
    final result = await showModalBottomSheet<_CompanyFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CompanyFilterSheet(
        companies: _companyNamesFor(_currentTabCards()),
        selected: _selectedCompanyFilter,
      ),
    );
    // Dismissing without picking a row (tap outside, swipe down) returns
    // null and should leave the filter exactly as it was.
    if (result == null || !mounted) return;
    setState(() => _selectedCompanyFilter = result.company);
    _runFilter();
  }

  bool get _hasActiveFilter =>
      _query.isNotEmpty ||
      _selectedCompanyFilter != null ||
      _selectedProfession != null;

  /// One-tap profession chips under the search bar, built from the
  /// professions the cards on this tab actually have — so a profession
  /// someone adds at sign-up gets a chip as soon as a card carries it. Each
  /// shows its count, most common first, and none can lead to an empty list.
  Widget _buildProfessionChips(
      bool isDark, List<BusinessCardModel> currentTabCards) {
    final l10n = AppLocalizations.of(context)!;
    final countsByKey = <String, int>{};
    final spelling = <String, String>{};
    for (final c in currentTabCards) {
      final name = c.profession?.trim() ?? '';
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      countsByKey[key] = (countsByKey[key] ?? 0) + 1;
      spelling.putIfAbsent(key, () => name);
    }
    if (countsByKey.isEmpty) return const SizedBox.shrink();
    final counts = {
      for (final key in countsByKey.keys.toList()
        ..sort((a, b) => countsByKey[b]!.compareTo(countsByKey[a]!)))
        spelling[key]!: countsByKey[key]!,
    };

    Widget chip({
      required String label,
      required IconData icon,
      required bool selected,
      required VoidCallback onTap,
      int? count,
    }) {
      final fg = selected
          ? Wallet.onAccentOf(isDark)
          : (isDark ? Wallet.darkInk : Wallet.ink);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: selected
              ? Wallet.accentOf(isDark)
              : (Wallet.surfaceOf(isDark)),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? Wallet.accentOf(isDark)
                      : (Wallet.lineOf(isDark)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Wallet.onAccentOf(isDark).withOpacity(.8)
                            : (Wallet.faintOf(isDark)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(
            label: l10n.cardPageAllProfessions,
            icon: Icons.grid_view_rounded,
            selected: _selectedProfession == null,
            onTap: () {
              setState(() => _selectedProfession = null);
              _runFilter();
            },
          ),
          for (final entry in counts.entries)
            chip(
              label: professionLabel(l10n, entry.key),
              icon: professionIcon(entry.key),
              count: entry.value,
              selected: _selectedProfession?.toLowerCase() ==
                  entry.key.toLowerCase(),
              // Tapping the selected chip again clears it.
              onTap: () {
                final isSelected = _selectedProfession?.toLowerCase() ==
                    entry.key.toLowerCase();
                setState(() =>
                    _selectedProfession = isSelected ? null : entry.key);
                _runFilter();
              },
            ),
        ],
      ),
    );
  }

  /// A thin bar while the server is filtering — the list itself stays put.
  /// Same height either way, so the list doesn't jump when it appears.
  Widget _buildFilterProgress() => SizedBox(
        height: 2,
        child: _isFiltering
            ? LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: Wallet.accentOf(Theme.of(context).brightness == Brightness.dark),
              )
            : null,
      );

  Widget _buildCardList(
    List<BusinessCardModel> cards,
    bool isLoading,
    bool Function(BusinessCardModel) onTab,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    if (isLoading) {
      return const Center(
        child: LoadingView(size: 90),
      );
    }

    // No auto-clear here. This runs for both tabs on every build, including
    // the one off screen, so a filter that matched nothing on the hidden tab
    // used to reset the filter just picked on the visible one. build() does
    // the auto-clear, for the current tab only.
    final filtered = _filterCards(cards, onTab);

    final scrollChildren = <Widget>[];

    if (filtered.isEmpty) {
      final hasActiveFilter = _hasActiveFilter;
      final title = hasActiveFilter
          ? l10n.cardPageNoMatchingCardsTitle
          : (cards.isNotEmpty ? l10n.cardPageNoCardsThisTabTitle : l10n.cardPageNoCardsYetTitle);
      final subtitle = hasActiveFilter
          ? l10n.cardPageFilterHidingCardsSubtitle
          : l10n.cardPagePullToRefreshSubtitle;

      scrollChildren.add(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Wallet.tintOf(isDark),
                ),
                child: Icon(
                  hasActiveFilter ? Icons.filter_list_off_rounded : Icons.style_outlined,
                  size: 36,
                  color: Wallet.accentOf(isDark).withOpacity(.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Wallet.darkInk
                      : Wallet.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Wallet.faintOf(isDark),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    } else if (Responsive.isDesktop(context)) {
      // A single-column list stretched across a browser window reads as
      // mostly empty space. A wrapped multi-column layout uses that width
      // the way a real card directory would, without forcing every card into
      // a uniform grid cell height.
      scrollChildren.add(
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: filtered
              .map((card) => SizedBox(width: 340, child: CardItem(card: card)))
              .toList(),
        ),
      );
    } else {
      scrollChildren.addAll(
        filtered.map(
          (card) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CardItem(card: card),
          ),
        ),
      );
    }

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: [0.0, 0.04, 0.94, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cardProvider);
          await ref.read(cardProvider.future);
          // The server's filtered answer is as stale as the list was.
          if (mounted && _hasActiveFilter) _runFilter();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: scrollChildren,
        ),
      ),
    );
  }

  void _showMyQrCode(BuildContext context, BusinessCardModel? myProfileCard) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.56,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color:
                    Wallet.groundOf(isDark),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(Wallet.radiusPanel)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Wallet.lineOf(isDark),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.cardPageMyQrCodeTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? Wallet.darkInk
                          : Wallet.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.cardPageMyQrCodeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Wallet.mutedOf(isDark),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: MyQrPanel(profileCard: myProfileCard),
                    ),
                  ),
                  if (myProfileCard == null) ...[
                    const SizedBox(height: 20),
                    AppPrimaryButton(
                      text: l10n.cardPageCreateProfileCard,
                      loading: false,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context)
                            .push(AppPageRoute(
                              builder: (_) => const AddCardPage(cardType: 'user_card'),
                            ))
                            .then((created) {
                          if (created == true && context.mounted) {
                            ref.read(cardProvider.notifier).fetchCards();
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (context.mounted) {
                                AppToast.show(
                                  context,
                                  l10n.cardPageProfileCardCreatedSuccess,
                                  type: AppToastType.success,
                                );
                              }
                            });
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Entry point for a new saved card. Scanning is offered first and styled as
  /// the primary path — photographing a card someone just handed over beats
  /// retyping it, and the manual form is still one tap away.
  void _showNewCardOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Wallet.surfaceOf(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Wallet.radiusPanel)),
      ),
      // Scroll-controlled, or the default 9/16-of-the-screen cap cuts this off
      // in landscape.
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Wallet.lineOf(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cardPageAddACardTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Wallet.darkInk
                            : Wallet.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.cardPageAddACardSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Wallet.mutedOf(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _startCardScan();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Wallet.accentOf(isDark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.document_scanner_outlined,
                            color: Wallet.onAccentOf(isDark)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.cardPageScanBusinessCard,
                                style: TextStyle(
                                  color: Wallet.onAccentOf(isDark),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.cardPageScanFastestSubtitle,
                                style: TextStyle(
                                  color: Wallet.onAccentOf(isDark).withOpacity(.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: Wallet.onAccentOf(isDark)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Icon(
                  Icons.edit_note,
                  color: Wallet.mutedOf(isDark),
                ),
                title: Text(l10n.cardPageEnterDetailsManually),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAddCard();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Gets the card's photos — shot now or picked from the gallery — then opens
  /// the form, which reads both sides.
  ///
  /// The back is asked for right after the front rather than left to the form:
  /// it routinely carries the address, extra numbers, and social links, and the
  /// user is still holding the card at this exact moment. Skipping is one tap,
  /// and the form can still add a back photo later either way.
  Future<void> _startCardScan() async {
    final l10n = AppLocalizations.of(context)!;
    final front = await _captureCardSide(
      title: l10n.cardPageScanFrontTitle,
      subtitle: l10n.cardPageScanFrontSubtitle,
    );
    if (front == null || !mounted) return;

    XFile? back;
    if (await _askForCardBack()) {
      if (!mounted) return;
      back = await _captureCardSide(
        title: l10n.cardPageScanBackTitle,
        subtitle: l10n.cardPageScanBackSubtitle,
      );
    }
    if (!mounted) return;

    _openAddCard(frontImageFile: front, backImageFile: back);
  }

  /// Asks where one side's photo should come from and returns it, or null when
  /// the user backs out or the picker could not be opened.
  Future<XFile?> _captureCardSide({
    required String title,
    required String subtitle,
  }) async {
    final source = await showImageSourceSheet(
      context,
      title: title,
      subtitle: subtitle,
    );
    if (source == null || !mounted) return null;

    try {
      return await pickImageForUpload(source, UploadImageKind.card);
    } catch (e) {
      if (!mounted) return null;
      final l10n = AppLocalizations.of(context)!;
      AppToast.show(
        context,
        l10n.cardPageImageSourceOpenFailed(
          source == ImageSource.camera
              ? l10n.cardPageSourceCamera
              : l10n.cardPageSourceGallery,
        ),
        type: AppToastType.error,
      );
      return null;
    }
  }

  /// Offers the back of the card between the two capture steps. Adding it is
  /// the recommended path; dismissing the sheet counts as skipping, because a
  /// front-only card is a perfectly good result.
  Future<bool> _askForCardBack() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final wantsBack = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Wallet.surfaceOf(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Wallet.radiusPanel)),
      ),
      // See above: the default sheet cap is too short for this in landscape.
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Wallet.lineOf(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Wallet.accentOf(isDark)),
                        const SizedBox(width: 6),
                        Text(
                          l10n.cardPageFrontCapturedLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: Wallet.mutedOf(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.cardPageAddBackQuestion,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Wallet.darkInk
                            : Wallet.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.cardPageAddBackSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Wallet.mutedOf(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(sheetContext).pop(true),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Wallet.accentOf(isDark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flip_to_back, color: Wallet.onAccentOf(isDark)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.cardPageScanBackTooTitle,
                                style: TextStyle(
                                  color: Wallet.onAccentOf(isDark),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.cardPageScanBackTooSubtitle,
                                style: TextStyle(
                                  color: Wallet.onAccentOf(isDark).withOpacity(.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: Wallet.onAccentOf(isDark)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Icon(
                  Icons.skip_next_outlined,
                  color: Wallet.mutedOf(isDark),
                ),
                title: Text(l10n.cardPageSkipFrontOnly),
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    return wantsBack ?? false;
  }

  /// Opens the add-card form and refreshes the Saved Cards tab on success.
  void _openAddCard({XFile? frontImageFile, XFile? backImageFile}) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context)
        .push(AppPageRoute(
          builder: (_) => AddCardPage(
            frontImageFile: frontImageFile,
            backImageFile: backImageFile,
          ),
        ))
        .then((created) {
      if (created != true) return;
      if (!mounted) return;

      // Clear any active search/company filter so the new + existing saved cards are visible
      _query = "";
      _searchController.clear();
      _searchFocusNode.unfocus();
      _selectedCompanyFilter = null;
      _selectedProfession = null;
      _dropApiResults();

      // Make sure we are on the Saved Cards tab (in case navigation context changed)
      _tabController?.animateTo(1);

      ref.read(cardProvider.notifier).fetchCards();

      // Slight delay to ensure navigation and rebuild complete before toast
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        AppToast.show(
          context,
          l10n.cardPageBusinessCardCreatedSuccess,
          type: AppToastType.success,
        );
      });
    });
  }

  void _showAddOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Wallet.surfaceOf(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Wallet.radiusPanel)),
      ),
      // Two tiles with subtitles are taller than the default sheet cap allows
      // in landscape.
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Wrap(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.qr_code_scanner, color: Wallet.accentOf(isDark)),
                  title: Text(
                    l10n.cardPageScanQrCodeTitle,
                    style: TextStyle(
                      color: isDark
                          ? Wallet.darkInk
                          : Wallet.ink,
                    ),
                  ),
                  subtitle: Text(
                    l10n.cardPageScanQrCodeSubtitle,
                    style: TextStyle(
                      color: Wallet.mutedOf(isDark),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      AppPageRoute(builder: (_) => const ScanPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.search, color: Wallet.accentOf(isDark)),
                  title: Text(
                    l10n.cardPageSearchUsersTitle,
                    style: TextStyle(
                      color: isDark
                          ? Wallet.darkInk
                          : Wallet.ink,
                    ),
                  ),
                  subtitle: Text(
                    l10n.cardPageSearchUsersSubtitle,
                    style: TextStyle(
                      color: Wallet.mutedOf(isDark),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      AppPageRoute(builder: (_) => const SearchPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoMessage(String message) {
    AppToast.show(context, message, type: AppToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    if (_tabController == null) {
      _initTabController();
    }

    final cardState = ref.watch(cardProvider).valueOrNull ?? CardState();
    final isCardLoading = ref.watch(cardProvider).isLoading;
    final notificationCount = cardState.friendRequests.length;
    if (!_hasSeenInitialNotificationCount) {
      _previousNotificationCount = notificationCount;
      _hasSeenInitialNotificationCount = true;
    } else if (notificationCount > _previousNotificationCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _bellController.forward(from: 0);
        }
      });
      _previousNotificationCount = notificationCount;
    } else if (notificationCount != _previousNotificationCount) {
      _previousNotificationCount = notificationCount;
    }

    final authState = ref.watch(authProvider).valueOrNull ?? AuthState();
    final pendingMessage = authState.pendingMessage;
    if (pendingMessage != null && pendingMessage != _lastShownMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final message = ref.read(authProvider.notifier).consumePendingMessage();
        if (message == null) return;
        _lastShownMessage = message;
        _showInfoMessage(message);
      });
    } else if (pendingMessage == null) {
      _lastShownMessage = null;
    }

    final currentUser = authState.currentUser;
    BusinessCardModel? myProfileCard;
    if (currentUser != null) {
      final userEmail = (currentUser.email ?? '').trim().toLowerCase();
      try {
        myProfileCard = cardState.cards.firstWhere((c) {
          if (c.cardType != 'user_card') return false;

          // Best match: by ownership (user.id or createdBy)
          if (c.user?.id == currentUser.id) return true;
          if (c.createdBy == currentUser.id) return true;

          // Fallback: email match (legacy)
          if (userEmail.isNotEmpty &&
              c.emails.any((e) => e.trim().toLowerCase() == userEmail)) {
            return true;
          }
          return false;
        });
      } catch (_) {
        myProfileCard = null;
      }

      // Fallback for QR: any owned card that has qrCodeData (so QR modal can show even if no user_card yet)
      if (myProfileCard == null) {
        try {
          myProfileCard = cardState.cards.firstWhere((c) {
            final isOwned = (c.user?.id == currentUser.id) ||
                (c.createdBy == currentUser.id) ||
                (userEmail.isNotEmpty && c.emails.any((e) => e.trim().toLowerCase() == userEmail));
            final hasQrData = (c.qrCodeData != null && c.qrCodeData!.trim().isNotEmpty);
            return isOwned && hasQrData;
          });
        } catch (_) {
          myProfileCard = null;
        }
      }

      myProfileCard ??= BusinessCardModel(
          id: 0,
          fullName: currentUser.name,
          position: 'Member',
          phones: const [],
          emails: [currentUser.email ?? ''],
          addresses: const [],
          user: currentUser,
          cardType: 'user_card',
          qrCodeData: 'user-${currentUser.id}-temp-qr',
          isFriend: false,
          friendStatus: 'none',
          friendRequestStatus: 'none',
        );
    }

    // 2. My Saved Cards -> Manual entries created by me ('saved_card')
    // Show only if type = saved_card AND (createdBy or user.id) matches the logged-in user.
    final userId = currentUser?.id;
    bool onSavedTab(BusinessCardModel c) => _isSavedTabCard(c, userId);
    bool onFriendsTab(BusinessCardModel c) => _isFriendsTabCard(c, userId);

    final mySavedCards = cardState.cards.where(onSavedTab).toList();

    // 3. My Friend's Cards -> user_card that have accepted friendship status
    // (card_type == 'user_card' AND has accepted relation in friendships table)
    final myFriendsCards = cardState.cards.where(onFriendsTab).toList();

    // Auto-clear filters if they would hide all cards for the current tab
    // (prevents cards from DB not appearing due to leftover filter). Not
    // while the server is still answering — the list is mid-update then.
    final isFriendsTab = (_tabController?.index ?? 0) == 0;
    final currentTabList = isFriendsTab ? myFriendsCards : mySavedCards;
    final filteredCurrent = _filterCards(
        currentTabList, isFriendsTab ? onFriendsTab : onSavedTab);
    if (currentTabList.isNotEmpty &&
        filteredCurrent.isEmpty &&
        _hasActiveFilter &&
        !_isFiltering) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _query = "";
            _searchController.clear();
            _searchFocusNode.unfocus();
            _selectedCompanyFilter = null;
            _selectedProfession = null;
            _dropApiResults();
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: isDark ? Wallet.darkGround : AppColors.surface,
      drawer: const UserDrawer(),
      appBar: AppBar(
        backgroundColor: isDark ? Wallet.darkGround : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: Wallet.inkOf(isDark),
        ),
        title: RichText(
          text: TextSpan(
            text: "businessCard",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Wallet.inkOf(isDark),
            ),
            children: [
              TextSpan(
                text: "4U",
                style: TextStyle(color: Wallet.accentOf(isDark)),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Wallet.lineOf(isDark),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              // Start at the page's 16px margin rather than Material 3's
              // default 52px offset, with room between the two tabs.
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 18),
              labelColor: Wallet.accentOf(isDark),
              unselectedLabelColor:
                  Wallet.faintOf(isDark),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
              ),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Wallet.accentOf(isDark).withOpacity(.12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              // The pill spans nearly the whole tab, so the label has ~16px
              // of air on each side instead of hugging its edges.
              indicatorPadding:
                  const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: [
                Tab(text: l10n.cardPageFriendsCardsTab),
                Tab(text: l10n.cardPageSavedCardsTab),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showMyQrCode(context, myProfileCard),
            icon: Icon(
              Icons.qr_code_2_rounded,
              color: Wallet.inkOf(isDark),
            ),
            tooltip: l10n.cardPageMyQrCodeTitle,
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => const FriendRequestsPage(),
                ),
              ).then((_) {
                if (!context.mounted) return;
                ref.read(cardProvider.notifier).fetchFriendRequests();
                ref.read(cardProvider.notifier).fetchCards();
              });
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _bellRotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _bellRotation.value,
                      alignment: Alignment.topCenter,
                      child: child,
                    );
                  },
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Wallet.inkOf(isDark),
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Wallet.danger,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              isDark ? Wallet.darkGround : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        notificationCount > 99 ? '99+' : '$notificationCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 1100 : double.infinity,
          ),
          child: Column(
        children: [
          /// ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Wallet.surfaceOf(isDark),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSearchFocused
                            ? Wallet.accentOf(isDark).withOpacity(.5)
                            : (Wallet.lineOf(isDark)),
                        width: _isSearchFocused ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isSearchFocused
                              ? Wallet.accentOf(isDark).withOpacity(.08)
                              : Colors.black.withOpacity(isDark ? .18 : .05),
                          blurRadius: _isSearchFocused ? 20 : 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _isSearchFocused
                                ? Icons.search_rounded
                                : Icons.search_rounded,
                            key: ValueKey(_isSearchFocused),
                            size: 20,
                            color: _isSearchFocused
                                ? Wallet.accentOf(isDark)
                                : (Wallet.faintOf(isDark)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onQueryChanged,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: isDark ? Wallet.darkInk : Wallet.ink,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.cardPageSearchHint,
                              hintStyle: TextStyle(
                                color: Wallet.faintOf(isDark),
                                fontSize: 14.5,
                              ),
                              // The app-wide InputDecorationTheme draws its
                              // own enabled/focused OutlineInputBorder on
                              // every field; left unset, that shows up as a
                              // second border inside this container's own
                              // pill border. All variants have to be zeroed
                              // out, not just `border`, since the theme's
                              // more specific ones take precedence over it.
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
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _query = "");
                              _runFilter();
                              _searchFocusNode.unfocus();
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Wallet.darkLine : Wallet.iconSoft,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 13,
                                  color: Wallet.mutedOf(isDark),
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
                Badge(
                  isLabelVisible: _selectedCompanyFilter != null,
                  smallSize: 10,
                  child: SearchIconButton(
                    onTap: _showCompanyFilterSheet,
                    isDark: isDark,
                    tooltip: l10n.cardPageFilterByCompanyTooltip,
                    active: _selectedCompanyFilter != null,
                    icon: Icons.tune_rounded,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildProfessionChips(isDark, currentTabList),
          ),
          _buildFilterProgress(),

          if (_selectedCompanyFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildActiveCompanyFilterPill(isDark, currentTabList),
              ),
            ),

          /// ================= TABS VIEW =================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCardList(myFriendsCards, isCardLoading, onFriendsTab),
                _buildCardList(mySavedCards, isCardLoading, onSavedTab),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'action_fab',
        backgroundColor: Wallet.accentOf(isDark),
        elevation: 4,
        icon: Icon(Icons.add, color: Wallet.onAccentOf(isDark)),
        label: Text(
          _tabController?.index == 0 ? l10n.cardPageAddFriendFabLabel : l10n.cardPageNewCardFabLabel,
          style: TextStyle(
            color: Wallet.onAccentOf(isDark),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        onPressed: () {
          if (_tabController?.index == 0) {
            _showAddOptions(context);
          } else {
            _showNewCardOptions();
          }
        },
      ),
    );
  }
}

/// `null` company means "All Companies" — distinct from the sheet being
/// dismissed without a choice, which [_CompanyFilterSheet] reports by not
/// popping a value at all.
class _CompanyFilterResult {
  final String? company;
  const _CompanyFilterResult(this.company);
}

/// The "Filter by Company" sheet opened from the Cards page search bar.
///
/// As little as possible: a small title, a search field only once there are
/// enough companies to need one, and a bare list of names. Only the chosen
/// row is marked (accent text and a check); picking a row applies it.
class _CompanyFilterSheet extends StatefulWidget {
  final List<String> companies;
  final String? selected;

  const _CompanyFilterSheet({required this.companies, required this.selected});

  @override
  State<_CompanyFilterSheet> createState() => _CompanyFilterSheetState();
}

class _CompanyFilterSheetState extends State<_CompanyFilterSheet> {
  static const _searchThreshold = 6;

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _choose(String? company) =>
      Navigator.of(context).pop(_CompanyFilterResult(company));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final ink = Wallet.inkOf(isDark);
    final faint = Wallet.faintOf(isDark);
    final line = Wallet.lineOf(isDark);
    final accent = Wallet.accentOf(isDark);

    final companies = widget.companies;
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? companies
        : companies.where((c) => c.toLowerCase().contains(query)).toList();
    final showSearch = companies.length > _searchThreshold;

    Widget message(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.secondary(
                TextStyle(fontSize: 14, color: faint),
              ),
            ),
          ),
        );

    // At most 60% of the screen, however many companies there are — the
    // list scrolls inside. With the keyboard up (searching), the sheet sits
    // on top of it and shrinks to whatever room is left above it.
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final roomAboveKeyboard =
        media.size.height - keyboard - media.padding.top - 24;
    final maxHeight = keyboard > 0
        ? roomAboveKeyboard
        : media.size.height * .6;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Wallet.surfaceOf(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Wallet.radiusPanel)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          // Header: the title, and Clear when there's something to clear.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.cardPageFilterByCompanySheetTitle,
                    style: AppTypography.primary(TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    )),
                  ),
                ),
                if (widget.selected != null)
                  TextButton(
                    onPressed: () => _choose(null),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      l10n.cardPageClearFilter,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: AppTypography.secondary(
                  TextStyle(fontSize: 14.5, color: ink),
                ),
                decoration: InputDecoration(
                  hintText: l10n.cardPageSearchCompaniesHint,
                  hintStyle: AppTypography.secondary(
                    TextStyle(fontSize: 14.5, color: faint),
                  ),
                  prefixIcon:
                      Icon(Icons.search_rounded, size: 20, color: faint),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: faint),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                  // A soft tint, no border — the quietest way to say
                  // "type here".
                  filled: true,
                  fillColor: Wallet.tintOf(isDark),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),

          Flexible(
            child: companies.isEmpty
                ? message(l10n.cardPageNoCompaniesAvailable)
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 12,
                    ),
                    children: [
                      _row(
                        isDark: isDark,
                        label: l10n.cardPageAllCompaniesLabel,
                        isSelected: widget.selected == null,
                        onTap: () => _choose(null),
                      ),
                      if (query.isNotEmpty && filtered.isEmpty)
                        message(
                            l10n.cardPageNoCompaniesMatchQuery(_query.trim()))
                      else
                        for (final company in filtered)
                          _row(
                            isDark: isDark,
                            label: company,
                            isSelected: widget.selected == company,
                            onTap: () => _choose(company),
                          ),
                    ],
                  ),
          ),
        ],
      ),
      ),
    );
  }

  /// One bare row: just the name. The chosen one turns accent and gets a
  /// check; the rest carry nothing extra.
  Widget _row({
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final accent = Wallet.accentOf(isDark);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.secondary(TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? accent : Wallet.inkOf(isDark),
                  )),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 12),
                Icon(Icons.check_rounded, size: 20, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
