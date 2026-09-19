import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_typography.dart';
import '../theme/glass.dart';
import '../theme/wallet_tokens.dart';
import 'loading_view.dart';

/// The frame both sign-up steps are built in.
///
/// Three things are deliberately inverted from the layout this replaces:
///
/// **Glass moved to the chrome.** The old steps wrapped the whole form in one
/// frosted card, which made every pixel on the screen translucent and left
/// nothing for the blur to mean. Here the header and footer float and the
/// content underneath is opaque, so glass reads as "above the page" — which is
/// the only thing it should ever say.
///
/// **The action is pinned.** The primary button used to be the last thing in a
/// long scroll, so on step two you had to scroll past a photo picker to reach
/// it. It now lives in the footer and is reachable at every scroll position.
///
/// **Progress is segmented.** A continuous bar hides how many steps there are.
/// Discrete segments answer "how much is left" at a glance — and the first one
/// is already filled, because verifying the email was real work and a bar that
/// starts at zero throws that away.
class OnboardingStepScaffold extends StatelessWidget {
  final int step;
  final int totalSteps;

  /// Names the step, set as an eyebrow beside the counter.
  final String label;

  /// What the user has already banked. Shown with a check in the header.
  final String? completed;

  final String headline;
  final String? subhead;

  /// Leading control. Back on step one, close on step two.
  final IconData exitIcon;
  final VoidCallback? onExit;

  final List<Widget> children;

  /// The pinned primary action, and an optional escape beside it.
  final Widget action;
  final Widget? secondaryAction;

  /// Covers the page while a request is in flight.
  final bool busy;

  const OnboardingStepScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.label,
    required this.headline,
    required this.children,
    required this.action,
    this.completed,
    this.subhead,
    this.exitIcon = Icons.arrow_back_rounded,
    this.onExit,
    this.secondaryAction,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Wallet.groundOf(isDark),
      // The footer has to ride the keyboard, or the pinned action ends up
      // underneath it the moment a field takes focus.
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: GlassBackdrop()),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              // Header, scroller and footer are a fixed-plus-flexible stack, so
              // once the header and footer alone are taller than the viewport
              // the column overflows. That happens for real in landscape with
              // the keyboard up, and the header is the part the user can spare
              // while typing.
              final tight = constraints.maxHeight < 300;

              return Column(
                children: [
                  if (!tight)
                    _Header(
                      step: step,
                      totalSteps: totalSteps,
                      label: label,
                      completed: completed,
                      exitIcon: exitIcon,
                      onExit: onExit,
                      isDark: isDark,
                    ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      behavior: HitTestBehavior.opaque,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          Wallet.margin,
                          20,
                          Wallet.margin,
                          28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: Responsive.isDesktop(context)
                                  ? 640
                                  : double.infinity,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  headline,
                                  style: AppTypography.primary(TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    height: 1.05,
                                    color: Wallet.inkOf(isDark),
                                  )),
                                ),
                                if (subhead != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    subhead!,
                                    style: AppTypography.secondary(TextStyle(
                                      fontSize: 14.5,
                                      height: 1.5,
                                      color: Wallet.mutedOf(isDark),
                                    )),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                ...children,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _Footer(
                    action: action,
                    secondaryAction: secondaryAction,
                  ),
                ],
              );
            }),
          ),
          if (busy)
            const Positioned.fill(
              child: GlassScrim(child: LoadingView(size: 110)),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String label;
  final String? completed;
  final IconData exitIcon;
  final VoidCallback? onExit;
  final bool isDark;

  const _Header({
    required this.step,
    required this.totalSteps,
    required this.label,
    required this.completed,
    required this.exitIcon,
    required this.onExit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // One segment more than there are steps: the email verification that got
    // the user here counts, so the rail never starts empty.
    final segments = totalSteps + 1;
    final filled = (step + 1).clamp(0, segments);

    return GlassPanel(
      radius: 0,
      elevated: false,
      padding: const EdgeInsets.fromLTRB(12, 10, Wallet.margin, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ExitButton(icon: exitIcon, onTap: onExit, isDark: isDark),
              const SizedBox(width: 4),
              Text(
                'STEP $step / $totalSteps',
                style: AppTypography.eyebrow(
                  color: Wallet.accentOf(isDark),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.eyebrow(
                    color: Wallet.faintOf(isDark),
                    fontSize: 10.5,
                  ),
                ),
              ),
              if (completed != null) ...[
                Icon(Icons.check_rounded, size: 13, color: Wallet.success),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    completed!.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.eyebrow(
                      color: Wallet.mutedOf(isDark),
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < segments; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < filled
                          ? Wallet.accentOf(isDark)
                          : Wallet.lineOf(isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _ExitButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: Wallet.inkOf(isDark)),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final Widget action;
  final Widget? secondaryAction;

  const _Footer({required this.action, this.secondaryAction});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 0,
      elevated: false,
      padding: const EdgeInsets.fromLTRB(
        Wallet.margin,
        14,
        Wallet.margin,
        14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          action,
          if (secondaryAction != null) ...[
            const SizedBox(height: 4),
            secondaryAction!,
          ],
        ],
      ),
    );
  }
}

/// A block of content on an opaque surface, named by an eyebrow above it.
///
/// Opaque on purpose: the header and footer are the only frosted things on
/// these screens, so a panel here would compete with them for the same signal.
class OnboardingSection extends StatelessWidget {
  final String title;
  final String? caption;

  /// Sits opposite the title — a rescan button, a counter, a status.
  final Widget? trailing;

  final List<Widget> children;

  const OnboardingSection({
    super.key,
    required this.title,
    required this.children,
    this.caption,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Wallet.surfaceOf(isDark),
        borderRadius: BorderRadius.circular(Wallet.radiusCard),
        border: Wallet.borderOf(isDark),
        boxShadow: Wallet.shadowOf(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: AppTypography.eyebrow(
                        color: Wallet.accentOf(isDark),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        caption!,
                        style: AppTypography.secondary(TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Wallet.mutedOf(isDark),
                        )),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// A ruled, tappable row — the company picker, and anything else that opens
/// somewhere else rather than editing in place.
class OnboardingPickerRow extends StatelessWidget {
  final IconData icon;
  final String? value;
  final String placeholder;
  final String actionLabel;
  final VoidCallback? onTap;

  const OnboardingPickerRow({
    super.key,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != null && value!.trim().isNotEmpty;
    final shape = BorderRadius.circular(Wallet.radiusControl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(
              color: Wallet.lineOf(isDark),
              width: Wallet.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Wallet.radiusTile),
                  color: Wallet.tintOf(isDark),
                ),
                child: Icon(icon, size: 15, color: Wallet.accentOf(isDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? value! : placeholder,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.secondary(TextStyle(
                    fontSize: 14.5,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    color: hasValue
                        ? Wallet.inkOf(isDark)
                        : Wallet.faintOf(isDark),
                  )),
                ),
              ),
              Text(
                actionLabel.toUpperCase(),
                style: AppTypography.eyebrow(
                  color: Wallet.accentOf(isDark),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Wallet.faintOf(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A squared-off suggestion chip. Selected state is a filled accent block, so
/// which one is active survives a glance.
class OnboardingChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const OnboardingChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Wallet.accentOf(isDark);
    final shape = BorderRadius.circular(Wallet.radiusTile);

    return Material(
      color: selected ? accent : Colors.transparent,
      borderRadius: shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(
              color: selected ? accent : Wallet.lineOf(isDark),
              width: Wallet.hairline,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.eyebrow(
              color: selected ? Wallet.onAccentOf(isDark) : Wallet.mutedOf(isDark),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
