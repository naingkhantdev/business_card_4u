import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/card/card_provider.dart';
import '../../network/image_url.dart';
import '../responsive/responsive.dart';
import '../../data/vos/business_card_model.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import '../theme/app_page_route.dart';
import '../theme/wallet_tokens.dart';
import 'card_detail_page.dart';
import 'search_page.dart';

class FriendRequestsPage extends ConsumerStatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  ConsumerState<FriendRequestsPage> createState() =>
      _FriendRequestsPageState();
}

class _FriendRequestsPageState extends ConsumerState<FriendRequestsPage> {
  bool _isLoading = true;
  final Set<int> _acceptedIds = <int>{};
  final Set<int> _processingIds = <int>{};
  List<BusinessCardModel> _requests = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRequests);
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    await ref.read(cardProvider.notifier).fetchFriendRequests();

    if (!mounted) return;

    final requests =
        ref.read(cardProvider).valueOrNull?.friendRequests ?? [];
    setState(() {
      _requests = List<BusinessCardModel>.from(requests);
      _acceptedIds.removeWhere((id) => !_requests.any((card) => card.id == id));
      _isLoading = false;
    });
  }

  Future<void> _acceptRequest(int cardId) async {
    setState(() => _processingIds.add(cardId));

    final result =
        await ref.read(cardProvider.notifier).acceptFriendRequest(cardId);

    if (!mounted) return;

    setState(() {
      _processingIds.remove(cardId);
      if (result.isSuccess) {
        _acceptedIds.add(cardId);
      }
    });

    final l10n = AppLocalizations.of(context)!;
    if (result.isSuccess) {
      AppToast.show(context, l10n.friendRequestsAcceptedToast, type: AppToastType.success);
    } else {
      AppToast.show(context, result.message ?? l10n.friendRequestsAcceptFailed, type: AppToastType.error);
    }
  }

  Future<void> _rejectRequest(int cardId) async {
    setState(() => _processingIds.add(cardId));

    final result =
        await ref.read(cardProvider.notifier).rejectFriendRequest(cardId);

    if (!mounted) return;

    setState(() {
      _processingIds.remove(cardId);
      if (result.isSuccess) {
        _acceptedIds.remove(cardId);
        _requests.removeWhere((card) => card.id == cardId);
      }
    });

    final l10n = AppLocalizations.of(context)!;
    if (result.isSuccess) {
      AppToast.show(context, l10n.friendRequestsRejectedToast, type: AppToastType.destructiveSoft);
    } else {
      AppToast.show(context, result.message ?? l10n.friendRequestsRejectFailed, type: AppToastType.error);
    }
  }

  /// The requester's full card, so the user can see who this is before
  /// answering. The detail page has its own Accept/Decline for a received
  /// request, so the list is reloaded on return in case it was answered there.
  Future<void> _openProfile(BusinessCardModel card) async {
    await Navigator.of(context).push(
      AppPageRoute(builder: (_) => CardDetailPage(card: card)),
    );
    if (!mounted) return;
    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    // Answered requests stay on screen as "now friends" until the next load,
    // but no longer count as waiting.
    final waiting =
        _requests.where((c) => !_acceptedIds.contains(c.id)).length;

    return Scaffold(
      backgroundColor: isDark ? Wallet.darkGround : const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          l10n.friendRequestsTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Wallet.inkOf(isDark),
          ),
        ),
        backgroundColor: isDark ? Wallet.darkGround : Colors.white,
        elevation: 0,
        surfaceTintColor: isDark ? Wallet.darkGround : Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 680 : double.infinity,
          ),
          child: _isLoading
              ? const Center(child: LoadingView(size: 90))
              : RefreshIndicator(
                  color: Wallet.accentOf(isDark),
                  onRefresh: _loadRequests,
                  child: _requests.isEmpty
                      ? _EmptyRequests(isDark: isDark)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              Wallet.gutter, 12, Wallet.gutter, 24),
                          itemCount: _requests.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(4, 0, 4, 12),
                                child: Text(
                                  waiting > 0
                                      ? l10n.friendRequestsWaiting(waiting)
                                      : l10n.friendRequestsEmpty,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Wallet.mutedOf(isDark),
                                  ),
                                ),
                              );
                            }
                            final card = _requests[index - 1];
                            return _FriendRequestCard(
                              card: card,
                              isAccepted: _acceptedIds.contains(card.id),
                              isBusy: _processingIds.contains(card.id),
                              onAccept: () => _acceptRequest(card.id),
                              onReject: () => _rejectRequest(card.id),
                              onViewProfile: () => _openProfile(card),
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }
}

