import 'package:flutter/material.dart';
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/locale/locale_provider.dart';
import '../theme/wallet_tokens.dart';
import 'deactivate_account_page.dart';

/// Account basics and the one account-level action that already exists
/// elsewhere (Deactivate Account, previously only reachable from the
/// profile card's overflow menu). Anything more — notification prefs,
/// theme override, etc. — was explicitly left out of this pass; add
/// sections here as they're actually needed rather than stubbing them now.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String _languageLabel(AppLocalizations l10n, Locale locale) {
    return locale.languageCode == 'my' ? l10n.languageBurmese : l10n.languageEnglish;
  }

  Future<void> _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = ref.read(localeProvider);

    final selected = await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: isDark ? Wallet.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
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
                    l10n.chooseLanguageTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Wallet.darkInk : Wallet.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.chooseLanguageSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Wallet.darkMuted : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _LanguageOptionTile(
              label: l10n.languageEnglish,
              selected: current.languageCode == 'en',
              isDark: isDark,
              onTap: () => Navigator.of(sheetContext).pop(const Locale('en')),
            ),
            _LanguageOptionTile(
              label: l10n.languageBurmese,
              selected: current.languageCode == 'my',
              isDark: isDark,
              onTap: () => Navigator.of(sheetContext).pop(const Locale('my')),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null) {
      await ref.read(localeProvider.notifier).setLocale(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(authProvider).valueOrNull?.currentUser;
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Wallet.groundOf(isDark),
      appBar: AppBar(
        backgroundColor: Wallet.groundOf(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Wallet.inkOf(isDark),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _SectionLabel(l10n.settingsAccountSection, isDark: isDark),
          _GroupCard(
            isDark: isDark,
            children: [
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: l10n.settingsName,
                value: currentUser?.name ?? '—',
                isDark: isDark,
              ),
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: l10n.settingsEmail,
                value: currentUser?.email ?? '—',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.settingsLanguageSection, isDark: isDark),
          _GroupCard(
            isDark: isDark,
            children: [
              _ValueActionRow(
                icon: Icons.translate_rounded,
                label: l10n.settingsLanguage,
                value: _languageLabel(l10n, locale),
                isDark: isDark,
                onTap: () => _showLanguageSheet(context, ref, l10n),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.settingsAccountActionsSection, isDark: isDark),
          _GroupCard(
            isDark: isDark,
            children: [
              _ActionRow(
                icon: Icons.no_accounts_outlined,
                label: l10n.settingsDeactivateAccount,
                destructive: true,
                isDark: isDark,
                onTap: () => Navigator.of(context).push(
                  AppPageRoute(
                    builder: (_) => const DeactivateAccountPage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? (isDark ? Colors.white : Wallet.accentOf(isDark))
                        : (isDark ? Wallet.darkInk : Wallet.ink),
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 18, color: Wallet.accentOf(isDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionLabel(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 9, top: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.25,
            color: Wallet.faintOf(isDark),
          ),
        ),
      );
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _GroupCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Wallet.surfaceOf(isDark),
        borderRadius: BorderRadius.circular(Wallet.radiusPanel),
        border: isDark ? Border.all(color: Wallet.darkLine) : null,
        boxShadow: Wallet.shadowOf(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, indent: 58, color: Wallet.lineOf(isDark)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Wallet.tintOf(isDark),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Wallet.accentOf(isDark)),
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
                    color: Wallet.faintOf(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Wallet.inkOf(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Like [_InfoRow], but tappable — shows the current value of a setting and
/// opens a picker to change it (a chevron makes that affordance clear).
class _ValueActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _ValueActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onTap,
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
                color: Wallet.tintOf(isDark),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: Wallet.accentOf(isDark)),
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
                      color: Wallet.faintOf(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Wallet.inkOf(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: Wallet.faintOf(isDark)),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool destructive;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFDC2626) : Wallet.accentOf(isDark);
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
                color: color.withOpacity(isDark ? .16 : .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: Wallet.faintOf(isDark)),
          ],
        ),
      ),
    );
  }
}
