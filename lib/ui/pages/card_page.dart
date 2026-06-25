import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../network/image_url.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../../data/vos/business_card_model.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import '../widgets/card_item.dart';
import '../widgets/my_qr_panel.dart';
import '../widgets/app_primary_button.dart';
import '../../utils/user_drawer.dart';
import 'add_card_page.dart';
import 'company_select_page.dart';
import 'scan_page.dart'; // Added import
import 'search_page.dart'; // Added import
import 'card_detail_page.dart'; // Added import
import 'friend_requests_page.dart';

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

    Future.microtask(() {
      if (!mounted) return;
      ref.read(cardProvider.notifier).fetchCards();
      ref.read(cardProvider.notifier).fetchFriendRequests();
    });
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

  Widget _buildCompanyFilter(List<BusinessCardModel> cards) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final companies = cards
        .where((c) => c.company != null)
        .map((c) => c.company!.name)
        .toSet()
        .toList()
      ..sort();

    final hasFilter = _selectedCompanyFilter != null;

    // Hide filter control when no companies on this tab and nothing is filtered
    if (companies.isEmpty && !hasFilter) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCompanyFilterSheet(companies),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: hasFilter
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF0D1426) : Colors.white),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: hasFilter
                      ? AppColors.primary
                      : (isDark
                          ? const Color(0xFF1F2A44)
                          : Colors.grey.withOpacity(.18)),
                ),
                boxShadow: hasFilter
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasFilter ? Icons.business_rounded : Icons.tune_rounded,
                    size: 15,
                    color: hasFilter
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF98A7C2)
                            : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasFilter ? _selectedCompanyFilter! : 'Filter',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasFilter
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFF98A7C2)
                              : Colors.grey.shade600),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _selectedCompanyFilter = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCompanyFilterSheet(List<String> companies) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1220) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A3550)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Company',
                        style: AppTheme.withFontStack(TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFEAF1FF)
                              : const Color(0xFF0B1220),
                        )),
                      ),
                      if (_selectedCompanyFilter != null)
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedCompanyFilter = null);
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'Clear',
                            style: AppTheme.withFontStack(TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            )),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (companies.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No companies available',
                          style: AppTheme.withFontStack(TextStyle(
                            color: isDark
                                ? const Color(0xFF6B7A99)
                                : Colors.grey.shade400,
                          )),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: companies.map((company) {
                        final isSelected = _selectedCompanyFilter == company;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCompanyFilter =
                                isSelected ? null : company);
                            setSheetState(() {});
                            Navigator.pop(ctx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? const Color(0xFF0D1426)
                                      : const Color(0xFFF4F7FB)),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? const Color(0xFF1F2A44)
                                        : Colors.grey.withOpacity(.18)),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(Icons.check_rounded,
                                      size: 13, color: Colors.white),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  company,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? const Color(0xFF98A7C2)
                                            : Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardList(
    List<BusinessCardModel> cards,
    bool isLoading, {
    Widget? header,
  }) {
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

    // The vertical scrollable content now includes the header (company filter)
    // so vertical pull-to-refresh works even when starting the gesture over
    // the horizontal scrolling filter area.
    final scrollChildren = <Widget>[];

    if (header != null) {
      scrollChildren.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: header,
        ),
      );
    }

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
                      ? const Color(0xFF0D1426)
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
                      ? const Color(0xFFEAF1FF)
                      : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF6B7A99) : Colors.black38,
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
        await Future.wait([
          ref.read(cardProvider.notifier).fetchCards(),
          ref.read(cardProvider.notifier).fetchFriendRequests(),
        ]);
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
                    isDark ? const Color(0xFF060B16) : const Color(0xFFF4F7FB),
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
                            ? const Color(0xFF2A3550)
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
                          ? const Color(0xFFEAF1FF)
                          : const Color(0xFF0B1220),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open this when someone wants to scan your card.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? const Color(0xFF98A7C2) : Colors.black54,
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

  void _showAddOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0D1426) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                title: Text(
                  'Scan QR Code',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFEAF1FF)
                        : const Color(0xFF0B1220),
                  ),
                ),
                subtitle: Text(
                  'Add friend by scanning their QR code',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF98A7C2) : Colors.black54,
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
                        ? const Color(0xFFEAF1FF)
                        : const Color(0xFF0B1220),
                  ),
                ),
                subtitle: Text(
                  'Find users by name or company',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF98A7C2) : Colors.black54,
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
    final themeMode = ref.watch(themeProvider).valueOrNull ?? ThemeMode.system;
    final isThemeDark = themeMode == ThemeMode.dark;
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
      backgroundColor: isDark ? const Color(0xFF060B16) : AppColors.surface,
      drawer: const UserDrawer(),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF060B16) : Colors.white,
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
              color: isDark ? Colors.white : const Color(0xFF1F2937),
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
                  isDark ? const Color(0xFF6B7A99) : Colors.grey,
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
                              isDark ? const Color(0xFF060B16) : Colors.white,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1426) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSearchFocused
                      ? AppColors.primary.withOpacity(.5)
                      : (isDark
                          ? const Color(0xFF1F2A44)
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
                              ? const Color(0xFF6B7A99)
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
                        color: isDark
                            ? const Color(0xFFEAF1FF)
                            : const Color(0xFF0B1220),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search cards...",
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF6B7A99)
                              : Colors.grey.shade400,
                          fontSize: 14.5,
                        ),
                        border: InputBorder.none,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF2A3550)
                                : Colors.grey.shade200,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 13,
                            color: isDark
                                ? const Color(0xFF98A7C2)
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

          /// ================= TABS VIEW =================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCardList(
                  myFriendsCards,
                  isCardLoading,
                  header: _buildCompanyFilter(myFriendsCards),
                ),
                _buildCardList(
                  mySavedCards,
                  isCardLoading,
                  header: _buildCompanyFilter(mySavedCards),
                ),
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
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AddCardPage()))
                .then((created) {
              if (created == true) {
                if (!context.mounted) return;

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
                  if (context.mounted) {
                    AppToast.show(
                      context,
                      'Business card created successfully',
                      type: AppToastType.success,
                    );
                  }
                });
              }
            });
          }
        },
      ),
    );
  }
}
