import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../network/image_url.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../utils/full_image_viewer.dart';
import '../widgets/app_toast.dart';
import '../theme/wallet_tokens.dart';
import '../widgets/my_qr_panel.dart';
import 'add_card_page.dart';
import 'deactivate_account_page.dart';

class CardDetailPage extends ConsumerStatefulWidget {
  final BusinessCardModel card;

  const CardDetailPage({super.key, required this.card});

  // Palette lives in Wallet so the list and this page cannot drift apart.
  // These aliases keep the existing call sites unchanged.
  static const primary = Wallet.accentLight;
  static const secondary = Color(0xFFC4B5FD);
  static const tertiary = Wallet.ground;

  static const _ink = Wallet.ink;
  static const _muted = Wallet.muted;
  static const _primary = Wallet.accentLight;
  static const _border = Wallet.line;
  static const _accentSoft = Wallet.accentSoft;
  static const _iconSoft = Wallet.iconSoft;

  static const _darkBg = Wallet.darkGround;
  static const _darkSurface = Wallet.darkSurface;
  static const _darkBorder = Wallet.darkLine;
  static const _darkInk = Wallet.darkInk;
  static const _darkMuted = Wallet.darkMuted;
  static const _accentDark = Wallet.accentDark;

  static List<BoxShadow>? surfaceShadow(bool isDark) => Wallet.shadowOf(isDark);
  static Color surface(bool isDark) => Wallet.surfaceOf(isDark);
  static Color accent(bool isDark) => Wallet.accentOf(isDark);
  static Color ink(bool isDark) => Wallet.inkOf(isDark);
  static Color muted(bool isDark) => Wallet.mutedOf(isDark);
  static Color faint(bool isDark) => Wallet.faintOf(isDark);
  static Color line(bool isDark) => Wallet.lineOf(isDark);

