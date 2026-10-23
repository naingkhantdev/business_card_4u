import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../data/vos/user_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../network/image_url.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../providers/card/profession_provider.dart';
import '../../providers/company/company_provider.dart';
import '../../providers/ocr/card_scanner_provider.dart';
import '../../data/vos/scanned_card_data.dart';
import '../../utils/image_upload.dart';
import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/image_source_sheet.dart';
import '../widgets/onboarding_chrome.dart';
import '../widgets/onboarding_step_scaffold.dart';
import '../widgets/profession_picker.dart';
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

  /// Picked in [ProfessionPicker]; what the card list's filter chips use.
  String? _profession;

  @override
  void initState() {
    super.initState();
    // The profession picker suggests from the position as it's typed, so
    // typing has to redraw it.
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
      _profession ??= card.profession;
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

  Future<XFile?> _pick(
    String title, {
    String? subtitle,
    required UploadImageKind kind,
  }) async {
    final source =
        await showImageSourceSheet(context, title: title, subtitle: subtitle);
    if (source == null || !mounted) return null;
    try {
      return await pickImageForUpload(source, kind);
    } catch (_) {
      if (!mounted) return null;
      final l10n = AppLocalizations.of(context)!;
      _showToast(
        l10n.setupProfileImageSourceError(
          source == ImageSource.camera
              ? l10n.setupProfileSourceCamera
              : l10n.setupProfileSourceGallery,
        ),
        isError: true,
      );
      return null;
    }
  }

  Future<void> _pickProfileImage() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await _pick(
      l10n.setupProfileImageSheetTitle,
      subtitle: l10n.setupProfileImageSheetSubtitle,
      kind: UploadImageKind.avatar,
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
    final l10n = AppLocalizations.of(context)!;
    final picked = await _pick(
      isFront ? l10n.setupProfileFrontSheetTitle : l10n.setupProfileBackSheetTitle,
      subtitle: isFront
          ? l10n.setupProfileFrontSheetSubtitle
          : l10n.setupProfileBackSheetSubtitle,
      kind: UploadImageKind.card,
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
      final scanned = await ref.read(cardScannerProvider).scan(front.path);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      if (scanned.isEmpty) {
        if (!silentWhenEmpty) {
          _showToast(
            l10n.setupProfileOcrEmptyError,
            isError: true,
          );
        }
        return;
      }

      setState(() => _applyScanned(scanned));
      unawaited(_resolveScannedCompany(scanned.companyName));
      if (!silentWhenEmpty) {
        _showToast(l10n.setupProfileOcrFilledMessage);
      }
    } catch (_) {
      if (!mounted) return;
      if (!silentWhenEmpty) {
        _showToast(AppLocalizations.of(context)!.setupProfileOcrError,
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _applyScanned(ScannedCardData data) {
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
      AppPageRoute(builder: (_) => const CompanySelectPage()),
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
      _profession != null ||
      _phoneCtrl.text.trim().isNotEmpty ||
      _companyId != null;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;

    if (!_hasAnythingToSave) {
      _finish(l10n.setupProfileFinishLaterMessage);
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
            profession: _profession,
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
            profession: _profession,
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
      // A newly typed profession is now on the server's list.
      ref.invalidate(professionsProvider);
      _finish(l10n.setupProfileSavedMessage);
    } else {
      _showToast(
        result.message ?? l10n.setupProfileSaveError,
        isError: true,
      );
    }
  }

  void _skip() {
    _finish(AppLocalizations.of(context)!.setupProfileFinishLaterMessage);
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
    final l10n = AppLocalizations.of(context)!;

    return OnboardingStepScaffold(
      step: 4,
      totalSteps: kSignUpSteps,
      label: l10n.setupProfileYourCardLabel,
      completed: l10n.setupProfileAccountCreated,
      headline: l10n.setupProfileHeadline,
      subhead: l10n.setupProfileSubhead,
      exitIcon: Icons.close_rounded,
      onExit: _isSaving ? null : _skip,
      busy: _isSaving,
      action: AppPrimaryButton(
        text: l10n.setupProfileSaveButton,
        loading: _isSaving,
        onPressed: _isSaving ? null : _save,
      ),
      secondaryAction: TextButton(
        onPressed: _isSaving ? null : _skip,
        child: Text(
          l10n.setupProfileSkipButton,
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
        _buildCardPhotosSection(l10n, isDark),
        _buildProfileSection(l10n, user, isDark),
      ],
    );
  }

  Widget _buildCardPhotosSection(AppLocalizations l10n, bool isDark) {
    final hasFront = _frontImageBytes != null;

    return OnboardingSection(
      title: l10n.setupProfilePhotosTitle,
      caption: hasFront ? null : l10n.setupProfilePhotosCaption,
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
                _isScanning ? l10n.setupProfileReadingLabel : l10n.setupProfileRescanLabel,
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
                l10n,
                label: l10n.setupProfileFrontLabel,
                bytes: _frontImageBytes,
                remoteUrl: ImageUrl.resolve(_profileCard?.frontImage),
                isFront: true,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardPhotoTile(
                l10n,
                label: l10n.setupProfileBackLabel,
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

  Widget _buildProfileSection(AppLocalizations l10n, UserModel? user, bool isDark) {
    final name = user?.name ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final existingAvatar = ImageUrl.resolve(_profileCard?.profileImage);

    // The Form _save() validates. Without it _formKey.currentState was null,
    // validation read as failed, and Save silently did nothing.
    return Form(
      key: _formKey,
      child: OnboardingSection(
      title: l10n.setupProfileProfileTitle,
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
                    name.isEmpty ? l10n.setupProfileYourCardLabel : name,
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
                    (_profileImageBytes != null
                        ? l10n.setupProfilePhotoAdded
                        : l10n.setupProfileAddPhoto),
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
          hintText: l10n.setupProfilePositionHint,
          prefixIcon: Icons.work_outline_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        ProfessionPicker(
          value: _profession,
          position: _positionCtrl.text,
          enabled: !_isSaving,
          onChanged: (value) => setState(() => _profession = value),
        ),
        const SizedBox(height: 16),
        OnboardingTextField(
          controller: _phoneCtrl,
          enabled: !_isSaving,
          hintText: l10n.setupProfilePhoneHint,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          validator: (v) {
            final value = (v ?? '').trim();
            if (value.isEmpty) return null;
            if (value.length < 6) return l10n.setupProfilePhoneMinLength;
            return null;
          },
        ),
        const SizedBox(height: 16),
        OnboardingPickerRow(
          icon: Icons.business_outlined,
          value: _companyName,
          placeholder: l10n.setupProfileCompanyPlaceholder,
          actionLabel: _companyName != null ? l10n.setupProfileChangeLabel : l10n.setupProfileChooseLabel,
          onTap: _isSaving ? null : _pickCompany,
        ),
      ],
      ),
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

  Widget _buildCardPhotoTile(
    AppLocalizations l10n, {
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
                      _buildCardPhotoPlaceholder(l10n, label, isFront, isDark),
                )
              else
                _buildCardPhotoPlaceholder(l10n, label, isFront, isDark),
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

  Widget _buildCardPhotoPlaceholder(
      AppLocalizations l10n, String label, bool isFront, bool isDark) {
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
            l10n.setupProfileFillsFormHint,
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
