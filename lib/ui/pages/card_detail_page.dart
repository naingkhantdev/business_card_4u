import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../network/image_url.dart';
import '../../data/vos/address_model.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../utils/full_image_viewer.dart';
import '../widgets/app_toast.dart';
import '../theme/wallet_tokens.dart';
import '../widgets/my_qr_panel.dart';
import 'add_card_page.dart';
import 'company_detail_page.dart';
import 'deactivate_account_page.dart';

/// Opens a tel:/mailto:/https: link in whatever app handles it, swallowing
/// failures — every launcher call on this page (quick actions, detail rows,
/// company links) goes through this one place.
Future<void> _openLink(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// A website often comes back bare ("acme.com"), which `Uri.parse` treats as
/// a relative path rather than something a browser can open — it needs a
/// scheme first.
String _normalizeUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

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
      // Landscape leaves a dialog only a couple of hundred points of height,
      // and AlertDialog does not scroll its content on its own.
      scrollable: true,
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

                    // ===== COMPANY / CONTACT / SOCIAL =====
                    // One surface, not three — a card per few rows of text
                    // read as clutter before it read as organization. The
                    // groups still separate cleanly by their own caption and
                    // the hairline `_GroupCard` already draws between rows.
                    _DetailsCard(card: card, isDark: isDark),

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

/// The identity: a large centered avatar, name, role, and a status chip, on
/// one quiet surface with a single accent line across its top.
///
/// A gradient cover was tried here and reverted — it read as "premium" in
/// isolation, but every other screen in this app (Cards, Search, Manage
/// Companies) is a neutral surface with one accent spent sparingly, per the
/// design notes on [Wallet] itself: "a coloured shadow is decoration, and it
/// dirties a neutral ground." A colour banner on just this one page broke
/// that — it stopped looking like part of the app and started looking like a
/// different app's mockup pasted in. What reads as premium *in this system*
/// is what already works on its other screens: restraint, generous
/// whitespace, and the accent spent on a couple of precise details instead
/// of a wash of color.
class _PremiumHero extends StatelessWidget {
  final BusinessCardModel card;
  final String? avatarUrl;
  final bool isDark;
  final bool isMyProfileCard;
  final String cardTypeLabel;
  final bool isFriend;

  /// Only a person's own card carries a portrait; a saved card gets a
  /// neutral card icon in the same spot instead — see the call site.
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
    final tag = (card.tag ?? '').trim();
    final createdAt = card.createdAt;
    AddressModel? firstAddress;
    for (final a in card.addresses) {
      if (!a.isEmpty) {
        firstAddress = a;
        break;
      }
    }
    final website = card.company?.website;

    final mapAddress = firstAddress;
    final companyWebsite = website;

    final quickActions = <_QuickAction>[
      if (card.phones.isNotEmpty)
        _QuickAction(Icons.call_rounded, 'Call',
            () => _openLink('tel:${card.phones.first}')),
      if (card.emails.isNotEmpty)
        _QuickAction(Icons.mail_rounded, 'Email',
            () => _openLink('mailto:${card.emails.first}')),
      if (mapAddress != null)
        _QuickAction(
            Icons.map_rounded,
            'Map',
            () => _openLink(
                'https://maps.google.com/?q=${Uri.encodeComponent(mapAddress.displayText)}')),
      if (companyWebsite != null && companyWebsite.isNotEmpty)
        _QuickAction(Icons.language_rounded, 'Website',
            () => _openLink(_normalizeUrl(companyWebsite))),
    ];

    const avatarSize = 88.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      decoration: BoxDecoration(
        color: CardDetailPage.surface(isDark),
        borderRadius: BorderRadius.circular(24),
        border:
            isDark ? Border.all(color: CardDetailPage._darkBorder) : null,
        boxShadow: CardDetailPage.surfaceShadow(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The one line of colour on the page — a signature, not a banner.
          Container(height: 3, color: CardDetailPage.accent(isDark)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? CardDetailPage._accentDark.withOpacity(.16)
                        : CardDetailPage._accentSoft,
                    border: Border.all(
                      color: CardDetailPage.accent(isDark).withOpacity(.25),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: showAvatar
                      ? (avatarUrl != null
                          ? Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _AvatarFallback(
                                  letter: firstLetter, isDark: isDark),
                            )
                          : _AvatarFallback(letter: firstLetter, isDark: isDark))
                      : _AvatarFallback(
                          icon: Icons.badge_rounded, isDark: isDark),
                ),
                const SizedBox(height: 18),
                Text(
                  card.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.55,
                    height: 1.15,
                    color: CardDetailPage.ink(isDark),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: CardDetailPage.muted(isDark),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(label: chip, isDark: isDark),
                    if (tag.isNotEmpty) _Chip(label: tag, isDark: isDark),
                  ],
                ),
                if (quickActions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(height: 1, color: CardDetailPage.line(isDark)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final action in quickActions)
                        _QuickActionButton(action: action, isDark: isDark),
                    ],
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Added ${_formatDate(createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Wallet.darkFaint : Colors.grey.shade400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.onTap);
}

/// One of the hero's quick actions — a filled circular icon with its label
/// underneath, the pattern contact-card apps use for "the handful of things
/// you'd actually do with this person right now" (call, email, find them,
/// visit their site), pulled up out of the detail rows below so they don't
/// need a scroll and a squint at a label to find.
class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  final bool isDark;

  const _QuickActionButton({required this.action, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CardDetailPage.accent(isDark),
                ),
                child: Icon(action.icon,
                    size: 19, color: Wallet.onAccentOf(isDark)),
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CardDetailPage.muted(isDark),
                ),
              ),
            ],
          ),
        ),
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
  final String? letter;
  final IconData? icon;
  final bool isDark;
  const _AvatarFallback({this.letter, this.icon, required this.isDark})
      : assert(letter != null || icon != null);

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        color: isDark
            ? CardDetailPage._accentDark.withOpacity(.16)
            : CardDetailPage._accentSoft,
        child: icon != null
            ? Icon(icon, size: 26, color: CardDetailPage.accent(isDark))
            : Text(
                letter!,
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
                // Full-width where the next row starts a new labelled group
                // (a section break, not just the next field) — indented to
                // clear the icon tile everywhere else, so it reads as
                // continuing the same group rather than ending it.
                indent: children[i] is _InlineHeader ? 0 : 58,
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
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: Wallet.onAccentOf(isDark),
                      ),
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
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: color,
                      ),
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

