import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../network/image_url.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../widgets/app_toast.dart';
import '../widgets/my_qr_panel.dart';
import 'add_card_page.dart';
import 'deactivate_account_page.dart';

class CardDetailPage extends ConsumerWidget {
  final BusinessCardModel card;

  const CardDetailPage({super.key, required this.card});

  // Purple theme aligned with app
  static const primary = Color(0xFF6D28D9);        // #6D28D9
  static const secondary = Color(0xFFC4B5FD);      // #C4B5FD
  static const tertiary = Color(0xFFFAF7FF);       // #FAF7FF

  static const _bg = Color(0xFFFAF7FF);
  static const _ink = Color(0xFF1F1A33);
  static const _muted = Color(0xFF6B647D);
  static const _primary = Color(0xFF6D28D9);
  static const _border = Color(0xFFEDE8F5);

  // Dark mode - purple tinted
  static const _darkBg = Color(0xFF0F0A1F);
  static const _darkSurface = Color(0xFF1A1433);
  static const _darkBorder = Color(0xFF352C52);
  static const _darkInk = Color(0xFFF1E8FF);
  static const _darkMuted = Color(0xFFA89BC7);

  // Typography using desired stack (Helvetica Neue / Inter / Arial fallback)
  // These inherit the app's fontFamily + fallback from ThemeData
  static TextStyle heroNameStyle(bool isDark) => TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w900,
        color: isDark ? _darkInk : _ink,
        letterSpacing: -0.5,
        height: 1.05,
      );

  static TextStyle heroPositionStyle(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? _darkMuted : _muted,
        height: 1.3,
      );

  static TextStyle sectionTitleStyle(bool isDark) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: isDark ? _darkInk : _ink,
        letterSpacing: -0.2,
      );

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

  static TextStyle pillLabelStyle(bool isDark) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? _darkMuted : _muted,
      );

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
      backgroundColor: isDark ? _darkSurface : Colors.white,
      surfaceTintColor: isDark ? _darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? _darkBorder : _border),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? _darkInk : _ink,
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
              color: isDark ? _darkMuted : _muted,
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
            style: TextStyle(color: isDark ? _darkMuted : _muted),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(
            confirmText,
            style: TextStyle(
              color: destructive ? Colors.redAccent : _primary,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      backgroundColor: isDark ? _darkBg : CardDetailPage.tertiary,
      appBar: AppBar(
        backgroundColor: isDark ? _darkBg : CardDetailPage.tertiary,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? _darkInk : _ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isUserCard && !isMyCard)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor:
                      card.isFriend ? (isDark ? _darkMuted : _muted) : _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isDark ? _darkBorder : _border),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                ),
                onPressed: () async {
                  if (card.isFriend) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => _buildActionDialog(
                        ctx,
                        title: 'Unfriend',
                        content: 'Are you sure you want to remove this friend?',
                        confirmText: 'Unfriend',
                        destructive: true,
                        onConfirm: () => Navigator.pop(ctx, true),
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final result = await ref
                          .read(cardProvider.notifier)
                          .removeFriend(card.id);
                      if (result.isSuccess && context.mounted) {
                        _showToast(context, 'Friend removed successfully',
                            isDestructiveSoft: true);
                        Navigator.pop(context);
                      } else if (context.mounted) {
                        _showToast(context, result.message ?? 'Failed to remove friend', isError: true);
                      }
                    }
                  } else {
                    final result = await ref
                        .read(cardProvider.notifier)
                        .addFriend(card.id);
                    if (result.isSuccess && context.mounted) {
                      _showToast(context, 'Friend request sent');
                    } else if (context.mounted) {
                      _showToast(context, result.message ?? 'Failed to send friend request', isError: true);
                    }
                  }
                },
                icon: Icon(
                  card.isFriend
                      ? Icons.person_remove_alt_1_rounded
                      : Icons.person_add_alt_1_rounded,
                  size: 18,
                ),
                label: Text(
                  card.isFriend ? 'Unfriend' : 'Connect',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (isSavedCard || isMyCard)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                color: isDark ? _darkSurface : Colors.white,
                surfaceTintColor: isDark ? _darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? _darkBorder : _border),
                ),
                elevation: 2,
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddCardPage(card: card)),
                    ).then((updated) async {
                      if (!context.mounted) return;
                      if (updated == true) {
                        await ref.read(cardProvider.notifier).fetchCards();
                        if (!context.mounted) return;

                        AppToast.show(
                          context,
                          'Business card updated successfully',
                          type: AppToastType.success,
                        );

                        final cards =
                            ref.read(cardProvider).valueOrNull?.cards ?? [];
                        final updatedIndex =
                            cards.indexWhere((c) => c.id == card.id);

                        if (updatedIndex != -1) {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                              pageBuilder: (_, __, ___) => CardDetailPage(
                                card: cards[updatedIndex],
                              ),
                            ),
                          );
                        }
                      }
                    });
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
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 19,
                            color: isDark ? _darkInk : Colors.black87),
                        const SizedBox(width: 12),
                        Text(
                          'Edit',
                          style: TextStyle(
                              color: isDark ? _darkInk : Colors.black87),
                        ),
                      ],
                    ),
                  ),
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
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // ===== HERO (purple premium) =====
            _PurpleHero(
                      card: card,
                      avatarUrl: avatarUrl,
                      isDark: isDark,
                      isMyProfileCard: isMyProfileCard,
                      cardTypeLabel: card.cardType == 'saved_card' ? 'Saved' : 'Business',
                    ),

                    const SizedBox(height: 18),

                    // ===== QUICK ACTIONS (purple) =====
                    _PurpleQuickActions(
                      card: card,
                      isDark: isDark,
                      isMyProfileCard: isMyProfileCard,
                      onFriendAction: () async {
                        if (card.isFriend) {
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
                            final res = await ref
                                .read(cardProvider.notifier)
                                .removeFriend(card.id);
                            if (res.isSuccess && context.mounted) {
                              _showToast(context, 'Friend removed',
                                  isDestructiveSoft: true);
                              Navigator.pop(context);
                            } else if (context.mounted) {
                              _showToast(context, res.message ?? 'Failed to remove friend', isError: true);
                            }
                          }
                        } else {
                          final res = await ref
                              .read(cardProvider.notifier)
                              .addFriend(card.id);
                          if (res.isSuccess && context.mounted) {
                            _showToast(context, 'Friend request sent');
                          } else if (context.mounted) {
                            _showToast(context, res.message ?? 'Failed to send friend request', isError: true);
                          }
                        }
                      },
                      onShowQr: () {
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
                                color: isDark ? _darkSurface : Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20)),
                                border: Border.all(
                                  color: isDark ? _darkBorder : _border,
                                ),
                              ),
                              child: ListView(
                                controller: sc,
                                padding:
                                    const EdgeInsets.fromLTRB(24, 16, 24, 32),
                                children: [
                                  Center(
                                    child: Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isDark ? _darkBorder : _border,
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    'Share Your Card',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? _darkInk : _ink,
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
                      },
                      onEdit: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddCardPage(card: card)),
                        ).then((updated) async {
                          if (updated == true && context.mounted) {
                            await ref.read(cardProvider.notifier).fetchCards();
                            if (!context.mounted) return;

                            AppToast.show(
                                context, 'Business card updated successfully');

                            final cards =
                                ref.read(cardProvider).valueOrNull?.cards ?? [];
                            final updatedIndex =
                                cards.indexWhere((c) => c.id == card.id);
                            if (updatedIndex != -1) {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: Duration.zero,
                                  pageBuilder: (_, __, ___) =>
                                      CardDetailPage(card: cards[updatedIndex]),
                                ),
                              );
                            }
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 26),

                    // ===== BIO =====
                    if ((card.bio ?? '').trim().isNotEmpty)
                      _PurpleSection(
                        icon: Icons.format_quote_rounded,
                        title: 'About',
                        isDark: isDark,
                        child: Text(
                          card.bio!.trim(),
                          style: CardDetailPage.bodyStyle(isDark),
                        ),
                      ),

                    // ===== CONTACTS =====
                    _PurpleSection(
                      icon: Icons.contact_phone_outlined,
                      title: 'Contact',
                      isDark: isDark,
                      child: _PurpleContactList(card: card, isDark: isDark),
                    ),

                    // ===== SOCIAL LINKS =====
                    _PurpleSocialLinks(
                        socialLinks: card.socialLinks, isDark: isDark),

                    // ===== COMPANY =====
                    if (card.company != null)
                      _PurpleSection(
                        icon: Icons.apartment_outlined,
                        title: 'Company',
                        isDark: isDark,
                        child: _PurpleCompanyCard(
                            company: card.company!, isDark: isDark),
                      ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            );
          }
}

