import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/theme_toggle_button.dart';
import '../../data/vos/company_model.dart';

class CompanyDetailPage extends StatelessWidget {
  final CompanyModel company;

  const CompanyDetailPage({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060B16) : const Color(0xFFF8FAFD),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainInfo(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Contact Details"),
                  _buildContactCard(context),
                  const SizedBox(height: 24),
                  if (company.description != null && company.description!.isNotEmpty) ...[
                    _buildSectionTitle(context, "About Company"),
                    _buildAboutCard(context),
                    const SizedBox(height: 24),
                  ],
                  if (company.socials.isNotEmpty) ...[
                    _buildSectionTitle(context, "Social Presence"),
                    _buildSocialsCard(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF060B16) : const Color(0xFF1E3C72),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: const [
        ThemeToggleButton(color: Colors.white),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF070D19), Color(0xFF172443)]
                  : const [Color(0xFF1E3C72), Color(0xFF2A5298)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business_rounded, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  company.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1426) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2A44) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _infoItem(context, Icons.category_rounded, company.industry ?? "General"),
          const VerticalDivider(),
          _infoItem(context, Icons.work_outline_rounded, company.businessType ?? "Corporate"),
        ],
      ),
    );
  }

  Widget _infoItem(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: isDark ? const Color(0xFF8FB6FF) : AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1426) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2A44) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          if (company.email != null)
            _contactTile(
              context,
              Icons.email_outlined,
              company.email!,
              onTap: () => _launchEmail(company.email!),
            ),
          if (company.phone != null)
            _contactTile(
              context,
              Icons.phone_android_rounded,
              company.phone!,
              onTap: () => _launchPhone(company.phone!),
            ),
          if (company.website != null)
            _contactTile(
              context,
              Icons.language_rounded,
              company.website!,
              onTap: () => _launchWebsite(company.website!),
            ),
          if (company.address != null)
            _contactTile(
              context,
              Icons.location_on_outlined,
              company.address!,
              onTap: () => _launchMaps(company.address!),
            ),
        ],
      ),
    );
  }

  Widget _contactTile(BuildContext context, IconData icon, String text, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: isDark ? const Color(0xFF8FB6FF) : Colors.blueGrey, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isDark ? const Color(0xFFEAF1FF) : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1426) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2A44) : Colors.transparent,
        ),
      ),
      child: Text(
        company.description!,
        style: TextStyle(
          color: isDark ? const Color(0xFF98A7C2) : Colors.black54,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSocialsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1426) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2A44) : Colors.transparent,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: company.socials.map((s) => _socialChip(context, s.platform)).toList(),
      ),
    );
  }

  Widget _socialChip(BuildContext context, String platform) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF131D31)
            : const Color(0xFF2563EB).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF24304B)
              : const Color(0xFF2563EB).withOpacity(0.1),
        ),
      ),
      child: Text(
        platform,
        style: TextStyle(
          color: isDark ? const Color(0xFFD8E4FF) : const Color(0xFF2563EB),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _launchWebsite(String url) async {
    final hasScheme = url.startsWith('http://') || url.startsWith('https://');
    final uri = Uri.parse(hasScheme ? url : 'https://$url');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchMaps(String query) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
