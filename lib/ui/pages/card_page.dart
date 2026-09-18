import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../theme/app_colors.dart';
import '../../data/vos/business_card_model.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import '../widgets/card_item.dart';
import '../widgets/image_source_sheet.dart';
import '../widgets/my_qr_panel.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/search_icon_button.dart';
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
        });
      }
    });
  }

  @override
  void dispose() {
    _bellController.dispose();
    _tabController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<BusinessCardModel> _filterCards(List<BusinessCardModel> cards) {
    var filtered = cards;

    // 1. Company Filter
    if (_selectedCompanyFilter != null) {
      filtered = filtered
          .where((c) => c.company?.name == _selectedCompanyFilter)
          .toList();
    }

    // 2. Search Query
    if (_query.isEmpty) return filtered;
    return filtered
        .where((card) =>
            card.fullName.toLowerCase().contains(_query.toLowerCase()))
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

  /// States which company the list is filtered to, since the search bar's
  /// filter icon only shows *that* something is filtered (a badge dot), not
  /// *what*. Tapping the pill itself reopens the sheet to change it; the ✕
  /// clears it without a trip through the sheet.
  Widget _buildActiveCompanyFilterPill(
      bool isDark, List<BusinessCardModel> currentTabCards) {
    final name = _selectedCompanyFilter!;
    return GestureDetector(
      onTap: () => _showCompanyFilterSheet(_companyNamesFor(currentTabCards)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(isDark ? .16 : .08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withOpacity(.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apartment_rounded,
                size: 13, color: AppColors.primary),
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
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _selectedCompanyFilter = null),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 11, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCompanyFilterSheet(List<String> companies) async {
    final result = await showModalBottomSheet<_CompanyFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CompanyFilterSheet(
        companies: companies,
        selected: _selectedCompanyFilter,
      ),
    );
    // Dismissing without picking a row (tap outside, swipe down) returns
    // null and should leave the filter exactly as it was.
    if (result == null || !mounted) return;
    setState(() => _selectedCompanyFilter = result.company);
  }

  Widget _buildCardList(
    List<BusinessCardModel> cards,
    bool isLoading,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isLoading) {
      return const Center(
        child: LoadingView(size: 90),
      );
    }

    final filtered = _filterCards(cards);

    // Auto-clear active filters if they are hiding all cards for this tab
    // (so the user sees the cards without having to manually clear)
    if (cards.isNotEmpty && filtered.isEmpty && (_query.isNotEmpty || _selectedCompanyFilter != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _query = "";
            _searchController.clear();
            _searchFocusNode.unfocus();
            _selectedCompanyFilter = null;
          });
        }
      });
    }

    final scrollChildren = <Widget>[];

    if (filtered.isEmpty) {
      final hasActiveFilter = _query.isNotEmpty || _selectedCompanyFilter != null;
      final title = hasActiveFilter
          ? 'No matching cards'
          : (cards.isNotEmpty ? 'No cards match this tab' : 'No cards yet');
      final subtitle = hasActiveFilter
          ? 'There are cards in the database, but your current search or company filter is hiding them.\nClear the filter to see them.'
          : 'Pull down to refresh or add new cards.';

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
                  color: isDark
                      ? Wallet.darkSurface
                      : AppColors.primary.withOpacity(.07),
                ),
                child: Icon(
                  hasActiveFilter ? Icons.filter_list_off_rounded : Icons.style_outlined,
                  size: 36,
                  color: AppColors.primary.withOpacity(.5),
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
                  color: isDark ? Wallet.darkFaint : Colors.black38,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
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

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(cardProvider);
        await ref.read(cardProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: scrollChildren,
      ),
    );
  }

  void _showMyQrCode(BuildContext context, BusinessCardModel? myProfileCard) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    isDark ? Wallet.darkGround : const Color(0xFFF4F7FB),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
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
                        color: isDark
                            ? Wallet.darkLine
                            : const Color(0xFFD5DDEA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'My QR Code',
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
                    'Open this when someone wants to scan your card.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Wallet.darkMuted : Colors.black54,
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
                      text: 'Create My Profile Card',
                      loading: false,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                              builder: (_) => const AddCardPage(cardType: 'user_card'),
                            ))
                            .then((created) {
                          if (created == true && context.mounted) {
                            ref.read(cardProvider.notifier).fetchCards();
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (context.mounted) {
                                AppToast.show(
                                  context,
                                  'Profile card created successfully',
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
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Wallet.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: isDark ? Wallet.darkLine : Colors.grey[300],
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
                      'Add a card',
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
                      'Snap the card or pick a photo — we fill in the details.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Wallet.darkMuted
                            : Colors.grey[600],
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
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.document_scanner_outlined,
                            color: Colors.white),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan a business card',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Fastest — reads front and back for you',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Icon(
                  Icons.edit_note,
                  color: isDark ? Wallet.darkMuted : Colors.grey[600],
                ),
                title: const Text('Enter details manually'),
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
    final front = await _captureCardSide(
      title: 'Scan the front',
      subtitle: 'Step 1 of 2 — we read the card and fill in the details for you.',
    );
    if (front == null || !mounted) return;

    XFile? back;
    if (await _askForCardBack()) {
      if (!mounted) return;
      back = await _captureCardSide(
        title: 'Scan the back',
        subtitle: 'Step 2 of 2 — whatever we find here joins the same card.',
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
      return await ImagePicker().pickImage(source: source);
    } catch (e) {
      if (!mounted) return null;
      AppToast.show(
        context,
        'Could not open the '
        '${source == ImageSource.camera ? 'camera' : 'gallery'}. '
        'You can still enter the card manually.',
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
    final wantsBack = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: isDark ? Wallet.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: isDark ? Wallet.darkLine : Colors.grey[300],
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
                        const Icon(Icons.check_circle,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Front captured',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isDark
                                ? Wallet.darkMuted
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add the back?',
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
                      'The back usually carries the address, extra numbers, and '
                      'social links the front leaves off.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Wallet.darkMuted
                            : Colors.grey[600],
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
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.flip_to_back, color: Colors.white),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan the back too',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Recommended — catches what the front misses',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Icon(
                  Icons.skip_next_outlined,
                  color: isDark ? Wallet.darkMuted : Colors.grey[600],
                ),
                title: const Text('Skip — front only'),
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
    Navigator.of(context)
        .push(MaterialPageRoute(
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

      // Make sure we are on the Saved Cards tab (in case navigation context changed)
      _tabController?.animateTo(1);

      ref.read(cardProvider.notifier).fetchCards();

      // Slight delay to ensure navigation and rebuild complete before toast
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        AppToast.show(
          context,
          'Business card created successfully',
          type: AppToastType.success,
        );
      });
    });
  }

  void _showAddOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Wallet.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  title: Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: isDark
                          ? Wallet.darkInk
                          : Wallet.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Add friend by scanning their QR code',
                    style: TextStyle(
                      color: isDark ? Wallet.darkMuted : Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search, color: AppColors.primary),
                  title: Text(
                    'Search Users',
                    style: TextStyle(
                      color: isDark
                          ? Wallet.darkInk
                          : Wallet.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Find users by name or company',
                    style: TextStyle(
                      color: isDark ? Wallet.darkMuted : Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchPage()),
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
    final mySavedCards = cardState.cards.where((c) {
      if (c.cardType != 'saved_card') return false;
      if (currentUser == null) return true;
      final creatorId = c.createdBy ?? c.user?.id;
      return creatorId == currentUser.id;
    }).toList();

    // 3. My Friend's Cards -> user_card that have accepted friendship status
    // (card_type == 'user_card' AND has accepted relation in friendships table)
    final myFriendsCards = cardState.cards.where((c) {
      if (c.cardType != 'user_card') return false;
      if (!c.isFriend) return false;
      if (currentUser != null && c.user?.id == currentUser.id) return false;
      return true;
    }).toList();

    // Auto-clear filters if they would hide all cards for the current tab
    // (prevents cards from DB not appearing due to leftover filter)
    final currentTabList = (_tabController?.index ?? 0) == 0 ? myFriendsCards : mySavedCards;
    final filteredCurrent = _filterCards(currentTabList);
    if (currentTabList.isNotEmpty && filteredCurrent.isEmpty && (_query.isNotEmpty || _selectedCompanyFilter != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _query = "";
            _searchController.clear();
            _searchFocusNode.unfocus();
            _selectedCompanyFilter = null;
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
          color: isDark ? Colors.white : Colors.black87,
        ),
        title: RichText(
          text: TextSpan(
            text: "businessCard",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Wallet.ink,
            ),
            children: const [
              TextSpan(
                text: "4U",
                style: TextStyle(color: AppColors.primary),
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
                  color: isDark
                      ? Colors.white.withOpacity(.06)
                      : Colors.black.withOpacity(.06),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  isDark ? Wallet.darkFaint : Colors.grey,
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
                color: AppColors.primary.withOpacity(.12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: "Friend's Cards"),
                Tab(text: "Saved Cards"),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showMyQrCode(context, myProfileCard),
            icon: Icon(
              Icons.qr_code_2_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: 'My QR Code',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
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
                    color: isDark ? Colors.white : Colors.black87,
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
                        color: Colors.redAccent,
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
      body: Column(
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _isSearchFocused
                                ? Icons.search_rounded
                                : Icons.search_rounded,
                            key: ValueKey(_isSearchFocused),
                            size: 20,
                            color: _isSearchFocused
                                ? AppColors.primary
                                : (isDark
                                    ? Wallet.darkFaint
                                    : Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (val) => setState(() => _query = val),
                            style: TextStyle(
                              fontSize: 14.5,
                              color: isDark ? Wallet.darkInk : Wallet.ink,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search cards...",
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Wallet.darkFaint
                                    : Colors.grey.shade400,
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
                Badge(
                  isLabelVisible: _selectedCompanyFilter != null,
                  smallSize: 10,
                  child: SearchIconButton(
                    onTap: () => _showCompanyFilterSheet(
                      _companyNamesFor(currentTabList),
                    ),
                    isDark: isDark,
                    tooltip: 'Filter by company',
                    active: _selectedCompanyFilter != null,
                    icon: Icons.tune_rounded,
                  ),
                ),
              ],
            ),
          ),

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
                _buildCardList(myFriendsCards, isCardLoading),
                _buildCardList(mySavedCards, isCardLoading),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'action_fab',
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController?.index == 0 ? 'Add Friend' : 'New Card',
          style: const TextStyle(
            color: Colors.white,
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
/// A letter avatar per company (stable per name, not per rebuild) gives rows
/// something to visually anchor on beyond a line of text — the wrap-of-chips
/// this replaced had no such landmark and read as a plain settings list. A
/// search field only earns its place once there's enough companies to be
/// worth searching.
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

  // A handful of accent tints, cycled by a hash of the name so a company's
  // avatar color is stable across rebuilds and repeat openings rather than
  // reshuffling — the letter is what varies row to row, not the palette.
  static const _avatarTints = [
    Wallet.accentLight,
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFB45309),
    Color(0xFFBE185D),
  ];

  Color _avatarTint(String name) {
    final hash = name.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return _avatarTints[hash % _avatarTints.length];
  }

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
    final companies = widget.companies;
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? companies
        : companies.where((c) => c.toLowerCase().contains(query)).toList();
    final showSearch = companies.length > _searchThreshold;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .78,
      ),
      decoration: BoxDecoration(
        color: Wallet.surfaceOf(isDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Wallet.radiusPanel),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .45 : .12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Wallet.darkLine : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(isDark ? .18 : .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by Company',
                        style: AppTheme.withFontStack(TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Wallet.darkInk : Wallet.ink,
                        )),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        companies.length == 1
                            ? '1 company'
                            : '${companies.length} companies',
                        style: AppTheme.withFontStack(TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Wallet.darkFaint : Colors.grey.shade500,
                        )),
                      ),
                    ],
                  ),
                ),
                if (widget.selected != null)
                  TextButton(
                    onPressed: () => _choose(null),
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: Text(
                      'Clear',
                      style: AppTheme.withFontStack(const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      )),
                    ),
                  ),
              ],
            ),
          ),
          if (showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? Wallet.darkGround : const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Wallet.darkLine : Colors.grey.withOpacity(.15),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded,
                        size: 18,
                        color: isDark ? Wallet.darkFaint : Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Wallet.darkInk : Wallet.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search companies',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark ? Wallet.darkFaint : Colors.grey.shade400,
                          ),
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
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color:
                                  isDark ? Wallet.darkMuted : Colors.grey.shade500),
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Flexible(
            child: companies.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'No companies available',
                        style: AppTheme.withFontStack(TextStyle(
                          color: isDark ? Wallet.darkFaint : Colors.grey.shade400,
                        )),
                      ),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      4,
                      12,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    children: [
                      _row(
                        isDark: isDark,
                        label: 'All Companies',
                        isSelected: widget.selected == null,
                        onTap: () => _choose(null),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Wallet.darkLine
                                : Colors.grey.withOpacity(.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.grid_view_rounded,
                              size: 18,
                              color:
                                  isDark ? Wallet.darkMuted : Colors.grey.shade600),
                        ),
                      ),
                      if (query.isNotEmpty && filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No companies match "${_query.trim()}"',
                              textAlign: TextAlign.center,
                              style: AppTheme.withFontStack(TextStyle(
                                color: isDark
                                    ? Wallet.darkFaint
                                    : Colors.grey.shade400,
                              )),
                            ),
                          ),
                        )
                      else
                        ...filtered.map((company) => _row(
                              isDark: isDark,
                              label: company,
                              isSelected: widget.selected == company,
                              onTap: () => _choose(company),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _avatarTint(company)
                                      .withOpacity(isDark ? .22 : .12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  company.isNotEmpty
                                      ? company[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: _avatarTint(company),
                                  ),
                                ),
                              ),
                            )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget leading,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(isDark ? .16 : .08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.primary)
                        : (isDark ? Wallet.darkInk : Wallet.ink),
                  ),
                ),
              ),
              SizedBox(
                width: 22,
                height: 22,
                child: isSelected
                    ? Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