  // Typography using desired stack (Helvetica Neue / Inter / Arial fallback)
  // These inherit the app's fontFamily + fallback from ThemeData
  // The hero and section headers now style themselves; what remains here is
  // what more than one widget shares.
  static TextStyle bodyStyle(bool isDark) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? _darkInk : _ink,
        height: 1.55,
      );

  static TextStyle smallMutedStyle(bool isDark) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: isDark ? _darkMuted : _muted,
      );

  @override
  ConsumerState<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends ConsumerState<CardDetailPage> {
  late bool _isFriend;
  late String _friendRequestStatus;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isFriend = widget.card.isFriend;
    _friendRequestStatus = widget.card.friendRequestStatus ?? 'none';
  }

  /// Opens the form for [card] and, when something was saved, reloads the list
  /// and swaps this page for one built on the fresh copy.
  ///
  /// The swap is what keeps the detail page honest after an edit — it holds the
  /// card it was constructed with, so without it a saved change would not show
  /// until the user backed out and came in again.
  Future<void> _openCardEditor(BusinessCardModel card) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddCardPage(card: card)),
    );
    if (!mounted || updated != true) return;

    final currentUser = ref.read(authProvider).valueOrNull?.currentUser;
    await ref.read(cardProvider.notifier).fetchCards();
    if (!mounted) return;

    AppToast.show(
      context,
      'Business card updated successfully',
      type: AppToastType.success,
    );

    final cards = ref.read(cardProvider).valueOrNull?.cards ?? [];
    // A placeholder profile card has no id yet, so it is found by ownership
    // instead — saving it is what gives it a real one.
    final index = card.id == 0
        ? cards.indexWhere((c) =>
            c.cardType == 'user_card' &&
            (c.user?.id == currentUser?.id ||
                c.createdBy == currentUser?.id))
        : cards.indexWhere((c) => c.id == card.id);
    if (index == -1) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => CardDetailPage(card: cards[index]),
      ),
    );
  }

  AlertDialog _buildActionDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
    bool destructive = false,
    Widget? extraContent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? CardDetailPage._darkSurface : Colors.white,
      surfaceTintColor: isDark ? CardDetailPage._darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? CardDetailPage._darkBorder : CardDetailPage._border),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? CardDetailPage._darkInk : CardDetailPage._ink,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: TextStyle(
              color: isDark ? CardDetailPage._darkMuted : CardDetailPage._muted,
              height: 1.45,
              fontSize: 14,
            ),
          ),
          if (extraContent != null) ...[
            const SizedBox(height: 16),
            extraContent,
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: isDark ? CardDetailPage._darkMuted : CardDetailPage._muted),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(
            confirmText,
            style: TextStyle(
              color: destructive ? Colors.redAccent : CardDetailPage._primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isDestructiveSoft = false,
  }) {
    AppToast.show(
      context,
      message,
      type: isError
          ? AppToastType.error
          : isDestructiveSoft
              ? AppToastType.destructiveSoft
              : AppToastType.success,
    );
  }

  Future<void> _showDeactivateAccountFlow(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeactivateAccountPage()),
    );
  }

  /// The QR sheet. Lifted out of the body so the overflow menu is its only
  /// caller — sharing used to be reachable from two places at once.
  void _showQrSheet(BusinessCardModel card, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: isDark ? CardDetailPage._darkSurface : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark
                  ? CardDetailPage._darkBorder
                  : CardDetailPage._border,
            ),
          ),
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CardDetailPage._darkBorder
                        : CardDetailPage._border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Share Your Card',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? CardDetailPage._darkInk
                      : CardDetailPage._ink,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Others can scan this to save your contact',
                style: CardDetailPage.smallMutedStyle(isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              MyQrPanel(profileCard: card, compact: false),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final card = widget.card;
    final isFriend = _isFriend;
    final friendRequestStatus = _friendRequestStatus;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.read(authProvider).valueOrNull?.currentUser;
    final isMyCard = currentUser != null && card.user?.id == currentUser.id;
    final isSavedCard = card.cardType == 'saved_card';
    final isUserCard = card.cardType == 'user_card';
    final isMyProfileCard = isMyCard && isUserCard;

    final avatarUrl =
        (card.profileImage != null && card.profileImage!.isNotEmpty)
            ? ImageUrl.resolve(card.profileImage!)
            : null;

    // Photos of the physical card. Most cards have a front only, so the
    // section adapts rather than reserving an empty slot for the back.
    final cardPhotoUrls = <String, String>{
      for (final entry in {
        'Front': card.frontImage,
        'Back': card.backImage,
      }.entries)
        if (ImageUrl.resolve(entry.value) case final url?) entry.key: url,
    };

    return Scaffold(
      backgroundColor: isDark ? CardDetailPage._darkBg : CardDetailPage.tertiary,
      appBar: AppBar(
        backgroundColor: isDark ? CardDetailPage._darkBg : CardDetailPage.tertiary,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? CardDetailPage._darkInk : CardDetailPage._ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Share and Edit live here and nowhere else. They were previously
          // duplicated into the body, so the same action appeared twice on one
          // screen. The body keeps only the relationship actions.
          if (isSavedCard || isMyCard || isUserCard)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                color: isDark ? CardDetailPage._darkSurface : Colors.white,
                surfaceTintColor: isDark ? CardDetailPage._darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? CardDetailPage._darkBorder : CardDetailPage._border),
                ),
                elevation: 2,
                onSelected: (value) async {
                  if (value == 'share') {
                    _showQrSheet(card, isDark);
                    return;
                  }

                  if (value == 'edit') {
                    await _openCardEditor(card);
                    return;
                  }

                  if (value == 'delete') {
                    if (isMyProfileCard) {
                      await _showDeactivateAccountFlow(context);
                      return;
                    }

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => _buildActionDialog(
                        ctx,
                        title: 'Delete Card',
                        content: 'Are you sure you want to delete this card?',
                        confirmText: 'Delete',
                        destructive: true,
                        onConfirm: () => Navigator.pop(ctx, true),
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final result = await ref
                          .read(cardProvider.notifier)
                          .deleteCard(card.id);
                      final deleteMessage =
                          ref.read(cardProvider).valueOrNull?.deleteMessage;

                      if (!context.mounted) return;

                      if (result.isSuccess) {
                        _showToast(
                          context,
                          deleteMessage ??
                              result.message ??
                              'Card deleted successfully',
                          isDestructiveSoft: true,
                        );
                        Navigator.pop(context);
                      } else {
                        _showToast(
                          context,
                          deleteMessage ??
                              result.message ??
                              'Failed to delete card',
                          isError: true,
                        );
                      }
                    }
                  }
                },
                itemBuilder: (_) => [
                  // Sharing means handing over a QR, which only a user_card
                  // carries — a saved card has no code of its own to show.
                  if (isUserCard)
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              size: 19,
                              color: isDark
                                  ? CardDetailPage._darkInk
                                  : Colors.black87),
                          const SizedBox(width: 12),
                          Text(
                            isMyProfileCard ? 'Share my card' : 'Share',
                            style: TextStyle(
                                color: isDark
                                    ? CardDetailPage._darkInk
                                    : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  if (isSavedCard || isMyProfileCard)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 19,
                              color: isDark
                                  ? CardDetailPage._darkInk
                                  : Colors.black87),
                          const SizedBox(width: 12),
                          Text(
                            'Edit',
                            style: TextStyle(
                                color: isDark
                                    ? CardDetailPage._darkInk
                                    : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  if (isSavedCard || isMyCard)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              size: 19, color: Colors.redAccent),
                          const SizedBox(width: 12),
                          Text(
                            isMyProfileCard ? 'Deactivate Account' : 'Delete',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ===== HERO =====
          // Identity only; the printed card sits at the foot of the page.
          _PremiumHero(
            card: card,
            avatarUrl: avatarUrl,
            isDark: isDark,
            isMyProfileCard: isMyProfileCard,
            cardTypeLabel: card.cardType == 'saved_card' ? 'Saved' : 'Business',
            isFriend: isFriend,
            // A portrait belongs to a person's own card. A saved card is a
            // photo of someone's printed card — it has no portrait, and a
            // letter-circle standing in for one is just noise above it.
            showAvatar: isUserCard,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    // ===== QUICK ACTIONS =====
                    _ActionList(
                      card: card,
                      isDark: isDark,
                      isMyProfileCard: isMyProfileCard,
                      isFriend: isFriend,
                      friendRequestStatus: friendRequestStatus,
                      isProcessing: _isProcessing,
                      onFriendAction: () async {
                        if (isFriend) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => _buildActionDialog(
                              ctx,
                              title: 'Unfriend',
                              content: 'Remove this connection?',
                              confirmText: 'Unfriend',
                              destructive: true,
                              onConfirm: () => Navigator.pop(ctx, true),
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            setState(() => _isProcessing = true);
                            final res = await ref
                                .read(cardProvider.notifier)
                                .removeFriend(card.id);
                            if (!context.mounted) return;
                            setState(() {
                              _isProcessing = false;
                              if (res.isSuccess) {
                                _isFriend = false;
                                _friendRequestStatus = 'none';
                              }
                            });
                            if (res.isSuccess) {
                              _showToast(context, 'Friend removed', isDestructiveSoft: true);
                            } else {
                              _showToast(context, res.message ?? 'Failed to remove friend', isError: true);
                            }
                          }
                        } else if (friendRequestStatus == 'pending_sent' || friendRequestStatus == 'pending') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => _buildActionDialog(
                              ctx,
                              title: 'Cancel Request',
                              content: 'Cancel the friend request sent to this user?',
                              confirmText: 'Cancel Request',
                              destructive: true,
                              onConfirm: () => Navigator.pop(ctx, true),
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            setState(() => _isProcessing = true);
                            final res = await ref
                                .read(cardProvider.notifier)
                                .removeFriend(card.id);
                            if (!context.mounted) return;
                            setState(() {
                              _isProcessing = false;
                              if (res.isSuccess) {
                                _friendRequestStatus = 'none';
                                _isFriend = false;
                              }
                            });
                            if (res.isSuccess) {
                              _showToast(context, 'Friend request cancelled', isDestructiveSoft: true);
                            } else {
                              _showToast(context, res.message ?? 'Failed to cancel request', isError: true);
                            }
                          }
                        } else {
                          setState(() => _isProcessing = true);
                          final res = await ref
                              .read(cardProvider.notifier)
                              .addFriend(card.id);
                          if (!context.mounted) return;
                          setState(() {
                            _isProcessing = false;
                            if (res.isSuccess) {
                              _friendRequestStatus = 'pending_sent';
                            }
                          });
                          if (res.isSuccess) {
                            _showToast(context, 'Friend request sent');
                          } else {
                            _showToast(context, res.message ?? 'Failed to send friend request', isError: true);
                          }
                        }
                      },
                      onAcceptFriend: () async {
                        setState(() => _isProcessing = true);
                        final res = await ref
                            .read(cardProvider.notifier)
                            .acceptFriendRequest(card.id);
                        if (!context.mounted) return;
                        setState(() {
                          _isProcessing = false;
                          if (res.isSuccess) {
                            _friendRequestStatus = 'accepted';
                            _isFriend = true;
                          }
                        });
                        if (res.isSuccess) {
                          _showToast(context, 'Friend request accepted');
                        } else {
                          _showToast(context, res.message ?? 'Failed to accept request', isError: true);
                        }
                      },
                      onRejectFriend: () async {
                        setState(() => _isProcessing = true);
                        final res = await ref
                            .read(cardProvider.notifier)
                            .rejectFriendRequest(card.id);
                        if (!context.mounted) return;
                        setState(() {
                          _isProcessing = false;
                          if (res.isSuccess) {
                            _friendRequestStatus = 'none';
                            _isFriend = false;
                          }
                        });
                        if (res.isSuccess) {
                          _showToast(context, 'Friend request declined', isDestructiveSoft: true);
                        } else {
                          _showToast(context, res.message ?? 'Failed to decline request', isError: true);
                        }
                      },
                    ),

                    // ===== BIO =====
                    if ((card.bio ?? '').trim().isNotEmpty) ...[
                      _SectionLabel('About', isDark: isDark),
                      Text(
                        card.bio!.trim(),
                        style: CardDetailPage.bodyStyle(isDark),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // ===== CONTACT =====
                    _ContactSection(card: card, isDark: isDark),

                    // ===== SOCIAL LINKS =====
                    _SocialSection(
                        socialLinks: card.socialLinks, isDark: isDark),

                    // ===== COMPANY =====
                    if (card.company != null)
                      _CompanySection(
                          company: card.company!, isDark: isDark),

                    // ===== THE PRINTED CARD =====
                    // Last, as reference. Tapping opens it full screen, which
                    // is where anyone actually reads a card photo.
                    if (cardPhotoUrls.isNotEmpty) ...[
                      _SectionLabel('Business card', isDark: isDark),
                      _CardCarousel(photos: cardPhotoUrls, isDark: isDark),
                    ]
                    // Your own card still names the gap, so a half-finished
                    // profile does not look complete.
                    else if (isMyProfileCard) ...[
                      _SectionLabel('Business card', isDark: isDark),
                      _SecondaryButton(
                        icon: Icons.add_a_photo_outlined,
                        label: 'Add front & back photos',
                        onTap: () => _openCardEditor(card),
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }
}

/// The identity: avatar, name, role, and a status chip, on one lifted surface.
///
/// A surface rather than loose text — the block is a thing you look at, and it
/// gives the page something to open on besides a heading.
class _PremiumHero extends StatelessWidget {
  final BusinessCardModel card;
  final String? avatarUrl;
  final bool isDark;
  final bool isMyProfileCard;
  final String cardTypeLabel;
  final bool isFriend;

  /// Only a person's own card carries a portrait; see the call site.
  final bool showAvatar;

  const _PremiumHero({
    required this.card,
    required this.avatarUrl,
    required this.isDark,
    required this.isMyProfileCard,
    required this.cardTypeLabel,
    required this.isFriend,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter =
        card.fullName.isNotEmpty ? card.fullName[0].toUpperCase() : '?';
    final company = card.company?.name ?? '';
    final subtitle = [
      if (card.position.isNotEmpty) card.position,
      if (company.isNotEmpty) company,
    ].join('  ·  ');

    final chip = isMyProfileCard
        ? 'Your profile'
        : isFriend
            ? 'Connected'
            : cardTypeLabel;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CardDetailPage.surface(isDark),
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: CardDetailPage._darkBorder)
            : null,
        boxShadow: CardDetailPage.surfaceShadow(isDark),
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? CardDetailPage._accentDark.withOpacity(.16)
                    : CardDetailPage._accentSoft,
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AvatarFallback(letter: firstLetter, isDark: isDark),
                    )
                  : _AvatarFallback(letter: firstLetter, isDark: isDark),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.fullName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.55,
                    height: 1.15,
                    color: CardDetailPage.ink(isDark),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: CardDetailPage.muted(isDark),
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                _Chip(label: chip, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _Chip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? CardDetailPage._accentDark.withOpacity(.14)
              : CardDetailPage._accentSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: CardDetailPage.accent(isDark),
          ),
        ),
      );
}

class _AvatarFallback extends StatelessWidget {
  final String letter;
  final bool isDark;
  const _AvatarFallback({required this.letter, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        color: isDark
            ? CardDetailPage._accentDark.withOpacity(.16)
            : CardDetailPage._accentSoft,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: CardDetailPage.accent(isDark),
          ),
        ),
      );
}

/// Small tracked caption above a group.
class _SectionLabel extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionLabel(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 9),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.25,
            color: CardDetailPage.faint(isDark),
          ),
        ),
      );
}