class _PurpleHero extends StatelessWidget {
  final BusinessCardModel card;
  final String? avatarUrl;
  final bool isDark;
  final bool isMyProfileCard;
  final String cardTypeLabel;

  const _PurpleHero({required this.card, required this.avatarUrl, required this.isDark, required this.isMyProfileCard, required this.cardTypeLabel});

  @override
  Widget build(BuildContext context) {
    final firstLetter = card.fullName.isNotEmpty ? card.fullName[0].toUpperCase() : '?';
    final accent = CardDetailPage.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: isDark
            ? LinearGradient(colors: [const Color(0xFF1A1433), CardDetailPage._darkSurface])
            : LinearGradient(colors: [CardDetailPage.tertiary, const Color(0xFFF3ECFF)]),
        border: Border.all(color: isDark ? CardDetailPage._darkBorder : CardDetailPage.secondary.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accent, CardDetailPage.secondary]),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? Image.network(avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _AvatarFallback(letter: firstLetter, isDark: isDark))
                      : _AvatarFallback(letter: firstLetter, isDark: isDark),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.fullName, style: CardDetailPage.heroNameStyle(isDark)),
                    Text(card.position.isEmpty ? 'Professional' : card.position, style: CardDetailPage.heroPositionStyle(isDark)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 7, children: [
                      _PurpleBadge(label: isMyProfileCard ? 'Your Profile' : cardTypeLabel, isDark: isDark),
                      if (card.isFriend) _PurpleBadge(label: 'Connected', isDark: isDark, accent: true),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          if (card.company != null && card.company!.name.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.06) : CardDetailPage.secondary.withOpacity(0.35), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.business_rounded, size: 15, color: isDark ? CardDetailPage.secondary : CardDetailPage.primary),
                const SizedBox(width: 6),
                Text(card.company!.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? CardDetailPage._darkInk : CardDetailPage._ink)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String letter;
  final bool isDark;
  const _AvatarFallback({required this.letter, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(color: isDark ? const Color(0xFF1F2A44) : const Color(0xFF3B5CCC), alignment: Alignment.center, child: Text(letter, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)));
}

class _PurpleBadge extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool accent;
  const _PurpleBadge({required this.label, required this.isDark, this.accent = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent ? CardDetailPage.primary.withOpacity(isDark ? 0.25 : 0.12) : (isDark ? CardDetailPage._darkBorder : CardDetailPage.secondary.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent ? CardDetailPage.primary.withOpacity(0.35) : (isDark ? CardDetailPage._darkBorder : CardDetailPage.secondary.withOpacity(0.6))),
      ),
      child: Text(label, style: TextStyle(color: accent ? (isDark ? CardDetailPage.secondary : CardDetailPage.primary) : (isDark ? CardDetailPage._darkMuted : CardDetailPage._muted), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
    );
  }
}

class _PurpleQuickActions extends StatelessWidget {
  final BusinessCardModel card;
  final bool isDark;
  final bool isMyProfileCard;
  final VoidCallback onFriendAction;
  final VoidCallback onShowQr;
  final VoidCallback onEdit;
  const _PurpleQuickActions({required this.card, required this.isDark, required this.isMyProfileCard, required this.onFriendAction, required this.onShowQr, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (card.phones.isNotEmpty) items.add(_PurpleActionPill(icon: Icons.call_rounded, label: 'Call', onTap: () => _launch('tel:${card.phones.first}'), isDark: isDark));
    if (card.emails.isNotEmpty) items.add(_PurpleActionPill(icon: Icons.mail_rounded, label: 'Email', onTap: () => _launch('mailto:${card.emails.first}'), isDark: isDark));
    if (card.addresses.isNotEmpty) items.add(_PurpleActionPill(icon: Icons.place_rounded, label: 'Map', onTap: () { final q = Uri.encodeComponent(card.addresses.first); _launch('https://maps.google.com/?q=$q'); }, isDark: isDark));
    if (!isMyProfileCard) items.add(_PurpleActionPill(icon: card.isFriend ? Icons.person_remove_rounded : Icons.person_add_alt_1_rounded, label: card.isFriend ? 'Unfriend' : 'Connect', onTap: onFriendAction, isDark: isDark, highlight: !card.isFriend));
    if (isMyProfileCard) {
      items.add(_PurpleActionPill(icon: Icons.qr_code_2_rounded, label: 'QR', onTap: onShowQr, isDark: isDark));
      items.add(_PurpleActionPill(icon: Icons.edit_rounded, label: 'Edit', onTap: onEdit, isDark: isDark));
    } else if (card.cardType == 'user_card') {
      items.add(_PurpleActionPill(icon: Icons.qr_code_2_rounded, label: 'QR', onTap: onShowQr, isDark: isDark));
    }
    return SizedBox(height: 80, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, i) => items[i]));
  }
  void _launch(String u) async { try { await launchUrl(Uri.parse(u)); } catch (_) {} }
}