/// Company, contact, and social — merged onto one surface instead of three
/// separate elevated cards stacked with gaps between them. Splitting them by
/// data type made sense when the model was written but not when it's on
/// screen: three shadows and three borders for a handful of rows each reads
/// as fragments of a page, not as a page. Each group still gets its own
/// caption and the hairline `_GroupCard` already draws between every row, so
/// nothing about telling them apart is lost — only the repeated framing is.
class _DetailsCard extends StatelessWidget {
  final BusinessCardModel card;
  final bool isDark;

  const _DetailsCard({required this.card, required this.isDark});

  IconData _socialIconFor(String platform) {
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

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    final company = card.company;
    if (company != null) {
      children.add(_InlineHeader('Company', isDark: isDark, isFirst: true));
      children.add(_CompanyHeaderRow(company: company, isDark: isDark));
      if ((company.description ?? '').trim().isNotEmpty) {
        children.add(_InlineTextRow(company.description!.trim(), isDark: isDark));
      }
      // Same row shape as the Contact section below, not a quieter,
      // non-tappable readout of the same kind of data — a phone number
      // should look and behave the same whether it's the company's or the
      // person's.
      if ((company.address ?? '').isNotEmpty) {
        children.add(_DetailRow(
          icon: Icons.place_outlined,
          label: 'Address',
          value: company.address!,
          onTap: () => _openLink(
              'https://maps.google.com/?q=${Uri.encodeComponent(company.address!)}'),
          isDark: isDark,
        ));
      }
      if ((company.website ?? '').isNotEmpty) {
        children.add(_DetailRow(
          icon: Icons.language_rounded,
          label: 'Website',
          value: company.website!,
          onTap: () => _openLink(_normalizeUrl(company.website!)),
          isDark: isDark,
        ));
      }
      if ((company.phone ?? '').isNotEmpty) {
        children.add(_DetailRow(
          icon: Icons.call_rounded,
          label: 'Phone',
          value: company.phone!,
          onTap: () => _openLink('tel:${company.phone}'),
          isDark: isDark,
        ));
      }
      if ((company.email ?? '').isNotEmpty) {
        children.add(_DetailRow(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: company.email!,
          onTap: () => _openLink('mailto:${company.email}'),
          isDark: isDark,
        ));
      }
      // The company's own social links — separate from the card's own
      // `socialLinks` below, which belong to the person, not the business.
      for (final s in company.socials) {
        children.add(_DetailRow(
          icon: _socialIconFor(s.platform),
          label: s.platform,
          value: s.url,
          onTap: () => _openLink(s.url),
          isDark: isDark,
        ));
      }
    }

    final contactRows = <Widget>[
      for (final p in card.phones)
        _DetailRow(
            icon: Icons.call_rounded,
            label: 'Phone',
            value: p,
            onTap: () => _openLink('tel:$p'),
            isDark: isDark),
      for (final e in card.emails)
        _DetailRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: e,
            onTap: () => _openLink('mailto:$e'),
            isDark: isDark),
      // The API always emits all five address keys, so an entry with nothing
      // filled in still arrives as an object — rendering it would give a row
      // with an icon and no text.
      for (final a in card.addresses)
        if (!a.isEmpty)
          _DetailRow(
              icon: Icons.place_outlined,
              label: 'Address',
              value: a.displayText,
              onTap: () => _openLink(
                  'https://maps.google.com/?q=${Uri.encodeComponent(a.displayText)}'),
              isDark: isDark),
    ];
    if (contactRows.isNotEmpty) {
      children.add(_InlineHeader('Contact',
          isDark: isDark, isFirst: children.isEmpty));
      children.addAll(contactRows);
    }

