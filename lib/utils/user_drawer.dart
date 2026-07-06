import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth/auth_provider.dart';
import '../providers/card/card_provider.dart';
import '../network/image_url.dart';
import '../ui/theme/app_colors.dart';
import '../ui/theme/theme_provider.dart';
import '../data/vos/business_card_model.dart';
import '../data/vos/user_model.dart';
import '../ui/pages/card_detail_page.dart';
import '../ui/pages/company_select_page.dart';

class UserDrawer extends ConsumerWidget {
  const UserDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider).valueOrNull ?? ThemeMode.system;
    final isThemeDark = themeMode == ThemeMode.dark;
    final authState = ref.watch(authProvider).valueOrNull ?? AuthState();
    final currentUser = authState.currentUser;
    final cardState = ref.watch(cardProvider).valueOrNull ?? CardState();

    // Find "my account" profile card (the user's own business card of type 'user_card')
    BusinessCardModel? myAccountCard;
    if (currentUser != null) {
      myAccountCard = _findMyAccountCard(cardState.cards, currentUser);

      // If no cards loaded yet, trigger a background fetch so next click can find the profile card
      if (myAccountCard == null && cardState.cards.isEmpty) {
        Future.microtask(() {
          ref.read(cardProvider.notifier).fetchCards();
        });
      }
    }

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModernHeader(currentUser, myAccountCard, isDark, () async {
              // Click on "my account" (avatar + name) in sidebar -> go to my account detail page (card detail)
              final navigator = Navigator.of(context);
              navigator.pop();

              BusinessCardModel? accountCard = myAccountCard;

              if (accountCard == null) {
                // Cards might not be loaded yet — fetch latest
                await ref.read(cardProvider.notifier).fetchCards();
                final latestCards =
                    ref.read(cardProvider).valueOrNull?.cards ?? [];
                accountCard = _findMyAccountCard(latestCards, currentUser);
              }

              final accountCardToOpen = accountCard;
              if (accountCardToOpen != null) {
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => CardDetailPage(card: accountCardToOpen),
                  ),
                );
              } else if (currentUser != null) {
                final fallbackCard = BusinessCardModel(
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
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => CardDetailPage(card: fallbackCard),
                  ),
                );
              }
            }),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  _buildMenuTile(
                    icon: Icons.business_rounded,
                    title: 'Manage Companies',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const CompanySelectPage(isSelectionMode: false),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  // Theme toggle — styled nicely
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard.withOpacity(0.65) : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      secondary: Icon(
                        Icons.palette_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1F2937),
                        ),
                      ),
                      subtitle: Text(
                        isThemeDark ? 'Dark mode' : 'Light mode',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF98A7C2) : Colors.black54,
                        ),
                      ),
                      value: isThemeDark,
                      activeColor: AppColors.primary,
                      onChanged: (_) {
                        ref.read(themeProvider.notifier).toggle();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).logout();
                    },
                    isDark: isDark,
                    destructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(UserModel? user, BusinessCardModel? accountCard, bool isDark, VoidCallback onAccountTap) {
    final name = user?.name ?? 'User';
    final email = user?.email ?? '';
    final profileImage = accountCard?.profileImage;
    final hasImage = profileImage != null && profileImage.isNotEmpty;
    final avatarUrl = hasImage ? ImageUrl.resolve(profileImage) : null;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: onAccountTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkCard, AppColors.darkSurfaceAlt]
                : [AppColors.secondary.withOpacity(0.85), AppColors.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Avatar with purple gradient ring (matches the premium style in card detail)
            Container(
              padding: const EdgeInsets.all(3.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: !hasImage
                    ? Text(
                        initial,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.secondary : AppColors.primaryDark,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF8FBFF) : const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF9AA8C7) : const Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool destructive = false,
  }) {
    final iconColor = destructive ? Colors.redAccent : AppColors.primary;
    final textColor = destructive
        ? Colors.redAccent
        : (isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1F2937));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark ? AppColors.darkCard.withOpacity(0.65) : AppColors.surfaceSoft,
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BusinessCardModel? _findMyAccountCard(
      List<BusinessCardModel> cards, UserModel? currentUser) {
    if (currentUser == null) return null;
    final userEmail = (currentUser.email ?? '').trim().toLowerCase();
    try {
      return cards.firstWhere((c) {
        if (c.cardType != 'user_card') return false;

        // Primary: ownership via user.id or createdBy (most reliable)
        if (c.user?.id == currentUser.id) return true;
        if (c.createdBy == currentUser.id) return true;

        // Fallback: email match on the card
        if (userEmail.isNotEmpty &&
            c.emails.any((e) => e.trim().toLowerCase() == userEmail)) {
          return true;
        }
        return false;
      });
    } catch (_) {
      return null;
    }
  }
}