class _PurpleActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool highlight;
  const _PurpleActionPill({required this.icon, required this.label, required this.onTap, required this.isDark, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final bg = highlight ? CardDetailPage.primary : (isDark ? CardDetailPage._darkSurface : CardDetailPage.tertiary);
    final ic = highlight ? Colors.white : (isDark ? CardDetailPage.secondary : CardDetailPage.primary);
    final tc = highlight ? Colors.white : (isDark ? CardDetailPage._darkMuted : CardDetailPage._muted);
    return Column(children: [
      Material(color: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: SizedBox(width: 56, height: 56, child: Icon(icon, size: 26, color: ic)))),
      const SizedBox(height: 5),
      Text(label, style: CardDetailPage.pillLabelStyle(isDark).copyWith(color: tc)),
    ]);
  }
}

class _PurpleSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final Widget child;
  const _PurpleSection({required this.icon, required this.title, required this.isDark, required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: isDark ? CardDetailPage.secondary : CardDetailPage.primary),
          const SizedBox(width: 8),
          Text(title, style: CardDetailPage.sectionTitleStyle(isDark)),
        ]),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? CardDetailPage._darkSurface : CardDetailPage.tertiary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? CardDetailPage._darkBorder : CardDetailPage.secondary.withOpacity(0.45)),
          ),
          child: child,
        ),
      ]),
    );
  }
}

