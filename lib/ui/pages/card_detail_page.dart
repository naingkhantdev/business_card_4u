import 'package:flutter/material.dart';
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../network/image_url.dart';
import '../../data/vos/address_model.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../utils/full_image_viewer.dart';
import '../responsive/responsive.dart';
import '../widgets/app_toast.dart';
import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';
import '../widgets/my_qr_panel.dart';
import '../widgets/profession_picker.dart';
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

  /// The page's only framing: a hairline, no shadow. Shadows on every block
  /// made the page read as a stack of floating cards rather than one sheet.
  static Border hairline(bool isDark) => Wallet.borderOf(isDark);

  // Typography using desired stack (Helvetica Neue / Inter / Arial fallback)
  // These inherit the app's fontFamily + fallback from ThemeData
  // The hero and section headers now style themselves; what remains here is
  // what more than one widget shares.
  static TextStyle bodyStyle(bool isDark) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? Wallet.darkInk : Wallet.ink,
        height: 1.55,
      );

  static TextStyle smallMutedStyle(bool isDark) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: isDark ? Wallet.darkMuted : Wallet.muted,
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
      AppPageRoute(builder: (_) => AddCardPage(card: card)),
    );
    if (!mounted || updated != true) return;

    final currentUser = ref.read(authProvider).valueOrNull?.currentUser;
    await ref.read(cardProvider.notifier).fetchCards();
    if (!mounted) return;

    AppToast.show(
      context,
      AppLocalizations.of(context)!.cardDetailUpdateSuccess,
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
      backgroundColor: Wallet.surfaceOf(isDark),
      surfaceTintColor: Wallet.surfaceOf(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? Wallet.darkLine : Wallet.line),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Wallet.darkInk : Wallet.ink,
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
              color: isDark ? Wallet.darkMuted : Wallet.muted,
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
            AppLocalizations.of(context)!.cardDetailCancel,
            style: TextStyle(color: isDark ? Wallet.darkMuted : Wallet.muted),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(
            confirmText,
            style: TextStyle(
              color: destructive ? Wallet.danger : Wallet.accentOf(isDark),
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
      AppPageRoute(builder: (_) => const DeactivateAccountPage()),
    );
  }

  /// The QR sheet. Lifted out of the body so the overflow menu is its only
  /// caller — sharing used to be reachable from two places at once.
  void _showQrSheet(BusinessCardModel card, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
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
            color: Wallet.surfaceOf(isDark),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark
                  ? Wallet.darkLine
                  : Wallet.line,
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
                        ? Wallet.darkLine
                        : Wallet.line,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.cardDetailShareYourCard,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Wallet.darkInk
                      : Wallet.ink,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cardDetailShareYourCardSubtitle,
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
    final l10n = AppLocalizations.of(context)!;
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

    // One plain sheet, not boxes on a tinted ground — sections are told apart
    // by their captions and hairlines alone.
    return Scaffold(
      backgroundColor: Wallet.surfaceOf(isDark),
      appBar: AppBar(
        backgroundColor: Wallet.surfaceOf(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? Wallet.darkInk : Wallet.ink,
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
                color: Wallet.surfaceOf(isDark),
                surfaceTintColor: Wallet.surfaceOf(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Wallet.darkLine : Wallet.line),
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
                        title: l10n.cardDetailDeleteCardTitle,
                        content: l10n.cardDetailDeleteCardBody,
                        confirmText: l10n.cardDetailDelete,
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
                              l10n.cardDetailDeleteSuccess,
                          isDestructiveSoft: true,
                        );
                        Navigator.pop(context);
                      } else {
                        _showToast(
                          context,
                          deleteMessage ??
                              result.message ??
                              l10n.cardDetailDeleteFailed,
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
                              color: Wallet.inkOf(isDark)),
                          const SizedBox(width: 12),
                          Text(
                            isMyProfileCard
                                ? l10n.cardDetailShareMyCard
                                : l10n.cardDetailShare,
                            style: TextStyle(
                                color: Wallet.inkOf(isDark)),
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
                              color: Wallet.inkOf(isDark)),
                          const SizedBox(width: 12),
                          Text(
                            l10n.cardDetailEdit,
                            style: TextStyle(
                                color: Wallet.inkOf(isDark)),
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
                              size: 19, color: Wallet.danger),
                          const SizedBox(width: 12),
                          Text(
                            isMyProfileCard
                                ? l10n.cardDetailDeactivateAccount
                                : l10n.cardDetailDelete,
                            style: const TextStyle(color: Wallet.danger),
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
            cardTypeLabel: card.cardType == 'saved_card'
                ? l10n.cardDetailTypeSaved
                : l10n.cardDetailTypeBusiness,
            isFriend: isFriend,
            // A portrait belongs to a person's own card. A saved card is a
            // photo of someone's printed card — it has no portrait, so that
            // slot shows the printed card itself instead (see cardPhotoUrls
            // below).
            showAvatar: isUserCard,
            cardPhotoUrls: cardPhotoUrls,
          ),

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.isDesktop(context) ? 720 : double.infinity,
              ),
              child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
                              title: l10n.cardDetailUnfriend,
                              content: l10n.cardDetailUnfriendBody,
                              confirmText: l10n.cardDetailUnfriend,
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
                              _showToast(context, l10n.cardDetailFriendRemoved, isDestructiveSoft: true);
                            } else {
                              _showToast(context, res.message ?? l10n.cardDetailFriendRemoveFailed, isError: true);
                            }
                          }
                        } else if (friendRequestStatus == 'pending_sent' || friendRequestStatus == 'pending') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => _buildActionDialog(
                              ctx,
                              title: l10n.cardDetailCancelRequest,
                              content: l10n.cardDetailCancelRequestBody,
                              confirmText: l10n.cardDetailCancelRequest,
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
                              _showToast(context, l10n.cardDetailFriendRequestCancelled, isDestructiveSoft: true);
                            } else {
                              _showToast(context, res.message ?? l10n.cardDetailCancelRequestFailed, isError: true);
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
                            _showToast(context, l10n.cardDetailFriendRequestSent);
                          } else {
                            _showToast(context, res.message ?? l10n.cardDetailFriendRequestSendFailed, isError: true);
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
                          _showToast(context, l10n.cardDetailFriendRequestAccepted);
                        } else {
                          _showToast(context, res.message ?? l10n.cardDetailAcceptRequestFailed, isError: true);
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
                          _showToast(context, l10n.cardDetailFriendRequestDeclined, isDestructiveSoft: true);
                        } else {
                          _showToast(context, res.message ?? l10n.cardDetailDeclineRequestFailed, isError: true);
                        }
                      },
                    ),

                    // ===== BIO =====
                    // On its own surface, like every block below it — plain
                    // text floating between the actions and the first card
                    // used to read as unfinished rather than intentional.
                    if ((card.bio ?? '').trim().isNotEmpty) ...[
                      _SectionLabel(l10n.cardDetailAbout, isDark: isDark),
                      _GroupCard(
                        isDark: isDark,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              card.bio!.trim(),
                              style: CardDetailPage.bodyStyle(isDark)
                                  .copyWith(fontSize: 14, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ===== COMPANY, then CONTACT / SOCIAL =====
                    // Two surfaces, not one: company details (its own phone,
                    // email, address) sitting in the same card as the
                    // person's made it easy to misread whose number you were
                    // looking at. A gap between cards reads as "these are two
                    // different things" more clearly than a caption can.
                    _DetailsCard(card: card, isDark: isDark),

                    // ===== THE PRINTED CARD =====
                    // Own profile and friends' cards — not saved cards,
                    // whose front/back photos now live in the hero above (a
                    // _CardCarousel there too) and would just repeat here.
                    if (cardPhotoUrls.isNotEmpty && !isSavedCard) ...[
                      _SectionLabel(l10n.cardDetailBusinessCardSection, isDark: isDark),
                      _CardCarousel(photos: cardPhotoUrls, isDark: isDark),
                    ]
                    // Only your own card gets an invitation to add what's
                    // missing — there's no editing a friend's card from here.
                    else if (isMyProfileCard) ...[
                      _SectionLabel(l10n.cardDetailBusinessCardSection, isDark: isDark),
                      _SecondaryButton(
                        icon: Icons.add_a_photo_outlined,
                        label: l10n.cardDetailAddFrontBackPhotos,
                        onTap: () => _openCardEditor(card),
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The identity: a compact avatar beside the name, role, and a status chip, on
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

  /// Only a person's own card carries a portrait; a saved card shows the
  /// printed card itself in that spot instead — see [cardPhotoUrls].
  final bool showAvatar;

  /// Front/back photos of the physical card, keyed by label. Used to fill
  /// the identity slot for a saved card, which has no portrait of its own.
  final Map<String, String> cardPhotoUrls;

  const _PremiumHero({
    required this.card,
    required this.avatarUrl,
    required this.isDark,
    required this.isMyProfileCard,
    required this.cardTypeLabel,
    required this.isFriend,
    required this.showAvatar,
    required this.cardPhotoUrls,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstLetter =
        card.fullName.isNotEmpty ? card.fullName[0].toUpperCase() : '?';
    final company = card.company?.name ?? '';
    final subtitle = [
      if (card.position.isNotEmpty) card.position,
      if (company.isNotEmpty) company,
    ].join('  ·  ');

    final chip = isMyProfileCard
        ? l10n.cardDetailYourProfile
        : isFriend
            ? l10n.cardDetailConnected
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
        _QuickAction(Icons.call_rounded, l10n.cardDetailCall,
            () => _openLink('tel:${card.phones.first}')),
      if (card.emails.isNotEmpty)
        _QuickAction(Icons.mail_rounded, l10n.cardDetailEmail,
            () => _openLink('mailto:${card.emails.first}')),
      if (mapAddress != null)
        _QuickAction(
            Icons.map_rounded,
            l10n.cardDetailMap,
            () => _openLink(
                'https://maps.google.com/?q=${Uri.encodeComponent(mapAddress.displayText)}')),
      if (companyWebsite != null && companyWebsite.isNotEmpty)
        _QuickAction(Icons.language_rounded, l10n.cardDetailWebsite,
            () => _openLink(_normalizeUrl(companyWebsite))),
    ];

    const avatarSize = 60.0;

    // Avatar sits beside the name rather than stacked above it — the stacked,
    // centered layout spent most of the hero's height on whitespace before
    // the reader reached anything they could act on.
    Widget avatarCircle(Widget child) => Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Wallet.accentDark.withOpacity(.16)
                : Wallet.accentSoft,
            border: Border.all(
              color: Wallet.accentOf(isDark).withOpacity(.25),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

    final showCarousel = !showAvatar && cardPhotoUrls.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showCarousel) ...[
                  // Full-width and swipeable between front/back, same as the
                  // old lower "Business card" section this replaced — a
                  // saved card's photo is the point of this page, not a
                  // small teaser for it.
                  _CardCarousel(photos: cardPhotoUrls, isDark: isDark),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    if (showAvatar)
                      avatarCircle(avatarUrl != null
                          ? Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _AvatarFallback(
                                  letter: firstLetter, isDark: isDark),
                            )
                          : _AvatarFallback(
                              letter: firstLetter, isDark: isDark))
                    else if (!showCarousel)
                      avatarCircle(_AvatarFallback(
                          icon: Icons.badge_rounded, isDark: isDark)),
                    if (showAvatar || !showCarousel)
                      const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.45,
                              height: 1.15,
                              color: Wallet.inkOf(isDark),
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: Wallet.mutedOf(isDark),
                              ),
                            ),
                          ],
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _Chip(label: chip, isDark: isDark),
                              if ((card.profession ?? '').isNotEmpty)
                                _Chip(
                                    label: professionLabel(
                                        l10n, card.profession!),
                                    isDark: isDark),
                              if (tag.isNotEmpty)
                                _Chip(label: tag, isDark: isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (quickActions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  // Equal-width slots so a 4-action row always fits on one
                  // line; a fixed gap pushed it onto two on a normal phone.
                  Row(
                    children: [
                      for (var i = 0; i < quickActions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _QuickActionButton(
                              action: quickActions[i], isDark: isDark),
                        ),
                      ],
                    ],
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.cardDetailAddedOn(_formatDate(createdAt)),
                    style: TextStyle(
                      fontSize: 11,
                      color: Wallet.faintOf(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Wallet.lineOf(isDark)),
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

/// One of the hero's quick actions (call, email, map, website) — a compact
/// tinted pill with the icon and label on one line, so the row costs a
/// single short line of height instead of a big icon stacked over a label.
class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  final bool isDark;

  const _QuickActionButton({required this.action, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = Wallet.accentOf(isDark);
    return Material(
      color: isDark
          ? Wallet.accentDark.withOpacity(.14)
          : Wallet.accentSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 16, color: accent),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
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
              ? Wallet.accentDark.withOpacity(.14)
              : Wallet.accentSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.eyebrow(
            color: Wallet.accentOf(isDark),
            fontSize: 9,
            fontWeight: FontWeight.w700,
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
            ? Wallet.accentDark.withOpacity(.16)
            : Wallet.accentSoft,
        child: icon != null
            ? Icon(icon, size: 26, color: Wallet.accentOf(isDark))
            : Text(
                letter!,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Wallet.accentOf(isDark),
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
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: AppTypography.eyebrow(
            color: Wallet.faintOf(isDark),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

/// A frameless group of rows. Rows are separated by hairlines, so the group
/// still reads as one object without a box of its own around it.
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
                indent: children[i] is _InlineHeader ? 0 : 32,
                color: Wallet.lineOf(isDark),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One detail: a plain icon, the value, and its label underneath. The whole
/// row is the action — tapping the phone number calls it — so it carries no
/// chevron; the value itself is what the eye is looking for.
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Wallet.mutedOf(isDark)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                      height: 1.3,
                      color: Wallet.inkOf(isDark),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Wallet.faintOf(isDark),
                    ),
                  ),
                ],
              ),
            ),
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
        color: Wallet.accentOf(isDark),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 18,
                      color: Wallet.onAccentOf(isDark)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
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
        ? Wallet.danger
        : Wallet.inkOf(isDark);
    return Opacity(
      opacity: onTap == null ? .55 : 1,
      child: Material(
        color: Wallet.surfaceOf(isDark),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: CardDetailPage.hairline(isDark),
            ),
            child: SizedBox(
              height: 46,
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

    final l10n = AppLocalizations.of(context)!;
    final Widget content;
    if (isFriend) {
      content = _SecondaryButton(
        icon: Icons.person_remove_alt_1_rounded,
        label: l10n.cardDetailUnfriend,
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
              label: l10n.cardDetailAccept,
              onTap: isProcessing ? null : onAcceptFriend,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _SecondaryButton(
              icon: Icons.close_rounded,
              label: l10n.cardDetailDecline,
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
        label: l10n.cardDetailRequestSent,
        onTap: isProcessing ? null : onFriendAction,
        isDark: isDark,
      );
    } else {
      content = _PrimaryButton(
        icon: Icons.person_add_alt_1_rounded,
        label: l10n.cardDetailConnect,
        onTap: isProcessing ? null : onFriendAction,
        isDark: isDark,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
    final l10n = AppLocalizations.of(context)!;
    final companyChildren = <Widget>[];

    final company = card.company;
    if (company != null) {
      companyChildren
          .add(_InlineHeader(l10n.cardDetailCompanyHeader, isDark: isDark, isFirst: true));
      companyChildren.add(_CompanyHeaderRow(company: company, isDark: isDark));
      if ((company.description ?? '').trim().isNotEmpty) {
        companyChildren
            .add(_InlineTextRow(company.description!.trim(), isDark: isDark));
      }
      // Same row shape as the Contact section below, not a quieter,
      // non-tappable readout of the same kind of data — a phone number
      // should look and behave the same whether it's the company's or the
      // person's.
      if ((company.address ?? '').isNotEmpty) {
        companyChildren.add(_DetailRow(
          icon: Icons.place_outlined,
          label: l10n.cardDetailAddress,
          value: company.address!,
          onTap: () => _openLink(
              'https://maps.google.com/?q=${Uri.encodeComponent(company.address!)}'),
          isDark: isDark,
        ));
      }
      if ((company.website ?? '').isNotEmpty) {
        companyChildren.add(_DetailRow(
          icon: Icons.language_rounded,
          label: l10n.cardDetailWebsite,
          value: company.website!,
          onTap: () => _openLink(_normalizeUrl(company.website!)),
          isDark: isDark,
        ));
      }
      if ((company.phone ?? '').isNotEmpty) {
        companyChildren.add(_DetailRow(
          icon: Icons.call_rounded,
          label: l10n.cardDetailPhone,
          value: company.phone!,
          onTap: () => _openLink('tel:${company.phone}'),
          isDark: isDark,
        ));
      }
      if ((company.email ?? '').isNotEmpty) {
        companyChildren.add(_DetailRow(
          icon: Icons.mail_outline_rounded,
          label: l10n.cardDetailEmail,
          value: company.email!,
          onTap: () => _openLink('mailto:${company.email}'),
          isDark: isDark,
        ));
      }
      // The company's own social links — separate from the card's own
      // `socialLinks` below, which belong to the person, not the business.
      for (final s in company.socials) {
        companyChildren.add(_DetailRow(
          icon: _socialIconFor(s.platform),
          label: s.platform,
          value: s.url,
          onTap: () => _openLink(s.url),
          isDark: isDark,
        ));
      }
    }

    final contactSocialChildren = <Widget>[];

    final contactRows = <Widget>[
      for (final p in card.phones)
        _DetailRow(
            icon: Icons.call_rounded,
            label: l10n.cardDetailPhone,
            value: p,
            onTap: () => _openLink('tel:$p'),
            isDark: isDark),
      for (final e in card.emails)
        _DetailRow(
            icon: Icons.mail_outline_rounded,
            label: l10n.cardDetailEmail,
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
              label: l10n.cardDetailAddress,
              value: a.displayText,
              onTap: () => _openLink(
                  'https://maps.google.com/?q=${Uri.encodeComponent(a.displayText)}'),
              isDark: isDark),
    ];
    if (contactRows.isNotEmpty) {
      contactSocialChildren.add(_InlineHeader(l10n.cardDetailContactHeader,
          isDark: isDark, isFirst: companyChildren.isEmpty));
      contactSocialChildren.addAll(contactRows);
    }

    final socialRows = <Widget>[];
    for (final s in card.socialLinks ?? const []) {
      final m = s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{};
      final platform = (m['platform'] ?? l10n.cardDetailSocialLinkFallback).toString();
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
      contactSocialChildren.add(_InlineHeader(l10n.cardDetailSocialHeader,
          isDark: isDark,
          isFirst: companyChildren.isEmpty && contactSocialChildren.isEmpty));
      contactSocialChildren.addAll(socialRows);
    }

    // One continuous list. Whose number is whose is carried by the COMPANY /
    // CONTACT captions and the full-width rule above each of them, not by
    // putting each group in a box of its own.
    final rows = [...companyChildren, ...contactSocialChildren];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _GroupCard(isDark: isDark, children: rows),
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
        padding: EdgeInsets.fromLTRB(0, isFirst ? 4 : 18, 0, 2),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Wallet.faintOf(isDark),
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
        // Left edge matches every other row's text (18 icon + 14 gap = 32) —
        // flush left made the description jut out past the name/address/
        // phone rows above and below it.
        padding: const EdgeInsets.fromLTRB(32, 0, 0, 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Wallet.mutedOf(isDark),
          ),
        ),
      );
}

/// The company's identity — same plain-icon/value shape as [_DetailRow]
/// (not a bigger avatar-style block of its own), so it lines up
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
        AppPageRoute(builder: (_) => CompanyDetailPage(company: company)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.apartment_rounded,
                size: 18, color: Wallet.mutedOf(isDark)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.3,
                      color: Wallet.inkOf(isDark),
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 12,
                        color: Wallet.mutedOf(isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Wallet.faintOf(isDark)),
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
                  borderRadius: BorderRadius.circular(14),
                  color: Wallet.surfaceOf(isDark),
                  border: CardDetailPage.hairline(isDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image(
                  image: _provider(entries[i].value),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Wallet.surfaceOf(isDark),
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image_outlined,
                        color: Wallet.faintOf(isDark)),
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
                        ? Wallet.accentOf(isDark)
                        : Wallet.accentOf(isDark).withOpacity(.22),
                  ),
                ),
              const Spacer(),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!
                      .cardDetailTapToEnlarge(entries[_index].key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Wallet.faintOf(isDark),
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