/// Nothing waiting. Says where requests come from and offers the one thing
/// that leads to more of them, instead of a single grey sentence. Scrollable
/// so pull-to-refresh still works on it.
class _EmptyRequests extends StatelessWidget {
  final bool isDark;
  const _EmptyRequests({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Wallet.tintOf(isDark),
                      ),
                      child: Icon(Icons.person_add_alt_1_rounded,
                          size: 36, color: Wallet.accentOf(isDark)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.friendRequestsEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Wallet.inkOf(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.friendRequestsEmptySubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Wallet.mutedOf(isDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      text: l10n.cardPageEmptyFriendsSearchCta,
                      loading: false,
                      onPressed: () => Navigator.of(context).push(
                        AppPageRoute(builder: (_) => const SearchPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  final BusinessCardModel card;
  final bool isAccepted;
  final bool isBusy;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;
  final VoidCallback onViewProfile;

  const _FriendRequestCard({
    required this.card,
    required this.isAccepted,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  String _relativeTime(BuildContext context, DateTime? createdAt) {
    if (createdAt == null) return '';
    final l10n = AppLocalizations.of(context)!;

    const myanmarOffset = Duration(hours: 6, minutes: 30);
    final now = DateTime.now().toUtc().add(myanmarOffset);
    final requestTime = createdAt.isUtc
        ? createdAt.add(myanmarOffset)
        : createdAt;
    final difference = now.difference(requestTime);

    if (difference.isNegative) {
      return l10n.friendRequestsJustNow;
    }

    if (difference.inSeconds < 60) {
      return l10n.friendRequestsJustNow;
    }
    if (difference.inMinutes < 60) {
      return l10n.friendRequestsMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return l10n.friendRequestsHoursAgo(difference.inHours);
    }
    return l10n.friendRequestsDaysAgo(difference.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final requestedAt = _relativeTime(context, card.createdAt);
    final meta = [
      if (card.position.trim().isNotEmpty) card.position.trim(),
      if ((card.company?.name ?? '').trim().isNotEmpty)
        card.company!.name.trim(),
    ].join(' · ');
    final acceptedColor =
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

    // One row: who, then the answer. The stacked version (identity block,
    // rule, full-width button row) spent ~240dp on a single request; the
    // decision fits beside the name as two round controls.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Wallet.surfaceOf(isDark),
          borderRadius: BorderRadius.circular(Wallet.radiusCard),
          border: Wallet.borderOf(isDark),
          boxShadow: Wallet.shadowOf(isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          // The whole card opens the requester's profile; the two controls
          // on the right take their own taps.
          child: InkWell(
            onTap: onViewProfile,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(
                children: [
                  _RequesterAvatar(card: card, isDark: isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.fullName,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.25,
                            color: Wallet.inkOf(isDark),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Wraps rather than truncating, so a long company
                        // name is never cut to "…".
                        Text(
                          meta.isEmpty
                              ? l10n.friendRequestsDefaultSubtitle
                              : meta,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: Wallet.mutedOf(isDark),
                          ),
                        ),
                        if (isAccepted || requestedAt.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            child: Text(
                              isAccepted
                                  ? l10n.friendRequestsNowFriends
                                  : requestedAt,
                              key: ValueKey(isAccepted),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isAccepted
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isAccepted
                                    ? acceptedColor
                                    : Wallet.faintOf(isDark),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // The one authored moment: answering collapses the two
                  // controls into a single confirmation mark, in place.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: isAccepted
                        ? Container(
                            key: const ValueKey('accepted'),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Wallet.success
                                  .withOpacity(isDark ? .16 : .10),
                            ),
                            child: Icon(Icons.check_rounded,
                                size: 22, color: acceptedColor),
                          )
                        : Row(
                            key: const ValueKey('actions'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RoundAction(
                                tooltip: l10n.friendRequestsReject,
                                icon: Icons.close_rounded,
                                filled: false,
                                isDark: isDark,
                                onPressed: isBusy ? null : onReject,
                              ),
                              const SizedBox(width: 8),
                              _RoundAction(
                                tooltip: l10n.friendRequestsAccept,
                                icon: Icons.check_rounded,
                                filled: true,
                                busy: isBusy,
                                isDark: isDark,
                                onPressed: isBusy ? null : onAccept,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 42dp round answer control. Filled accent for the action being invited,
/// a hairline outline for the quiet alternative. The label lives in the
/// tooltip and the semantics, so screen readers still hear "Accept".
class _RoundAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool filled;
  final bool busy;
  final bool isDark;
  final VoidCallback? onPressed;

  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.filled,
    required this.isDark,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Wallet.accentOf(isDark);
    final onAccent = Wallet.onAccentOf(isDark);

    final style = IconButton.styleFrom(
      fixedSize: const Size(42, 42),
      minimumSize: const Size(42, 42),
      padding: EdgeInsets.zero,
      backgroundColor: filled ? accent : Colors.transparent,
      foregroundColor: filled ? onAccent : Wallet.mutedOf(isDark),
      disabledBackgroundColor:
          filled ? accent.withOpacity(.55) : Colors.transparent,
      disabledForegroundColor:
          filled ? onAccent : Wallet.faintOf(isDark),
      side: filled ? null : BorderSide(color: Wallet.lineOf(isDark)),
      shape: const CircleBorder(),
    );

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: style,
      icon: busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: onAccent),
            )
          : Icon(icon, size: 21),
    );
  }
}

/// Same circle as the avatars elsewhere: soft accent fill, ring drawn over
/// the photo, first letter when there is no photo or it fails to load.
class _RequesterAvatar extends StatelessWidget {
  final BusinessCardModel card;
  final bool isDark;

  const _RequesterAvatar({required this.card, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final url = (card.profileImage ?? '').isNotEmpty
        ? ImageUrl.resolve(card.profileImage)
        : null;
    final letter =
        card.fullName.isNotEmpty ? card.fullName[0].toUpperCase() : '?';

    Widget fallback() => Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Wallet.accentOf(isDark),
            ),
          ),
        );

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Wallet.accentDark.withOpacity(.16) : Wallet.accentSoft,
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Wallet.accentOf(isDark).withOpacity(.25),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback(),
            )
          : fallback(),
    );
  }
}