/// A lifted white surface. Rows inside it are separated by hairlines, so the
/// group reads as one object instead of a stack of loose lines.
class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final EdgeInsets padding;

  const _GroupCard({
    required this.children,
    required this.isDark,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CardDetailPage.surface(isDark),
        borderRadius: BorderRadius.circular(20),
        border:
            isDark ? Border.all(color: CardDetailPage._darkBorder) : null,
        boxShadow: CardDetailPage.surfaceShadow(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 58,
                color: CardDetailPage.line(isDark),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One detail: tinted icon tile, label over value, chevron. The whole row is
/// the action — tapping the phone number calls it.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? CardDetailPage._accentDark.withOpacity(.13)
                    : CardDetailPage._iconSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: CardDetailPage.accent(isDark)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: CardDetailPage.faint(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.3,
                      color: CardDetailPage.ink(isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: CardDetailPage.faint(isDark)),
          ],
        ),
      ),
    );
  }
}

/// The one filled action on the page. Everything else stays unsaturated so
/// this is unmistakably the thing to press.
class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: Material(
        color: CardDetailPage.accent(isDark),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: enabled && !isDark
                  ? [
                      BoxShadow(
                        color: CardDetailPage._primary.withOpacity(.42),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                        spreadRadius: -10,
                      ),
                    ]
                  : null,
            ),
            child: SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 18,
                      color: Wallet.onAccentOf(isDark)),
                  const SizedBox(width: 9),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: Wallet.onAccentOf(isDark),
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

