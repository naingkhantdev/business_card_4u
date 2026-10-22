import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/company/company_provider.dart';
import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../../data/vos/company_model.dart';
import '../widgets/app_toast.dart';
import 'company_detail_page.dart'; // Uncommented
import 'company_form_page.dart';
import '../theme/wallet_tokens.dart';

class CompanySelectPage extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const CompanySelectPage({
    super.key,
    this.isSelectionMode =
        true, // Default to true for backward compatibility with AddCardPage
  });

  @override
  ConsumerState<CompanySelectPage> createState() => _CompanySelectPageState();
}

class _CompanySelectPageState extends ConsumerState<CompanySelectPage> {
  final ScrollController _scrollController = ScrollController();

  /// Whether the add button shows its label; see [_onScroll].
  bool _fabExtended = true;

  @override
  void initState() {
    super.initState();
    // No fetch here: watching companyProvider runs its `build`, which loads the
    // list. A parallel fetch races that future and loses to its return value.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Fetch the next page once the user is within a screen's-worth of the
  // bottom, rather than waiting for them to hit the exact end — that would
  // leave them staring at a loading footer they had to scroll to see.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    // The add button tucks its label away while scrolling down through the
    // list and brings it back on the way up (or back at the top), so it
    // never sits over the rows any wider than it has to.
    final extend = position.pixels <= 0 ||
        position.userScrollDirection == ScrollDirection.forward;
    final collapse = position.userScrollDirection == ScrollDirection.reverse;
    if (extend && !_fabExtended) {
      setState(() => _fabExtended = true);
    } else if (collapse && _fabExtended && position.pixels > 0) {
      setState(() => _fabExtended = false);
    }

    if (position.pixels < position.maxScrollExtent - 400) return;
    ref.read(companyProvider.notifier).loadMoreCompanies();
  }

  Future<void> _addCompany() async {
    final result = await Navigator.of(context).push<CompanyModel>(
      AppPageRoute(builder: (_) => const CompanyFormPage()),
    );
    if (!mounted) return;
    if (result != null) {
      AppToast.show(
        context,
        AppLocalizations.of(context)!.companySelectCreatedSuccess,
        type: AppToastType.success,
      );
      // Auto refresh list
      if (mounted) {
        ref.read(companyProvider.notifier).fetchCompanies();
      }
    }
  }

  Future<void> _editCompany(CompanyModel company) async {
    final result = await Navigator.of(context).push<CompanyModel>(
      AppPageRoute(builder: (_) => CompanyFormPage(company: company)),
    );
    if (!mounted) return;
    if (result != null) {
      AppToast.show(
        context,
        AppLocalizations.of(context)!.companySelectUpdatedSuccess,
        type: AppToastType.success,
      );
      // Auto refresh list
      if (mounted) {
        ref.read(companyProvider.notifier).fetchCompanies();
      }
    }
  }