    final socialRows = <Widget>[];
    for (final s in card.socialLinks ?? const []) {
      final m = s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{};
      final platform = (m['platform'] ?? 'Link').toString();
      final url = m['url']?.toString() ?? '';
      socialRows.add(_DetailRow(
        icon: _socialIconFor(platform),
        label: platform,
        value: url.isEmpty ? platform : url,
        onTap: url.isEmpty ? () {} : () => _openLink(url),
        isDark: isDark,
      ));
    }
    if (socialRows.isNotEmpty) {
      children.add(_InlineHeader('Social',
          isDark: isDark, isFirst: children.isEmpty));
      children.addAll(socialRows);
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: _GroupCard(isDark: isDark, children: children),
    );
  }
}

/// A small caption row inside [_GroupCard], marking where one group of
/// fields ends and the next begins without needing a card of its own.
class _InlineHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  /// True when this is the very first row in the card — it gets less top
  /// padding, since there's no row above it to breathe away from.
  final bool isFirst;

  const _InlineHeader(this.title,
      {required this.isDark, this.isFirst = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(14, isFirst ? 14 : 16, 14, 6),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: CardDetailPage.faint(isDark),
          ),
        ),
      );
}

/// A plain paragraph inside [_GroupCard] — for the company's description,
/// which doesn't fit the icon/label/value shape every other row here uses.
class _InlineTextRow extends StatelessWidget {
  final String text;
  final bool isDark;

  const _InlineTextRow(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: CardDetailPage.muted(isDark),
          ),
        ),
      );
}

/// The company's identity — same icon-tile/value/chevron shape as
/// [_DetailRow] (not a bigger avatar-style block of its own), so it lines up
/// with the contact and social rows under it instead of reading as a
/// different kind of thing wedged into the same card. Taps through to the
/// company's own page, which is what the chevron implies everywhere else.
class _CompanyHeaderRow extends StatelessWidget {
  final CompanyModel company;
  final bool isDark;

  const _CompanyHeaderRow({required this.company, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final meta = [company.industry, company.businessType]
        .where((e) => e != null && e.isNotEmpty)
        .join('  ·  ');

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CompanyDetailPage(company: company)),
      ),
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
              child: Icon(Icons.apartment_rounded,
                  size: 16, color: CardDetailPage.accent(isDark)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.3,
                      color: CardDetailPage.ink(isDark),
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 12,
                        color: CardDetailPage.muted(isDark),
                      ),
                    ),
                  ],
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
              Flexible(
                child: Text(
                  '${entries[_index].key} · tap to enlarge',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: CardDetailPage.faint(isDark),
                  ),
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