/// A quieter action, on a surface rather than a fill.
class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final bool destructive;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFDC2626)
        : CardDetailPage.ink(isDark);
    return Opacity(
      opacity: onTap == null ? .55 : 1,
      child: Material(
        color: CardDetailPage.surface(isDark),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: isDark
                  ? Border.all(color: CardDetailPage._darkBorder)
                  : null,
              boxShadow: CardDetailPage.surfaceShadow(isDark),
            ),
            child: SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: color),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: color,
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

/// The relationship actions. Share, Edit and Delete live in the app bar menu.
class _ActionList extends StatelessWidget {
  final BusinessCardModel card;
  final bool isDark;
  final bool isMyProfileCard;
  final bool isFriend;
  final String friendRequestStatus;
  final VoidCallback onFriendAction;
  final VoidCallback onAcceptFriend;
  final VoidCallback onRejectFriend;

  /// True while a request is in flight, so a second tap cannot send it twice.
  final bool isProcessing;

  const _ActionList({
    required this.card,
    required this.isDark,
    required this.isMyProfileCard,
    required this.isFriend,
    required this.friendRequestStatus,
    required this.onFriendAction,
    required this.onAcceptFriend,
    required this.onRejectFriend,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    if (isMyProfileCard || card.cardType != 'user_card') {
      return const SizedBox.shrink();
    }

    final Widget content;
    if (isFriend) {
      content = _SecondaryButton(
        icon: Icons.person_remove_alt_1_rounded,
        label: 'Unfriend',
        onTap: isProcessing ? null : onFriendAction,
        isDark: isDark,
        destructive: true,
      );
    } else if (friendRequestStatus == 'pending_received') {
      content = Row(
        children: [
          Expanded(
            flex: 3,
            child: _PrimaryButton(
              icon: Icons.check_rounded,
              label: 'Accept',
              onTap: isProcessing ? null : onAcceptFriend,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _SecondaryButton(
              icon: Icons.close_rounded,
              label: 'Decline',
              onTap: isProcessing ? null : onRejectFriend,
              isDark: isDark,
            ),
          ),
        ],
      );
    } else if (friendRequestStatus == 'pending_sent' ||
        friendRequestStatus == 'pending') {
      content = _SecondaryButton(
        icon: Icons.schedule_rounded,
        label: 'Request sent',
        onTap: isProcessing ? null : onFriendAction,
        isDark: isDark,
      );
    } else {
      content = _PrimaryButton(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Connect',
        onTap: isProcessing ? null : onFriendAction,
        isDark: isDark,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: content,
    );
  }
}

class _ContactSection extends StatelessWidget {
  final BusinessCardModel card;
  final bool isDark;

  const _ContactSection({required this.card, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final p in card.phones) {
      rows.add(_DetailRow(
          icon: Icons.call_rounded,
          label: 'Phone',
          value: p,
          onTap: () => _launch('tel:$p'),
          isDark: isDark));
    }
    for (final e in card.emails) {
      rows.add(_DetailRow(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: e,
          onTap: () => _launch('mailto:$e'),
          isDark: isDark));
    }
    for (final a in card.addresses) {
      // The API always emits all five keys, so an entry with nothing filled in
      // still arrives as an object. Rendering it would give a row with an icon
      // and no text.
      if (a.isEmpty) continue;
      final text = a.displayText;
      rows.add(_DetailRow(
          icon: Icons.place_outlined,
          label: 'Address',
          value: text,
          onTap: () => _launch(
              'https://maps.google.com/?q=${Uri.encodeComponent(text)}'),
          isDark: isDark));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel('Contact', isDark: isDark),
          _GroupCard(isDark: isDark, children: rows),
        ],
      ),
    );
  }

  void _launch(String u) async {
    try {
      await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _SocialSection extends StatelessWidget {
  final List<dynamic>? socialLinks;
  final bool isDark;

  const _SocialSection({this.socialLinks, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (socialLinks == null || socialLinks!.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[];
    for (final s in socialLinks!) {
      final m = s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{};
      final platform = (m['platform'] ?? 'Link').toString();
      final url = m['url']?.toString() ?? '';
      rows.add(_DetailRow(
        icon: _iconFor(platform),
        label: platform,
        value: url.isEmpty ? platform : url,
        onTap: () async {
          if (url.isEmpty) return;
          try {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          } catch (_) {}
        },
        isDark: isDark,
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel('Social', isDark: isDark),
          _GroupCard(isDark: isDark, children: rows),
        ],
      ),
    );
  }

  IconData _iconFor(String platform) {
    switch (platform.toLowerCase()) {
      case 'telegram':
      case 'viber':
      case 'whatsapp':
      case 'messenger':
        return Icons.chat_bubble_outline_rounded;
      case 'youtube':
        return Icons.play_circle_outline_rounded;
      case 'website':
      case 'web':
        return Icons.language_rounded;
      default:
        return Icons.public_rounded;
    }
  }
}

class _CompanySection extends StatelessWidget {
  final CompanyModel company;
  final bool isDark;

  const _CompanySection({required this.company, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final meta = [company.industry, company.businessType]
        .where((e) => e != null && e.isNotEmpty)
        .join('  ·  ');
    final initial =
        company.name.isNotEmpty ? company.name[0].toUpperCase() : '#';

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel('Company', isDark: isDark),
          _GroupCard(
            isDark: isDark,
            padding: const EdgeInsets.all(14),
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark
                          ? CardDetailPage._accentDark.withOpacity(.13)
                          : CardDetailPage._iconSoft,
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CardDetailPage.accent(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: CardDetailPage.ink(isDark),
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            meta,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: CardDetailPage.muted(isDark),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              for (final line in [
                if ((company.website ?? '').isNotEmpty)
                  (Icons.language_rounded, company.website!),
                if ((company.phone ?? '').isNotEmpty)
                  (Icons.call_rounded, company.phone!),
                if ((company.email ?? '').isNotEmpty)
                  (Icons.mail_outline_rounded, company.email!),
              ])
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(line.$1,
                          size: 15, color: CardDetailPage.faint(isDark)),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          line.$2,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            color: CardDetailPage.muted(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The printed card, at whatever proportions the photo actually has.
class _CardCarousel extends StatefulWidget {
  final Map<String, String> photos;
  final bool isDark;

  const _CardCarousel({required this.photos, required this.isDark});

  @override
  State<_CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<_CardCarousel> {
  late final PageController _controller;
  int _index = 0;

  /// The photo's own width/height. The frame is sized from this so nothing is
  /// cropped: assuming 85x55mm (1.62) was wrong for every real upload, which
  /// arrive at 2.17, and cover-fitting those cut a quarter of the width off.
  double? _ratio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  static const _fallbackRatio = 1.75;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveRatio();
  }

  @override
  void didUpdateWidget(covariant _CardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos.values.firstOrNull !=
        widget.photos.values.firstOrNull) {
      _ratio = null;
      _resolveRatio();
    }
  }

  void _resolveRatio() {
    final url = widget.photos.values.firstOrNull;
    if (url == null) return;

    _detach();
    final stream =
        _provider(url).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      final ratio = info.image.width / info.image.height;
      if (!mounted || ratio == _ratio) return;
      setState(() => _ratio = ratio);
    }, onError: (_, __) {
      if (mounted && _ratio == null) setState(() => _ratio = _fallbackRatio);
    });
    _stream = stream..addListener(listener);
    _listener = listener;
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  /// Capped decode. The originals are 4096px wide — roughly 31MB of memory
  /// each once decoded, for a slot a few hundred pixels across.
  ImageProvider _provider(String url) => ResizeImage(
        NetworkImage(url),
        width: 1080,
        allowUpscaling: false,
      );

  @override
  void dispose() {
    _detach();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.photos.entries.toList();
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: _ratio ?? _fallbackRatio,
          child: PageView.builder(
            controller: _controller,
            itemCount: entries.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openViewer(entries, i),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: CardDetailPage.surface(isDark),
                  boxShadow: CardDetailPage.surfaceShadow(isDark),
                  border: isDark
                      ? Border.all(color: CardDetailPage._darkBorder)
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image(
                  image: _provider(entries[i].value),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: CardDetailPage.surface(isDark),
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image_outlined,
                        color: CardDetailPage.faint(isDark)),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (entries.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < entries.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 5),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: i == _index
                        ? CardDetailPage.accent(isDark)
                        : CardDetailPage.accent(isDark).withOpacity(.22),
                  ),
                ),
              const Spacer(),
              Text(
                '${entries[_index].key} · tap to enlarge',
                style: TextStyle(
                  fontSize: 11,
                  color: CardDetailPage.faint(isDark),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _openViewer(List<MapEntry<String, String>> entries, int index) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.94),
      builder: (_) => FullImageViewer(
        images: [for (final e in entries) e.value],
        labels: [for (final e in entries) e.key],
        initialIndex: index,
      ),
    );
  }
}
