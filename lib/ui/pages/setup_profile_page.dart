import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../data/vos/user_model.dart';
import '../../network/image_url.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../providers/company/company_provider.dart';
import '../../services/ocr/card_ocr_service.dart';
import '../../utils/business_card_parser.dart';
import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/image_source_sheet.dart';
import '../widgets/onboarding_chrome.dart';
import '../widgets/onboarding_step_scaffold.dart';
import 'company_select_page.dart';

/// Step two of sign-up: the profile behind the account, and photos of the
/// physical card that goes with it.
///
/// Registration already created a bare `user_card` server-side — a name, an
/// email, and the placeholder position "Member". That card is what other people
/// find when they search or scan, so it is worth finishing while the user still
/// has their own card in hand. Everything here is optional and skippable: the
/// account exists either way, and a half-filled card beats a blocked signup.
class SetupProfilePage extends ConsumerStatefulWidget {
  final String email;

  const SetupProfilePage({super.key, required this.email});

  @override
  ConsumerState<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends ConsumerState<SetupProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _positionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  /// The card registration created for this user, once the list has loaded.
  /// Null means it has not been found yet — saving falls back to creating one.
  BusinessCardModel? _profileCard;

  int? _companyId;
  String? _companyName;

  XFile? _profileImage;
  Uint8List? _profileImageBytes;

  XFile? _frontImage;
  Uint8List? _frontImageBytes;
  XFile? _backImage;
  Uint8List? _backImageBytes;

  bool _isScanning = false;
  bool _isSaving = false;

  /// Common roles, offered as taps instead of typing. The list is deliberately
  /// short — a long one is just a second keyboard.
  static const _positionSuggestions = [
    'Founder',
    'Manager',
    'Engineer',
    'Designer',
    'Sales',
    'Consultant',
  ];

  @override
  void initState() {
    super.initState();
    // The suggestion chips mirror the field, so typing has to redraw them —
    // otherwise a chip stays lit after its text has been edited away.
    _positionCtrl.addListener(_onPositionChanged);
    Future.microtask(_loadProfileCard);
  }

  void _onPositionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _positionCtrl.removeListener(_onPositionChanged);
    _positionCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Finds the card sign-up created so the form edits it rather than adding a
  /// second one. The list is refetched because registration invalidated it.
  Future<void> _loadProfileCard() async {
    final user = ref.read(authProvider).valueOrNull?.currentUser;
    if (user == null) return;

    final state = await ref.read(cardProvider.notifier).fetchCards();
    if (!mounted) return;

    final card = findOwnUserCard(state.cards, user);
    if (card == null) return;

    setState(() {
      _profileCard = card;
      // "Member" is the server's placeholder, not something the user chose, so
      // it is left out rather than presented as an answer already given.
      if (card.position.isNotEmpty && card.position != 'Member') {
        _positionCtrl.text = card.position;
      }
      if (card.phones.isNotEmpty) _phoneCtrl.text = card.phones.first;
      if (card.company != null) {
        _companyId = card.company!.id;
        _companyName = card.company!.name;
      }
    });
  }

  void _showToast(String message, {bool isError = false}) {
    AppToast.show(
      context,
      message,
      type: isError ? AppToastType.error : AppToastType.success,
    );
  }

  Future<XFile?> _pick(String title, {String? subtitle}) async {
    final source =
        await showImageSourceSheet(context, title: title, subtitle: subtitle);
    if (source == null || !mounted) return null;
    try {
      return await ImagePicker().pickImage(source: source);
    } catch (_) {
      if (!mounted) return null;
      _showToast(
        'Could not open the '
        '${source == ImageSource.camera ? 'camera' : 'gallery'}.',
        isError: true,
      );
      return null;
    }
  }

