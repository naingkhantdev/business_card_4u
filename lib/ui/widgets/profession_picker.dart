import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/card/profession_provider.dart';
import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';
import 'onboarding_chrome.dart';
import 'onboarding_step_scaffold.dart';

/// Translated label for a profession. The defaults have translations;
/// anything people typed themselves is shown exactly as they typed it.
String professionLabel(AppLocalizations l10n, String name) => switch (name) {
      'Engineer' => l10n.professionEngineer,
      'Doctor' => l10n.professionDoctor,
      'Sailor' => l10n.professionSailor,
      'Nurse' => l10n.professionNurse,
      'Teacher' => l10n.professionTeacher,
      'Lawyer' => l10n.professionLawyer,
      'Accountant' => l10n.professionAccountant,
      'Designer' => l10n.professionDesigner,
      'Manager' => l10n.professionManager,
      'Sales' => l10n.professionSales,
      _ => name,
    };

IconData professionIcon(String name) => switch (name) {
      'Engineer' => Icons.engineering_rounded,
      'Doctor' => Icons.medical_services_rounded,
      'Sailor' => Icons.sailing_rounded,
      'Nurse' => Icons.healing_rounded,
      'Teacher' => Icons.school_rounded,
      'Lawyer' => Icons.gavel_rounded,
      'Accountant' => Icons.calculate_rounded,
      'Designer' => Icons.palette_rounded,
      'Manager' => Icons.work_rounded,
      'Sales' => Icons.storefront_rounded,
      _ => Icons.badge_outlined,
    };

/// Position words that name a profession without containing its name.
const _aliases = {
  'developer': 'Engineer',
  'programmer': 'Engineer',
  'physician': 'Doctor',
  'surgeon': 'Doctor',
  'captain': 'Sailor',
  'seaman': 'Sailor',
  'mariner': 'Sailor',
  'director': 'Manager',
  'marketing': 'Sales',
};

/// The profession [position] most likely means, out of [options] — so the
/// picker can start with an answer instead of a blank. Works for professions
/// people added later too, since it matches on the option's own name.
String? suggestProfession(String position, List<String> options) {
  final p = position.trim().toLowerCase();
  if (p.isEmpty) return null;
  for (final option in options) {
    if (p.contains(option.toLowerCase())) return option;
  }
  for (final entry in _aliases.entries) {
    if (p.contains(entry.key) && options.contains(entry.value)) {
      return entry.value;
    }
  }
  return null;
}

/// Pick-one profession chips, most used first, with "Other" for typing a new
/// one. Anything typed here is saved on the server and offered to everyone
/// after, which is how the list grows as people sign up.
///
/// Until the user taps a chip themselves, the choice follows [position]: type
/// "Software Engineer" and Engineer lights up, marked as a suggestion.
class ProfessionPicker extends ConsumerStatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String position;
  final bool enabled;

  const ProfessionPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.position,
    this.enabled = true,
  });

  @override
  ConsumerState<ProfessionPicker> createState() => _ProfessionPickerState();
}

class _ProfessionPickerState extends ConsumerState<ProfessionPicker> {
  static const _visibleCount = 9;

  final _otherCtrl = TextEditingController();
  bool _showOther = false;

  /// Set once the user taps or types a choice; from then on the position no
  /// longer overrides it.
  bool _userChose = false;

  /// The value this widget filled in from the position, if any.
  String? _suggested;

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  void _choose(String? value) {
    setState(() {
      _userChose = true;
      _showOther = false;
    });
    widget.onChanged(value);
  }

  void _submitOther() {
    final text = _otherCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return;
    _otherCtrl.clear();
    _choose(text);
  }

  /// Follows the position until the user makes a choice of their own. Runs
  /// after the frame, since it changes the parent's state.
  void _syncSuggestion(String? suggestion) {
    if (_userChose || suggestion == null) return;
    final value = widget.value;
    final followsPosition = value == null || value == _suggested;
    if (!followsPosition || suggestion == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _userChose) return;
      setState(() => _suggested = suggestion);
      widget.onChanged(suggestion);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options =
        ref.watch(professionsProvider).valueOrNull ?? kDefaultProfessions;
    final value = widget.value;

    final suggestion = suggestProfession(widget.position, options);
    _syncSuggestion(suggestion);

    // The current choice always shows, even when it's a typed one outside
    // the top of the list.
    final visible = options.take(_visibleCount).toList();
    if (value != null &&
        !visible.any((o) => o.toLowerCase() == value.toLowerCase())) {
      visible.insert(0, value);
    }

    final isSuggestion =
        !_userChose && value != null && value == _suggested;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.badge_outlined,
                size: 16, color: Wallet.mutedOf(isDark)),
            const SizedBox(width: 6),
            Text(
              l10n.professionPickerTitle,
              style: AppTypography.eyebrow(
                color: Wallet.mutedOf(isDark),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in visible)
              OnboardingChoiceChip(
                label: professionLabel(l10n, option),
                selected: value?.toLowerCase() == option.toLowerCase(),
                onTap: !widget.enabled
                    ? null
                    : () => _choose(
                        value?.toLowerCase() == option.toLowerCase()
                            ? null
                            : option),
              ),
            OnboardingChoiceChip(
              label: '+ ${l10n.professionPickerOther}',
              selected: _showOther,
              onTap: !widget.enabled
                  ? null
                  : () => setState(() => _showOther = !_showOther),
            ),
          ],
        ),
        if (isSuggestion) ...[
          const SizedBox(height: 8),
          Text(
            l10n.professionPickerSuggested,
            style: AppTypography.secondary(TextStyle(
              fontSize: 11.5,
              color: Wallet.accentOf(isDark),
            )),
          ),
        ],
        if (_showOther) ...[
          const SizedBox(height: 12),
          OnboardingTextField(
            controller: _otherCtrl,
            enabled: widget.enabled,
            hintText: l10n.professionPickerOtherHint,
            prefixIcon: Icons.edit_outlined,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitOther(),
            suffix: IconButton(
              tooltip: l10n.professionPickerAdd,
              icon: Icon(Icons.check_rounded, color: Wallet.accentOf(isDark)),
              onPressed: _submitOther,
            ),
          ),
        ],
      ],
    );
  }
}