  Future<void> _deleteCompany(CompanyModel company) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        // A dialog in landscape is short; let the body scroll rather than
        // overflow when the company name runs long.
        scrollable: true,
        backgroundColor: isDark ? Wallet.darkSurface : Colors.white,
        surfaceTintColor: isDark ? Wallet.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.companySelectDeleteTitle,
          style: TextStyle(
            color: isDark ? Wallet.darkInk : Wallet.ink,
          ),
        ),
        content: Text(
          l10n.companySelectDeleteConfirm(company.name),
          style: TextStyle(
            color: isDark ? Wallet.darkMuted : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.companySelectCancel,
              style: TextStyle(
                color: isDark ? Wallet.darkMuted : Colors.grey,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.companySelectDelete),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;
    final result =
        await ref.read(companyProvider.notifier).deleteCompany(company.id);

    if (!mounted) return;

    if (result.isSuccess) {
      AppToast.show(
        context,
        l10n.companySelectDeletedSuccess,
        type: AppToastType.destructiveSoft,
      );
    } else {
      final errorMsg = result.message ??
          ref.read(companyProvider).valueOrNull?.errorMessage ??
          l10n.companySelectDeleteFailed;
      AppToast.show(
        context,
        errorMsg,
        type: AppToastType.error,
      );
    }

    // Auto refresh after delete
    if (mounted) {
      ref.read(companyProvider.notifier).fetchCompanies();
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyProvider);
    final companyState = companyAsync.valueOrNull ?? CompanyState();
    // Skeleton only while there is nothing to show yet. Reading isLoading off
    // the fallback CompanyState() alone was always false on the first load,
    // so the empty state flashed before the list arrived.
    // Only while a request is actually in flight: a failed load falls through
    // to the empty state rather than leaving the skeleton up for good.
    final showSkeleton =
        (companyAsync.isLoading && !companyAsync.hasValue) ||
            companyState.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Wallet.darkGround : AppColors.surface,
      appBar: AppBar(
        backgroundColor: isDark ? Wallet.darkGround : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.companySelectTitle,
          style: TextStyle(
            color: isDark ? Colors.white : Wallet.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primary, size: 28),
            onPressed: _addCompany,
          ),
        ],
      ),
      floatingActionButton: _GlassAddButton(
        label: l10n.companySelectAddNew,
        extended: _fabExtended,
        onTap: _addCompany,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 680 : double.infinity,
          ),
          // Cross-fade, not a cut: swapped in one frame, the skeleton and the
          // list read as two different pages. Both are top-aligned with the
          // same padding, so the real rows fade in where the bones were.
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, if (current != null) current],
            ),
            child: showSkeleton
              ? const _CompanyListSkeleton(key: ValueKey('skeleton'))
              : RefreshIndicator(
                  key: const ValueKey('list'),
                  onRefresh: () =>
                      ref.read(companyProvider.notifier).fetchCompanies(),
                  child: companyState.companies.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: _buildEmptyState(),
                        )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: companyState.companies.length +
                            (companyState.hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= companyState.companies.length) {
                            return _buildLoadMoreFooter();
                          }
                          final c = companyState.companies[i];
                          return _buildCompanyCard(c);
                        },
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center_outlined,
              size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            l10n.companySelectEmptyTitle,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Wallet.darkInk : Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.companySelectEmptySubtitle,
            style: TextStyle(
              color: isDark ? Wallet.darkMuted : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    final companyState = ref.watch(companyProvider).valueOrNull ?? CompanyState();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: companyState.isLoadingMore
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            // Reserve the same footer space when idle so reaching this row
            // doesn't jump the scroll offset once loading finishes.
            : const SizedBox(height: 28),
      ),
    );
  }

  Widget _buildCompanyCard(CompanyModel company) {
    final authState = ref.watch(authProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isCreator = company.createdBy != null &&
        authState?.currentUser != null &&
        company.createdBy == authState!.currentUser!.id;

    final cardWidget = Container(
          decoration: BoxDecoration(
            color: isDark ? Wallet.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Wallet.darkLine
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // If selection mode, return the company
                if (widget.isSelectionMode) {
                  Navigator.of(context).pop<CompanyModel>(company);
                } else {
                  // If management mode, navigate to detail page (Read-Only)
                  // Creator can edit via the 3-dot menu
                  Navigator.of(context).push(
                    AppPageRoute(
                      builder: (_) => CompanyDetailPage(company: company),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Wallet.darkLine
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business,
                        color: isDark
                            ? Wallet.accentDark
                            : AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Wallet.darkInk
                                  : Wallet.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company.industry ?? l10n.companySelectGeneralIndustry,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Wallet.darkMuted
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCreator)
                      PopupMenuButton<String>(
                        color: isDark ? Wallet.darkSurface : Colors.white,
                        surfaceTintColor:
                            isDark ? Wallet.darkSurface : Colors.white,
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark
                              ? Wallet.darkMuted
                              : Colors.grey,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editCompany(company);
                          } else if (value == 'delete') {
                            _deleteCompany(company);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.companySelectEdit,
                                  style: TextStyle(
                                    color: isDark
                                        ? Wallet.darkInk
                                        : Wallet.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.companySelectDelete,
                                  style: TextStyle(
                                    color: isDark
                                        ? Wallet.darkInk
                                        : Wallet.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: cardWidget,
    );
  }
}

/// Placeholder rows shaped like [_CompanySelectPageState._buildCompanyCard]
/// (icon tile, name, industry), pulsing gently while the list loads — so
/// the page shows its layout straight away instead of a lone spinner, and
/// nothing jumps when the real rows replace it.
class _CompanyListSkeleton extends StatefulWidget {
  const _CompanyListSkeleton({super.key});

  @override
  State<_CompanyListSkeleton> createState() => _CompanyListSkeletonState();
}

class _CompanyListSkeletonState extends State<_CompanyListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bone = isDark ? Wallet.darkLine : const Color(0xFFE9EDF3);

    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bone,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return FadeTransition(
      opacity: Tween<double>(begin: .45, end: 1).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: ListView.builder(
        // Same padding and spacing as the real list.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 7,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Wallet.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Wallet.darkLine : Colors.black.withOpacity(0.05),
            ),
            // Same shadow as the real card, so the frame doesn't change as
            // the content fades in — only what's inside it does.
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bone,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vary the name width a little so the rows don't read
                    // as one repeated stamp.
                    bar(i.isEven ? 150 : 110, 14),
                    const SizedBox(height: 10),
                    bar(80, 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Add new company" as a frosted-glass pill: the list blurs through a
/// translucent accent fill with a lit hairline edge, so it floats over the
/// rows while staying the page's one obvious action.
///
/// The label animates away (fade + width collapse) when [extended] turns
/// false, leaving a round "+" — and back again when it turns true.
class _GlassAddButton extends StatelessWidget {
  final String label;
  final bool extended;
  final VoidCallback onTap;

  const _GlassAddButton({
    required this.label,
    required this.extended,
    required this.onTap,
  });

  static const _height = 56.0;
  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Wallet.accentOf(isDark);
    final onAccent = Wallet.onAccentOf(isDark);
    final shape = BorderRadius.circular(_height / 2);

    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? .35 : .28),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: shape,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: accent.withOpacity(.78),
              child: InkWell(
                onTap: onTap,
                child: Container(
                  height: _height,
                  constraints: const BoxConstraints(minWidth: _height),
                  decoration: BoxDecoration(
                    borderRadius: shape,
                    // The lit rim that makes it read as glass rather than
                    // as a faded button.
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? .18 : .45),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: onAccent, size: 24),
                      // Width and opacity animate together, so the text
                      // fades as the pill narrows instead of being clipped.
                      AnimatedSize(
                        duration: _duration,
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          duration: _duration,
                          curve: Curves.easeOut,
                          opacity: extended ? 1 : 0,
                          child: extended
                              ? Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, right: 4),
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: onAccent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