  Future<void> _pickProfileImage() async {
    final picked = await _pick(
      'Profile photo',
      subtitle: 'This is the face people see when they find your card.',
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _profileImage = picked;
      _profileImageBytes = bytes;
    });
  }

  Future<void> _pickCardImage({required bool isFront}) async {
    final picked = await _pick(
      isFront ? 'Front of your card' : 'Back of your card',
      subtitle: isFront
          ? 'We read it and fill in the details below.'
          : 'Often where the address and extra numbers live.',
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (isFront) {
        _frontImage = picked;
        _frontImageBytes = bytes;
      } else {
        _backImage = picked;
        _backImageBytes = bytes;
      }
    });

    await _runOcr(silentWhenEmpty: true);
  }

  /// Reads whichever card photos are attached and fills fields still blank.
  /// Anything the user typed is left alone — recognition is a guess.
  Future<void> _runOcr({bool silentWhenEmpty = false}) async {
    final front = _frontImage;
    if (front == null) return;

    setState(() => _isScanning = true);
    try {
      final parsed =
          await const CardOcrService().scan(front: front, back: _backImage);
      if (!mounted) return;

      if (parsed.isEmpty) {
        if (!silentWhenEmpty) {
          _showToast(
            "Couldn't read that photo. Try better lighting, or type the "
            'details in yourself.',
            isError: true,
          );
        }
        return;
      }

      setState(() => _applyScanned(parsed));
      unawaited(_resolveScannedCompany(parsed.company));
      if (!silentWhenEmpty) {
        _showToast('Filled in what we could read. Check it before saving.');
      }
    } catch (_) {
      if (!mounted) return;
      if (!silentWhenEmpty) {
        _showToast('Could not scan that photo. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _applyScanned(ParsedCardData data) {
    if (_positionCtrl.text.trim().isEmpty && data.position != null) {
      _positionCtrl.text = data.position!.trim();
    }
    if (_phoneCtrl.text.trim().isEmpty && data.phones.isNotEmpty) {
      _phoneCtrl.text = data.phones.first;
    }
  }

  /// Links the company OCR read off the card, creating it when it is not on
  /// file yet. Failures stay quiet — the picker is right there either way.
  Future<void> _resolveScannedCompany(String? name) async {
    if (name == null || name.trim().isEmpty || _companyId != null) return;

    final resolved =
        await ref.read(companyProvider.notifier).resolveByName(name.trim());
    if (!mounted || resolved == null) return;

    setState(() {
      _companyId = resolved.company.id;
      _companyName = resolved.company.name;
    });
  }

  Future<void> _pickCompany() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CompanySelectPage()),
    );
    if (result is CompanyModel) {
      setState(() {
        _companyId = result.id;
        _companyName = result.name;
      });
    }
  }

  bool get _hasAnythingToSave =>
      _profileImage != null ||
      _frontImage != null ||
      _backImage != null ||
      _positionCtrl.text.trim().isNotEmpty ||
      _phoneCtrl.text.trim().isNotEmpty ||
      _companyId != null;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_hasAnythingToSave) {
      _finish('You can finish your card any time from the menu.');
      return;
    }

    final user = ref.read(authProvider).valueOrNull?.currentUser;
    final notifier = ref.read(cardProvider.notifier);

    // The card may not have loaded yet if the user was fast; look once more
    // before falling back to creating a second one.
    var card = _profileCard;
    if (card == null && user != null) {
      final state = await notifier.fetchCards();
      card = findOwnUserCard(state.cards, user);
    }

    final position = _positionCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() => _isSaving = true);
    final result = card != null && card.id != 0
        ? await notifier.updateCard(
            card.id,
            position: position.isEmpty ? null : position,
            phones: phone.isEmpty ? null : [phone],
            companyId: _companyId,
            imageFile: _profileImage,
            frontImageFile: _frontImage,
            backImageFile: _backImage,
            // Omitting this blanks card_type server-side, which would drop the
            // card out of both list tabs.
            cardType: 'user_card',
          )
        : await notifier.createCard(
            name: user?.name,
            emails: [widget.email],
            position: position.isEmpty ? null : position,
            phones: phone.isEmpty ? null : [phone],
            companyId: _companyId,
            imageFile: _profileImage,
            frontImageFile: _frontImage,
            backImageFile: _backImage,
            cardType: 'user_card',
          );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.isSuccess) {
      _finish('Your card is ready. Share it any time from the QR button.');
    } else {
      _showToast(
        result.message ?? 'Could not save your card. Please try again.',
        isError: true,
      );
    }
  }

  void _skip() {
    _finish('You can finish your card any time from the menu.');
  }

  /// Leaves sign-up for the app. The toast rides the root overlay, so it
  /// survives the pop and lands on the card list.
  void _finish(String message) {
    AppToast.show(context, message, type: AppToastType.info);
    ref.read(cardProvider.notifier).fetchCards();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull?.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OnboardingStepScaffold(
      step: 2,
      totalSteps: 2,
      label: 'Your card',
      completed: 'Account created',
      headline: 'Complete your card',
      subhead: 'This is what people see when they scan you. '
          'Everything here is optional.',
      exitIcon: Icons.close_rounded,
      onExit: _isSaving ? null : _skip,
      busy: _isSaving,
      action: AppPrimaryButton(
        text: 'Save My Card',
        loading: _isSaving,
        onPressed: _isSaving ? null : _save,
      ),
      secondaryAction: TextButton(
        onPressed: _isSaving ? null : _skip,
        child: Text(
          'Skip for now',
          style: AppTypography.secondary(TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Wallet.mutedOf(isDark),
          )),
        ),
      ),
      children: [
        // Photos first, deliberately. The scan fills the fields underneath,
        // so asking for the photo before the typing turns the whole section
        // below into something the user reviews rather than composes.
        _buildCardPhotosSection(isDark),
        _buildProfileSection(user, isDark),
      ],
    );
  }

  Widget _buildCardPhotosSection(bool isDark) {
    final hasFront = _frontImageBytes != null;

    return OnboardingSection(
      title: 'Your printed card',
      caption: hasFront
          ? null
          : 'Photograph the front and we read it into the form below.',
      trailing: hasFront
          ? TextButton.icon(
              onPressed: _isScanning ? null : () => _runOcr(),
              style: TextButton.styleFrom(
                foregroundColor: Wallet.accentOf(isDark),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: _isScanning
                  ? SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Wallet.accentOf(isDark)),
                      ),
                    )
                  : const Icon(Icons.auto_fix_high_rounded, size: 15),
              label: Text(
                _isScanning ? 'READING' : 'RESCAN',
                style: AppTypography.eyebrow(
                  color: Wallet.accentOf(isDark),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCardPhotoTile(
                label: 'Front',
                bytes: _frontImageBytes,
                remoteUrl: ImageUrl.resolve(_profileCard?.frontImage),
                isFront: true,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardPhotoTile(
                label: 'Back',
                bytes: _backImageBytes,
                remoteUrl: ImageUrl.resolve(_profileCard?.backImage),
                isFront: false,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileSection(UserModel? user, bool isDark) {
    final name = user?.name ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final existingAvatar = ImageUrl.resolve(_profileCard?.profileImage);

    return OnboardingSection(
      title: 'Profile',
      children: [
        Row(
          children: [
            _buildAvatarPicker(initial, existingAvatar, isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Your card' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.primary(TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Wallet.inkOf(isDark),
                    )),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    (_profileImageBytes != null ? 'PHOTO ADDED' : 'ADD A PHOTO'),
                    style: AppTypography.eyebrow(
                      color: _profileImageBytes != null
                          ? Wallet.success
                          : Wallet.faintOf(isDark),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        OnboardingTextField(
          controller: _positionCtrl,
          enabled: !_isSaving,
          hintText: 'Position — e.g. Product Designer',
          prefixIcon: Icons.work_outline_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in _positionSuggestions)
              OnboardingChoiceChip(
                label: suggestion,
                selected: _positionCtrl.text.trim().toLowerCase() ==
                    suggestion.toLowerCase(),
                onTap: _isSaving
                    ? null
                    : () => setState(() {
                          final selected =
                              _positionCtrl.text.trim().toLowerCase() ==
                                  suggestion.toLowerCase();
                          _positionCtrl.text = selected ? '' : suggestion;
                        }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        OnboardingTextField(
          controller: _phoneCtrl,
          enabled: !_isSaving,
          hintText: 'Phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          validator: (v) {
            final value = (v ?? '').trim();
            if (value.isEmpty) return null;
            if (value.length < 6) return 'Phone must be at least 6 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),
        OnboardingPickerRow(
          icon: Icons.business_outlined,
          value: _companyName,
          placeholder: 'Company (optional)',
          actionLabel: _companyName != null ? 'Change' : 'Choose',
          onTap: _isSaving ? null : _pickCompany,
        ),
      ],
    );
  }

  /// A square plate, matching the avatars in the card list. The old gradient
  /// ring was the only gradient left in the app once the buttons went flat.
  Widget _buildAvatarPicker(
    String initial,
    String? existingAvatar,
    bool isDark,
  ) {
    final bytes = _profileImageBytes;
    final shape = BorderRadius.circular(Wallet.radiusTile);

    return GestureDetector(
      onTap: _isSaving ? null : _pickProfileImage,
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: shape,
                color: Wallet.tintOf(isDark),
                border: Border.all(
                  color: Wallet.lineOf(isDark),
                  width: Wallet.hairline,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : (existingAvatar != null
                      ? Image.network(
                          existingAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildAvatarFallback(initial, isDark),
                        )
                      : _buildAvatarFallback(initial, isDark)),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Wallet.accentOf(isDark),
                  borderRadius: BorderRadius.circular(Wallet.radiusTile),
                  border: Border.all(
                    color: Wallet.surfaceOf(isDark),
                    width: 2,
                  ),
                ),
                child: Icon(
                  bytes != null
                      ? Icons.edit_rounded
                      : Icons.add_a_photo_rounded,
                  size: 12,
                  color: Wallet.onAccentOf(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String initial, bool isDark) {
    return Container(
      color: Wallet.tintOf(isDark),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTypography.primary(TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Wallet.accentOf(isDark),
        )),
      ),
    );
  }

  Widget _buildCardPhotoTile({
    required String label,
    required Uint8List? bytes,
    required String? remoteUrl,
    required bool isFront,
    required bool isDark,
  }) {
    final hasImage = bytes != null || remoteUrl != null;
    final accent = Wallet.accentOf(isDark);

    return GestureDetector(
      onTap: _isSaving ? null : () => _pickCardImage(isFront: isFront),
      child: AspectRatio(
        // Roughly the proportions of a printed card, so the slot reads as the
        // card itself rather than a generic image box.
        aspectRatio: 1.7,
        child: Container(
          decoration: BoxDecoration(
            color: hasImage ? null : Wallet.tintOf(isDark),
            borderRadius: BorderRadius.circular(Wallet.radiusCard),
            border: Border.all(
              // An empty front slot is the one thing on this screen worth
              // pointing at, because filling it fills the rest of the form.
              color: hasImage
                  ? Wallet.lineOf(isDark)
                  : accent.withOpacity(isFront ? .55 : .28),
              width: hasImage ? Wallet.hairline : 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null)
                Image.memory(bytes, fit: BoxFit.cover)
              else if (remoteUrl != null)
                Image.network(
                  remoteUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildCardPhotoPlaceholder(label, isFront, isDark),
                )
              else
                _buildCardPhotoPlaceholder(label, isFront, isDark),
              if (hasImage) ...[
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.62),
                      borderRadius:
                          BorderRadius.circular(Wallet.radiusTile),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: AppTypography.eyebrow(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.62),
                      borderRadius:
                          BorderRadius.circular(Wallet.radiusTile),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPhotoPlaceholder(String label, bool isFront, bool isDark) {
    final accent = Wallet.accentOf(isDark);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 20, color: accent),
        const SizedBox(height: 7),
        Text(
          label.toUpperCase(),
          style: AppTypography.eyebrow(
            color: Wallet.inkOf(isDark),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (isFront) ...[
          const SizedBox(height: 3),
          Text(
            'Fills the form',
            style: AppTypography.secondary(TextStyle(
              fontSize: 10.5,
              color: Wallet.mutedOf(isDark),
            )),
          ),
        ],
      ],
    );
  }

}

/// The signed-in user's own `user_card` out of [cards], or null when the list
/// does not hold one yet.
///
/// Ownership is the reliable signal; the email match is a fallback for cards
/// created before `user_id` was always set.
BusinessCardModel? findOwnUserCard(
  List<BusinessCardModel> cards,
  UserModel user,
) {
  final email = (user.email ?? '').trim().toLowerCase();
  for (final card in cards) {
    if (card.cardType != 'user_card') continue;
    if (card.user?.id == user.id || card.createdBy == user.id) return card;
    if (email.isNotEmpty &&
        card.emails.any((e) => e.trim().toLowerCase() == email)) {
      return card;
    }
  }
  return null;
}
