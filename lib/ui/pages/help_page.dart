import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/wallet_tokens.dart';

/// The support email shown on this page. Placeholder — swap for the real
/// support address before shipping.
const _supportEmail = 'support@businesscard4u.app';

Future<void> _openLink(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// Contact support, a short tour of what the app actually does, and a
/// handful of FAQs written from what the app's own flows do — not sourced
/// from real support tickets, so revise wording once real questions come
/// in.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final faqs = [
      (l10n.helpPageFaq1Question, l10n.helpPageFaq1Answer),
      (l10n.helpPageFaq2Question, l10n.helpPageFaq2Answer),
      (l10n.helpPageFaq3Question, l10n.helpPageFaq3Answer),
      (l10n.helpPageFaq4Question, l10n.helpPageFaq4Answer),
    ];

    return Scaffold(
      backgroundColor: Wallet.groundOf(isDark),
      appBar: AppBar(
        backgroundColor: Wallet.groundOf(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Wallet.inkOf(isDark),
        title: Text(l10n.helpPageTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _Section(
            title: l10n.helpPageContactSection,
            isDark: isDark,
            child: _Card(
              isDark: isDark,
              child: InkWell(
                onTap: () => _openLink('mailto:$_supportEmail'),
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
                        child: Icon(Icons.mail_outline_rounded,
                            size: 16, color: Wallet.accentOf(isDark)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.helpPageContactSupport,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Wallet.inkOf(isDark),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _supportEmail,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Wallet.mutedOf(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: Wallet.faintOf(isDark)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.helpPageHowItWorksSection,
            isDark: isDark,
            child: _Card(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Feature(
                      icon: Icons.document_scanner_outlined,
                      text: l10n.helpPageFeatureScan,
                      isDark: isDark,
                    ),
                    _Feature(
                      icon: Icons.apartment_rounded,
                      text: l10n.helpPageFeatureCompany,
                      isDark: isDark,
                    ),
                    _Feature(
                      icon: Icons.qr_code_2_rounded,
                      text: l10n.helpPageFeatureQr,
                      isDark: isDark,
                    ),
                    _Feature(
                      icon: Icons.people_alt_outlined,
                      text: l10n.helpPageFeatureFriends,
                      isDark: isDark,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.helpPageFaqSection,
            isDark: isDark,
            child: _Card(
              isDark: isDark,
              child: Column(
                children: [
                  for (var i = 0; i < faqs.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: Wallet.lineOf(isDark)),
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        expandedAlignment: Alignment.centerLeft,
                        iconColor: Wallet.accentOf(isDark),
                        collapsedIconColor: Wallet.faintOf(isDark),
                        title: Text(
                          faqs[i].$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Wallet.inkOf(isDark),
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              faqs[i].$2,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Wallet.mutedOf(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _Section({required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 9),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.25,
                color: Wallet.faintOf(isDark),
              ),
            ),
          ),
          child,
        ],
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Wallet.surfaceOf(isDark),
          borderRadius: BorderRadius.circular(Wallet.radiusPanel),
          border: isDark ? Border.all(color: Wallet.darkLine) : null,
          boxShadow: Wallet.shadowOf(isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final bool isLast;

  const _Feature({
    required this.icon,
    required this.text,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Wallet.accentOf(isDark)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Wallet.mutedOf(isDark),
                ),
              ),
            ),
          ],
        ),
      );
}