class _PurpleContactList extends StatelessWidget {
  final BusinessCardModel card;
  final bool isDark;
  const _PurpleContactList({required this.card, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final list = <Widget>[];
    for (final p in card.phones) {
      list.add(_ContactRow(icon: Icons.phone_rounded, label: 'Phone', value: p, onTap: () => _launch('tel:$p'), isDark: isDark));
    }
    for (final e in card.emails) {
      list.add(_ContactRow(icon: Icons.email_rounded, label: 'Email', value: e, onTap: () => _launch('mailto:$e'), isDark: isDark));
    }
    for (final a in card.addresses) {
      list.add(_ContactRow(icon: Icons.location_on_rounded, label: 'Address', value: a, onTap: () { final q = Uri.encodeComponent(a); _launch('https://maps.google.com/?q=$q'); }, isDark: isDark));
    }
    if (list.isEmpty) return Text('No contact info.', style: TextStyle(color: isDark ? CardDetailPage._darkMuted : CardDetailPage._muted));
    return Column(children: list);
  }
  void _launch(String u) async { try { await launchUrl(Uri.parse(u)); } catch (_) {} }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isDark;
  const _ContactRow({required this.icon, required this.label, required this.value, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5FA), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: isDark ? CardDetailPage.secondary : CardDetailPage.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: CardDetailPage.smallMutedStyle(isDark)),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? CardDetailPage._darkInk : CardDetailPage._ink, height: 1.3)),
          ])),
        ]),
      ),
    );
  }
}

class _PurpleSocialLinks extends StatelessWidget {
  final List<dynamic>? socialLinks;
  final bool isDark;
  const _PurpleSocialLinks({this.socialLinks, required this.isDark});
  @override
  Widget build(BuildContext context) {
    if (socialLinks == null || socialLinks!.isEmpty) return const SizedBox.shrink();
    return _PurpleSection(
      icon: Icons.public,
      title: 'Social',
      isDark: isDark,
      child: Wrap(spacing: 8, children: socialLinks!.map((s) {
        final m = s is Map ? Map<String,dynamic>.from(s) : <String,dynamic>{};
        final plat = (m['platform'] ?? 'link').toString();
        final url = m['url']?.toString() ?? '';
        return ActionChip(
          label: Text(plat),
          onPressed: () async { if (url.isNotEmpty) { try { await launchUrl(Uri.parse(url)); } catch (_) {} } },
        );
      }).toList()),
    );
  }
}

class _PurpleCompanyCard extends StatelessWidget {
  final CompanyModel company;
  final bool isDark;
  const _PurpleCompanyCard({required this.company, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(company.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isDark ? CardDetailPage._darkInk : CardDetailPage._ink, letterSpacing: -0.3)),
      if ((company.industry ?? '').isNotEmpty || (company.businessType ?? '').isNotEmpty)
        Text([company.industry, company.businessType].where((e) => e != null && e!.isNotEmpty).join(' • '), style: CardDetailPage.smallMutedStyle(isDark)),
      if ((company.website ?? '').isNotEmpty) _CompanyRow(icon: Icons.language, text: company.website!),
      if ((company.phone ?? '').isNotEmpty) _CompanyRow(icon: Icons.phone, text: company.phone!),
      if ((company.email ?? '').isNotEmpty) _CompanyRow(icon: Icons.email, text: company.email!),
    ]);
  }
}

class _CompanyRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CompanyRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [Icon(icon, size: 16), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)))]));
}
