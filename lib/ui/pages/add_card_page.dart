import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../providers/card/profession_provider.dart';
import '../../providers/company/company_provider.dart';
import '../../providers/ocr/card_scanner_provider.dart';
import '../../utils/app_result.dart';
import '../../utils/image_upload.dart';
import '../../network/image_url.dart';
import '../../data/vos/address_model.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../data/vos/scanned_card_data.dart';
import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/image_source_sheet.dart';
import '../widgets/loading_view.dart';
import '../widgets/profession_picker.dart';
import 'company_select_page.dart';
import '../theme/wallet_tokens.dart';

class AddCardPage extends ConsumerStatefulWidget {
  final BusinessCardModel? card; // Pass card for edit mode
  final String? cardType; // 'user_card' for own profile, 'saved_card' for manual

  /// Photos of the physical card carried over from the scan flow, already
  /// captured so the user is not asked for them a second time.
  final XFile? frontImageFile;
  final XFile? backImageFile;

  /// Fields OCR read off those photos. Pre-fills the form; every value stays
  /// editable because recognition is a guess, not a source of truth.
  final ScannedCardData? scanned;

  const AddCardPage({
    super.key,
    this.card,
    this.cardType,
    this.frontImageFile,
    this.backImageFile,
    this.scanned,
  });

  @override
  ConsumerState<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends ConsumerState<AddCardPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _phonesCtrl = TextEditingController();
  final _emailsCtrl = TextEditingController();
  final List<_AddressEntry> _addressEntries = [];
  final _bioCtrl = TextEditingController();
  final _profileImageCtrl = TextEditingController();
  int? _selectedCompanyId;
  String? _selectedCompanyName;

  /// Picked in [ProfessionPicker]; what the card list's filter chips use.
  String? _profession;
  // The portrait shown on the card. Offered on the user's own profile card
  // only: a card saved from someone else's is described by the photos of the
  // card itself, and guessing a face for it is not this form's job.
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  // Photos of the physical card. The XFile is set only when the user picked a
  // new one this session; the URL is what the server already holds.
  XFile? _frontImage;
  Uint8List? _frontImageBytes;
  String? _frontImageUrl;
  XFile? _backImage;
  Uint8List? _backImageBytes;
  String? _backImageUrl;

  /// Company name OCR found. Kept after the company is linked so the form can
  /// say which scanned name produced it.
  String? _scannedCompanyName;

  /// Outcome of resolving [_scannedCompanyName]: true when the scan created the
  /// company, false when it matched one already on file, null while unresolved.
  bool? _companyCreatedByScan;

  bool _isResolvingCompany = false;

  /// Field keys that were filled by OCR rather than typed, so the form can
  /// mark them as needing a glance.
  final Set<String> _scannedFields = {};

  bool _isRescanning = false;

  /// [_formSignature] as it stood before the user (or a scan) touched the
  /// form, so leaving can tell real work from an untouched form.
  late final String _baselineSignature;

  /// Set once the card is saved, so the pop that follows isn't mistaken for
  /// walking away from unsaved work.
  bool _saved = false;

  bool get isEditing => widget.card != null;

  /// True when this form is editing (or creating) the signed-in user's own
  /// profile card — the one other people find by search or QR.
  bool get isOwnProfileCard {
    final card = widget.card;
    if (card == null) return widget.cardType == 'user_card';
    if (card.cardType != 'user_card') return false;

    final currentUser = ref.read(authProvider).valueOrNull?.currentUser;
    if (currentUser == null) return false;
    // id 0 is the placeholder card the app shows before the real one loads.
    return card.id == 0 ||
        card.user?.id == currentUser.id ||
        card.createdBy == currentUser.id;
  }

  void _showToast(String message, {bool isError = false}) {
    AppToast.show(
      context,
      message,
      type: isError ? AppToastType.error : AppToastType.success,
    );
  }

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final c = widget.card!;
      _nameCtrl.text = c.fullName;
      _positionCtrl.text = c.position;
      _profession = c.profession;
      _phonesCtrl.text = c.phones.join(', ');
      _emailsCtrl.text = c.emails.join(', ');
      for (final address in c.addresses) {
        _addressEntries.add(_AddressEntry.fromModel(address));
      }
      _bioCtrl.text = c.bio ?? '';
      _profileImageCtrl.text = c.profileImage ?? '';
      _frontImageUrl = ImageUrl.resolve(c.frontImage);
      _backImageUrl = ImageUrl.resolve(c.backImage);
      if (c.company != null) {
        _selectedCompanyId = c.company!.id;
        _selectedCompanyName = c.company!.name;
      }
    } else {
      if (widget.cardType == 'user_card') {
        final authState = ref.read(authProvider).valueOrNull;
        final currentUser = authState?.currentUser;
        if (currentUser != null) {
          _nameCtrl.text = currentUser.name;
          if (currentUser.email != null) {
            _emailsCtrl.text = currentUser.email!;
          }
        }
      }
    }
    if (_addressEntries.isEmpty) {
      _addressEntries.add(_AddressEntry());
    }
    // Taken before the scan's photos and fields are applied: those are work
    // the user would lose too.
    _baselineSignature = _formSignature();

    _frontImage = widget.frontImageFile;
    _backImage = widget.backImageFile;
    _loadPickedCardImageBytes();

    final scanned = widget.scanned;
    if (scanned != null) {
      _applyScanned(scanned);
    } else if (widget.frontImageFile != null) {
      // Arrived straight from the scan entry point with a photo but no reading
      // yet — do it here so there is one OCR path, shared with the in-form
      // "Fill from photo" action.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runOcr();
      });
    }
  }

  /// Reads the bytes of card photos handed over by the scan flow so they can
  /// be previewed without hitting the file system again on every rebuild.
  Future<void> _loadPickedCardImageBytes() async {
    final front = _frontImage;
    final back = _backImage;
    final frontBytes = front == null ? null : await front.readAsBytes();
    final backBytes = back == null ? null : await back.readAsBytes();
    if (!mounted) return;
    setState(() {
      _frontImageBytes = frontBytes;
      _backImageBytes = backBytes;
    });
  }

  /// Writes OCR results into the form. Only empty fields are filled, so a
  /// rescan can add what was missed without discarding the user's own edits.
  void _applyScanned(ScannedCardData data) {
    void fill(String key, TextEditingController controller, String? value) {
      if (value == null || value.trim().isEmpty) return;
      if (controller.text.trim().isNotEmpty) return;
      controller.text = value.trim();
      _scannedFields.add(key);
    }

    fill('name', _nameCtrl, data.name);
    fill('position', _positionCtrl, data.position);
    fill('phones', _phonesCtrl, data.phones.join(', '));
    fill('emails', _emailsCtrl, data.emails.join(', '));

    final address = data.address;
    if (address != null && _addressEntries.first.isEmpty) {
      final entry = _addressEntries.first;
      entry.street.text = address.street ?? '';
      entry.city.text = address.city ?? '';
      entry.state.text = address.state ?? '';
      entry.postalCode.text = address.postalCode ?? '';
      entry.country.text = address.country ?? '';
      _scannedFields.add('address');
    }

    if (_selectedCompanyId == null && data.companyName != null) {
      _scannedCompanyName = data.companyName;
    }
  }

  /// Picks the portrait for the user's own card. Unlike the card photos this
  /// one is never scanned — it is a face, not a source of fields.
  Future<void> _pickProfileImage() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await _askImageSource(l10n.addCardProfilePhotoSourceTitle);
    if (source == null) return;

    final pickedFile = await _pick(source, UploadImageKind.avatar);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImage = pickedFile;
      _pickedImageBytes = bytes;
    });
  }

  /// Picks or captures a photo of one side of the physical card, then reads it
  /// so the newly captured side can contribute to the form right away.
  Future<void> _pickCardImage({required bool isFront}) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await _askImageSource(
        isFront ? l10n.addCardFrontSourceTitle : l10n.addCardBackSourceTitle);
    if (source == null) return;

    final pickedFile = await _pick(source, UploadImageKind.card);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (isFront) {
        _frontImage = pickedFile;
        _frontImageBytes = bytes;
      } else {
        _backImage = pickedFile;
        _backImageBytes = bytes;
      }
    });

    await _runOcr(silentWhenEmpty: true);
  }

  /// Re-reads the front card photo and fills any field still blank. Existing
  /// values are never overwritten — see [_applyScanned]. Only the front side
  /// is read; the back photo is stored but not scanned.
  Future<void> _runOcr({bool silentWhenEmpty = false}) async {
    final front = _frontImage;
    if (front == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isRescanning = true);
    try {
      final scanned = await ref.read(cardScannerProvider).scan(front.path);
      if (!mounted) return;

      if (scanned.isEmpty) {
        if (!silentWhenEmpty) {
          _showToast(
            l10n.addCardOcrNoTextFound,
            isError: true,
          );
        }
        return;
      }

      setState(() => _applyScanned(scanned));
      unawaited(_resolveScannedCompany());
      if (!silentWhenEmpty) {
        _showToast(l10n.addCardScannedDetailsAdded);
      }
    } catch (e) {
      debugPrint('OCR failed: $e');
      if (!mounted) return;
      if (!silentWhenEmpty) {
        _showToast(l10n.addCardScanFailed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isRescanning = false);
    }
  }

  Future<XFile?> _pick(ImageSource source, UploadImageKind kind) async {
    try {
      return await pickImageForUpload(source, kind);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showToast(
            l10n.addCardCouldNotOpenSource(source == ImageSource.camera
                ? l10n.addCardSourceCamera
                : l10n.addCardSourceGallery),
            isError: true);
      }
      return null;
    }
  }

  /// Delegates to the shared sheet so this form and the Saved Cards scan
  /// entry offer the same choice in the same place.
  Future<ImageSource?> _askImageSource(String title) =>
      showImageSourceSheet(context, title: title);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _positionCtrl.dispose();
    _phonesCtrl.dispose();
    _emailsCtrl.dispose();
    for (final entry in _addressEntries) {
      entry.dispose();
    }
    _bioCtrl.dispose();
    _profileImageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCompany() async {
    final result = await Navigator.of(context).push(
      AppPageRoute(builder: (_) => const CompanySelectPage()),
    );
    if (result != null && result is CompanyModel) {
      setState(() {
        _selectedCompanyId = result.id;
        _selectedCompanyName = result.name;
        // A hand-picked company overrides whatever the scan concluded, so the
        // scan's own note about it should stop being shown.
        _scannedCompanyName = null;
        _companyCreatedByScan = null;
      });
    }
  }

  /// Links the card to the company OCR read off it when one already on file
  /// matches. When none does, files it as a new company right away — the scan
  /// flow should not stall on a confirmation for something this routine.
  ///
  /// Failures stay quiet — the hint falls back to pointing at the picker, so a
  /// card can still be saved by hand.
  Future<void> _resolveScannedCompany() async {
    final name = _scannedCompanyName;
    if (name == null || _selectedCompanyId != null || _isResolvingCompany) {
      return;
    }

    setState(() => _isResolvingCompany = true);
    CompanyModel? match;
    try {
      match =
          await ref.read(companyProvider.notifier).findByName(name);
    } catch (_) {
      match = null;
    }
    if (!mounted) return;

    if (match != null) {
      final matched = match;
      setState(() {
        _selectedCompanyId = matched.id;
        _selectedCompanyName = matched.name;
        _companyCreatedByScan = false;
        _isResolvingCompany = false;
      });
      return;
    }

    // Nothing matched — file it as a new company without asking.
    try {
      final created =
          await ref.read(companyProvider.notifier).createMinimal(name);
      if (!mounted || created == null) return;
      setState(() {
        _selectedCompanyId = created.id;
        _selectedCompanyName = created.name;
        _companyCreatedByScan = true;
      });
    } finally {
      if (mounted) setState(() => _isResolvingCompany = false);
    }
  }

  /// Everything the user can change on this form, flattened to one string.
  /// New photos aren't in it — any picked photo counts as a change by itself.
  String _formSignature() => [
        _nameCtrl.text,
        _positionCtrl.text,
        _phonesCtrl.text,
        _emailsCtrl.text,
        _bioCtrl.text,
        _profileImageCtrl.text,
        _selectedCompanyId,
        _profession,
        for (final e in _addressEntries.where((e) => !e.isEmpty))
          e.toModel().displayText,
      ].map((v) => (v ?? '').toString().trim()).join('\u0000');

  /// Photos picked or carried over from the scan this session — the ones
  /// that exist nowhere else yet.
  int get _newPhotoCount => [_frontImage, _backImage, _pickedImage]
      .where((f) => f != null)
      .length;

  bool get _isDirty =>
      !_saved &&
      (_newPhotoCount > 0 || _formSignature() != _baselineSignature);

  /// Back, swipe-back and the app bar arrow all land here. Leaving an
  /// untouched form is instant; otherwise the sheet names what goes with it.
  Future<void> _handleBack() async {
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await _showDiscardSheet();
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<bool?> _showDiscardSheet() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photos = _newPhotoCount;
    final fields = _scannedFields.length;

    final String body;
    if (photos > 0 && fields > 0) {
      body = l10n.addCardDiscardBodyItems(l10n.addCardDiscardBoth(
          l10n.addCardDiscardPhotoCount(photos),
          l10n.addCardDiscardScannedFieldCount(fields)));
    } else if (photos > 0) {
      body = l10n.addCardDiscardBodyItems(l10n.addCardDiscardPhotoCount(photos));
    } else if (fields > 0) {
      body = l10n.addCardDiscardBodyItems(
          l10n.addCardDiscardScannedFieldCount(fields));
    } else {
      body = l10n.addCardDiscardBodyGeneric;
    }

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Wallet.surfaceOf(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Wallet.radiusPanel),
        ),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              Wallet.margin, 10, Wallet.margin, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  color: Wallet.lineOf(isDark),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Wallet.danger.withOpacity(isDark ? .18 : .1),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: Wallet.danger),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isEditing
                          ? l10n.addCardDiscardEditTitle
                          : l10n.addCardDiscardNewTitle,
                      style: AppTypography.primary(TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: Wallet.inkOf(isDark),
                      )),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: AppTypography.secondary(TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Wallet.mutedOf(isDark),
                )),
              ),
              const SizedBox(height: 24),
              // Staying is the safe choice, so it gets the filled button.
              AppPrimaryButton(
                text: l10n.addCardKeepEditing,
                loading: false,
                onPressed: () => Navigator.of(sheetContext).pop(false),
                height: 52,
                borderRadius: BorderRadius.circular(14),
                fontSize: 16,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Wallet.danger,
                  ),
                  child: Text(
                    l10n.addCardDiscard,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _splitToList(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String? _validateEmails(String? value) {
    final emails = _splitToList(value ?? '');
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    for (final e in emails) {
      if (!emailRegex.hasMatch(e)) {
        return AppLocalizations.of(context)!.addCardInvalidEmail(e);
      }
    }
    return null;
  }

  String? _validatePhones(String? value) {
    final phones = _splitToList(value ?? '');
    for (final p in phones) {
      if (p.length < 6) return AppLocalizations.of(context)!.addCardPhoneTooShort;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(cardProvider.notifier);
    final companyId = _selectedCompanyId;
    final name = _nameCtrl.text.trim();
    final position = _positionCtrl.text.trim();
    final phones = _splitToList(_phonesCtrl.text);
    final emails = _splitToList(_emailsCtrl.text);
    final addresses = _addressEntries
        .where((e) => !e.isEmpty)
        .map((e) => e.toModel())
        .toList();
    final bio = _bioCtrl.text.trim();
    final profileImage = _profileImageCtrl.text.trim();

    AppResult result;
    if (isEditing && widget.card!.id != 0) {
      result = await notifier.updateCard(
        widget.card!.id,
        name: name.isEmpty ? null : name,
        companyId: companyId,
        position: position.isEmpty ? null : position,
        profession: _profession,
        phones: phones.isEmpty ? null : phones,
        emails: emails.isEmpty ? null : emails,
        addresses: addresses.isEmpty ? null : addresses,
        bio: bio.isEmpty ? null : bio,
        profileImage: profileImage.isEmpty ? null : profileImage,
        imageFile: _pickedImage, // Pass image file
        frontImageFile: _frontImage,
        backImageFile: _backImage,
        // Preserve the existing type; omitting it blanks card_type server-side.
        cardType: widget.card!.cardType,
      );
    } else {
      result = await notifier.createCard(
        name: name.isEmpty ? null : name,
        companyId: companyId,
        position: position.isEmpty ? null : position,
        profession: _profession,
        phones: phones.isEmpty ? null : phones,
        emails: emails.isEmpty ? null : emails,
        addresses: addresses.isEmpty ? null : addresses,
        bio: bio.isEmpty ? null : bio,
        profileImage: profileImage.isEmpty ? null : profileImage,
        imageFile: _pickedImage, // Pass image file
        frontImageFile: _frontImage,
        backImageFile: _backImage,
        cardType: (isEditing && widget.card!.id == 0)
            ? 'user_card'
            : (widget.cardType ?? 'saved_card'),
      );
    }

    if (!mounted) return;
    if (result.isSuccess) {
      // A newly typed profession is now on the server's list.
      ref.invalidate(professionsProvider);
      _saved = true;
      // Success toast is shown by the caller after pop (to avoid timing issues with navigation)
      Navigator.of(context).pop(true);
    } else {
      final l10n = AppLocalizations.of(context)!;
      final msg = result.message;
      _showToast(
        (msg != null && msg.isNotEmpty && msg != 'null')
            ? msg
            : (isEditing ? l10n.addCardUpdateFailed : l10n.addCardCreateFailed),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreating =
        ref.watch(cardProvider).valueOrNull?.isCreating ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // Never pops on its own: typing doesn't rebuild this widget, so a canPop
    // worked out at build time could be stale. _handleBack decides at the
    // moment of leaving instead. The cost is that iOS swipe-back is off here.
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      backgroundColor:
          Wallet.groundOf(isDark),
      appBar: AppBar(
        title: Text(isEditing ? l10n.addCardEditTitle : l10n.addCardAddTitle,
            style: TextStyle(
                color: Wallet.inkOf(isDark),
                fontWeight: FontWeight.w600)),
        backgroundColor: Wallet.groundOf(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: Wallet.inkOf(isDark)),
      ),
      bottomNavigationBar: _buildSubmitBar(isCreating, isDark),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      Responsive.isDesktop(context) ? 720 : double.infinity,
                ),
                child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardPhotosPanel(),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.badge_outlined,
                    title: l10n.addCardPersonalInfoTitle,
                    subtitle: isOwnProfileCard
                        ? l10n.addCardPersonalInfoSubtitleOwn
                        : l10n.addCardPersonalInfoSubtitleOther,
                    children: [
                      if (isOwnProfileCard) ...[
                        _buildProfilePhotoRow(),
                        const SizedBox(height: 16),
                      ],
                      _buildPremiumTextField(
                        controller: _nameCtrl,
                        fieldKey: 'name',
                        label: l10n.addCardFullNameLabel,
                        hint: l10n.addCardFullNameHint,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                      _buildPremiumTextField(
                        controller: _positionCtrl,
                        fieldKey: 'position',
                        label: l10n.addCardPositionLabel,
                        hint: l10n.addCardPositionHint,
                        icon: Icons.work_outline,
                      ),
                      const SizedBox(height: 16),
                      // Rebuilt as the position is typed, so its suggestion
                      // follows along.
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _positionCtrl,
                        builder: (_, position, __) => ProfessionPicker(
                          value: _profession,
                          position: position.text,
                          enabled: !isCreating,
                          onChanged: (value) =>
                              setState(() => _profession = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.apartment_outlined,
                    title: l10n.addCardCompanySectionTitle,
                    subtitle: l10n.addCardCompanySectionSubtitle,
                    children: [
                      _buildCompanySelector(),
                      ..._buildScannedCompanyHint(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.contact_phone_outlined,
                    title: l10n.addCardContactDetailsTitle,
                    subtitle: l10n.addCardContactDetailsSubtitle,
                    children: [
                      _buildPremiumTextField(
                        controller: _phonesCtrl,
                        fieldKey: 'phones',
                        label: l10n.addCardPhonesLabel,
                        hint: l10n.addCardPhonesHint,
                        icon: Icons.phone_outlined,
                        validator: _validatePhones,
                      ),
                      const SizedBox(height: 14),
                      _buildPremiumTextField(
                        controller: _emailsCtrl,
                        fieldKey: 'emails',
                        label: l10n.addCardEmailsLabel,
                        hint: l10n.addCardEmailsHint,
                        icon: Icons.email_outlined,
                        validator: _validateEmails,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.place_outlined,
                    title: l10n.addCardAddressesTitle,
                    subtitle: l10n.addCardAddressesSubtitle,
                    children: _buildAddressSection(),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.notes_outlined,
                    title: l10n.addCardMoreTitle,
                    subtitle: l10n.addCardMoreSubtitle,
                    children: [
                      _buildPremiumTextField(
                        controller: _bioCtrl,
                        label: l10n.addCardBioLabel,
                        hint: l10n.addCardBioHint,
                        icon: Icons.info_outline,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
              ),
            ),
          ),
          if (isCreating)
            Container(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.5),
              child: const Center(child: LoadingView(size: 96)),
            ),
        ],
      ),
      ),
    );
  }

  /// Photos of the physical card, first because they are what a scanned card
  /// starts from — and what fills the rest of the form in.
  Widget _buildCardPhotosPanel() {
    final hasFront = _frontImageBytes != null || _frontImageUrl != null;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildSection(
      icon: Icons.credit_card_outlined,
      title: isOwnProfileCard
          ? l10n.addCardYourCardPhotosTitle
          : l10n.addCardCardPhotosTitle,
      subtitle: hasFront
          ? l10n.addCardPhotosSubtitleHasFront
          : (isOwnProfileCard
              ? l10n.addCardPhotosSubtitleOwnEmpty
              : l10n.addCardPhotosSubtitleOtherEmpty),
      trailing: hasFront
          ? TextButton.icon(
              onPressed: _isRescanning ? null : () => _runOcr(),
              style: TextButton.styleFrom(
                foregroundColor: Wallet.accentOf(isDark),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              icon: _isRescanning
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high, size: 16),
              label: Text(_isRescanning ? l10n.addCardReading : l10n.addCardRescan),
            )
          : null,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCardPhotoTile(
                label: 'Front',
                bytes: _frontImageBytes,
                remoteUrl: _frontImageUrl,
                isFront: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardPhotoTile(
                label: 'Back',
                bytes: _backImageBytes,
                remoteUrl: _backImageUrl,
                isFront: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// A titled panel. Grouping a long form into panels gives it a hierarchy —
  /// each block reads as one decision instead of an undifferentiated stack of
  /// inputs.
  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Wallet.surfaceOf(isDark),
        borderRadius: BorderRadius.circular(Wallet.radiusCard),
        border: Wallet.borderOf(isDark),
        boxShadow: Wallet.shadowOf(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Wallet.tintOf(isDark),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: Wallet.accentOf(isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Wallet.darkInk
                            : Wallet.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Wallet.mutedOf(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Sticky action bar. On a form this long the primary action should not be
  /// something you have to scroll to find.
  Widget _buildSubmitBar(bool isCreating, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Wallet.surfaceOf(isDark),
        border: Border(
          top: BorderSide(
            color: Wallet.lineOf(isDark),
          ),
        ),
      ),
      child: AppPrimaryButton(
        text: isEditing
            ? AppLocalizations.of(context)!.addCardSaveChanges
            : AppLocalizations.of(context)!.addCardCreateCard,
        loading: isCreating,
        onPressed: isCreating ? null : _submit,
        height: 52,
        borderRadius: BorderRadius.circular(14),
        fontSize: 16,
      ),
    );
  }

  /// The portrait picker for the user's own card: the avatar itself is the
  /// control, with the text beside it saying what tapping does.
  Widget _buildProfilePhotoRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final bytes = _pickedImageBytes;
    final remoteUrl = ImageUrl.resolve(widget.card?.profileImage);
    final hasPhoto = bytes != null || remoteUrl != null;
    final name = _nameCtrl.text.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return InkWell(
      onTap: _pickProfileImage,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Wallet.accentOf(isDark),
                  ),
                  child: ClipOval(
                    child: bytes != null
                        ? Image.memory(bytes, fit: BoxFit.cover)
                        : (remoteUrl != null
                            ? Image.network(
                                remoteUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildAvatarFallback(initial, isDark),
                              )
                            : _buildAvatarFallback(initial, isDark)),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Wallet.accentOf(isDark),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Wallet.surfaceOf(isDark),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      hasPhoto
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto ? l10n.addCardChangeProfilePhoto : l10n.addCardAddProfilePhoto,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Wallet.darkInk
                        : Wallet.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.addCardProfilePhotoHelp,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Wallet.mutedOf(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String initial, bool isDark) {
    return Container(
      color: Wallet.tintOf(isDark),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Wallet.accentOf(isDark),
        ),
      ),
    );
  }

  Widget _buildCardPhotoTile({
    required String label,
    required Uint8List? bytes,
    required String? remoteUrl,
    required bool isFront,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final hasImage = bytes != null || remoteUrl != null;

    return GestureDetector(
      onTap: () => _pickCardImage(isFront: isFront),
      child: AspectRatio(
        // Roughly the proportions of a printed business card, so the preview
        // reads as the card itself rather than a generic image slot.
        aspectRatio: 1.7,
        child: Container(
          decoration: BoxDecoration(
            color: Wallet.surfaceOf(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasImage
                  ? Wallet.lineOf(isDark)
                  : Wallet.accentOf(isDark).withOpacity(0.4),
              width: hasImage ? 1 : 1.5,
              style: BorderStyle.solid,
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
                      _buildCardPhotoPlaceholder(label, isDark),
                )
              else
                _buildCardPhotoPlaceholder(label, isDark),
              if (hasImage)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label == 'Front' ? l10n.addCardFrontLabel : l10n.addCardBackLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (hasImage)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit,
                        size: 13, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPhotoPlaceholder(String label, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    // The tile is a 1.7 aspect box, so on a narrow screen it is short enough
    // for this stack to run past it. Scaling down beats clipping.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 22,
            color: Wallet.accentOf(isDark),
          ),
          const SizedBox(height: 6),
          Text(
            label == 'Front' ? l10n.addCardFrontLabel : l10n.addCardBackLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Wallet.darkInk : Wallet.ink,
            ),
          ),
          Text(
            label == 'Back' ? l10n.addCardOptional : l10n.addCardRequiredToScan,
            style: TextStyle(
              fontSize: 11,
              color: Wallet.mutedOf(isDark),
            ),
          ),
        ],
      ),
    );
  }

  /// Reports what became of the company name OCR read off the card: filed as a
  /// new company, matched to one already on file, or still unresolved — in
  /// which case it points at the picker, as it always did.
  ///
  /// Auto-linking is silent about the id it chose, and the user may well
  /// disagree with it, so the outcome is always stated and the picker stays one
  /// tap away underneath.
  List<Widget> _buildScannedCompanyHint() {
    final scannedName = _scannedCompanyName;
    if (scannedName == null) return [];
    final l10n = AppLocalizations.of(context)!;

    final IconData icon;
    final String message;
    // Only the unresolved state asks for a decision; the others are reports.
    final bool needsChoice;

    if (_isResolvingCompany) {
      icon = Icons.hourglass_top;
      message = l10n.addCardFilingCompany(scannedName);
      needsChoice = false;
    } else if (_companyCreatedByScan == true) {
      icon = Icons.add_business_outlined;
      message = l10n.addCardAddedNewCompany(scannedName);
      needsChoice = false;
    } else if (_companyCreatedByScan == false) {
      icon = Icons.auto_awesome;
      message = l10n.addCardMatchedCompany(scannedName);
      needsChoice = false;
    } else {
      icon = Icons.auto_awesome;
      message = l10n.addCardScannedPickCompany(scannedName);
      needsChoice = true;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      const SizedBox(height: 10),
      InkWell(
        onTap: _isResolvingCompany ? null : _pickCompany,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Wallet.tintOf(isDark),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: Wallet.accentOf(isDark)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Wallet.darkInk
                        : Wallet.ink,
                  ),
                ),
              ),
              if (!_isResolvingCompany)
                Text(
                  needsChoice ? l10n.addCardChoose : l10n.addCardChange,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Wallet.accentOf(isDark),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  /// Marks a field OCR filled in, so the user knows which values to
  /// double-check before saving. It sits in the field's label row rather than
  /// inside the input, where it used to crowd long values like emails.
  Widget _buildScannedBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = Wallet.accentOf(isDark);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: tint.withOpacity(isDark ? 0.20 : 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tint.withOpacity(isDark ? 0.40 : 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 11, color: tint),
          const SizedBox(width: 5),
          Text(
            AppLocalizations.of(context)!.addCardScannedBadge,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAddressSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final widgets = <Widget>[];

    for (var i = 0; i < _addressEntries.length; i++) {
      final entry = _addressEntries[i];
      widgets.add(Container(
        margin: EdgeInsets.only(top: i == 0 ? 0 : 14),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        decoration: BoxDecoration(
          color: Wallet.groundOf(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Wallet.lineOf(isDark),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.addCardAddressNumber(i + 1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Wallet.mutedOf(isDark),
                    ),
                  ),
                ),
                if (_addressEntries.length > 1)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _addressEntries.removeAt(i).dispose();
                      });
                    },
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Wallet.danger),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPremiumTextField(
              controller: entry.street,
              label: l10n.addCardStreetLabel,
              hint: l10n.addCardStreetHint,
              icon: Icons.location_on_outlined,
              maxLines: 2,
              // Only the first entry can be scan-filled; see _applyScanned.
              fieldKey: i == 0 ? 'address' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPremiumTextField(
                    controller: entry.city,
                    label: l10n.addCardCityLabel,
                    hint: l10n.addCardCityHint,
                    validator: (_) => entry.isEmpty || entry.hasCity
                        ? null
                        : l10n.addCardCityRequired,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPremiumTextField(
                    controller: entry.state,
                    label: l10n.addCardStateLabel,
                    hint: l10n.addCardOptional,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPremiumTextField(
                    controller: entry.postalCode,
                    label: l10n.addCardPostalCodeLabel,
                    hint: l10n.addCardOptional,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPremiumTextField(
                    controller: entry.country,
                    label: l10n.addCardCountryLabel,
                    hint: l10n.addCardCountryHint,
                    validator: (_) => entry.isEmpty || entry.hasCountry
                        ? null
                        : l10n.addCardCountryRequired,
                  ),
                ),
              ],
            ),
          ],
        ),
      ));
    }

    widgets.add(Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _addressEntries.add(_AddressEntry());
          });
        },
        icon: const Icon(Icons.add, size: 18),
        label: Text(l10n.addCardAddAddress),
      ),
    ));

    return widgets;
  }

  /// One form field: a label row above the input (which is where the scanned
  /// badge lives) and a bordered input below it. The borders come from
  /// [InputDecoration] rather than a wrapping container so focus, error, and
  /// scanned states are all visible without tracking focus by hand.
  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? fieldKey,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isScanned = fieldKey != null && _scannedFields.contains(fieldKey);

    final idle = isScanned
        ? Wallet.accentOf(isDark).withOpacity(isDark ? 0.38 : 0.26)
        : Wallet.lineOf(isDark);
    final fill = isScanned
        ? Wallet.accentOf(isDark).withOpacity(isDark ? 0.10 : 0.04)
        : (isDark ? Wallet.darkSurface : AppColors.surfaceSoft);
    const error = Wallet.danger;

    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color:
                    Wallet.mutedOf(isDark),
              ),
            ),
            if (isScanned) ...[
              const SizedBox(width: 8),
              _buildScannedBadge(),
            ],
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Wallet.darkInk : Wallet.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: Wallet.faintOf(isDark),
            ),
            prefixIcon: icon != null
                ? Icon(icon,
                    size: 20,
                    color: isScanned
                        ? Wallet.accentOf(isDark).withOpacity(.85)
                        : Wallet.faintOf(isDark))
                : null,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 0),
            filled: true,
            fillColor: fill,
            isDense: true,
            contentPadding: EdgeInsets.fromLTRB(icon != null ? 0 : 14, 14, 14, 14),
            enabledBorder: outline(idle, 1),
            focusedBorder: outline(Wallet.accentOf(isDark), 1.6),
            errorBorder: outline(error, 1),
            focusedErrorBorder: outline(error, 1.6),
            errorStyle: const TextStyle(fontSize: 11.5, color: error),
          ),
        ),
      ],
    );
  }

  /// Matches the text fields: same label row, same border treatment, so the
  /// picker reads as one of the form's fields rather than a card floating
  /// above them.
  Widget _buildCompanySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final hasCompany = _selectedCompanyName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.addCardSelectedCompanyLabel,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Wallet.mutedOf(isDark),
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: _pickCompany,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Wallet.darkSurface : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Wallet.lineOf(isDark),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Wallet.tintOf(isDark),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.business_outlined,
                    size: 20,
                    color: Wallet.accentOf(isDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCompanyName ?? l10n.addCardChooseCompany,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          hasCompany ? FontWeight.w600 : FontWeight.w400,
                      color: hasCompany
                          ? (isDark
                              ? Wallet.darkInk
                              : Wallet.ink)
                          : (Wallet.faintOf(isDark)),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Wallet.faintOf(isDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Controllers for one structured address in the form. City and country are
/// required by the API once any field of the entry is filled.
class _AddressEntry {
  final street = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final postalCode = TextEditingController();
  final country = TextEditingController();

  _AddressEntry();

  factory _AddressEntry.fromModel(AddressModel model) {
    final entry = _AddressEntry();
    entry.street.text = model.street ?? '';
    entry.city.text = model.city ?? '';
    entry.state.text = model.state ?? '';
    entry.postalCode.text = model.postalCode ?? '';
    entry.country.text = model.country ?? '';
    return entry;
  }

  List<TextEditingController> get _controllers =>
      [street, city, state, postalCode, country];

  bool get isEmpty => _controllers.every((c) => c.text.trim().isEmpty);

  bool get hasCity => city.text.trim().isNotEmpty;

  bool get hasCountry => country.text.trim().isNotEmpty;

  AddressModel toModel() {
    String? valueOf(TextEditingController c) {
      final text = c.text.trim();
      return text.isEmpty ? null : text;
    }

    return AddressModel(
      street: valueOf(street),
      city: valueOf(city),
      state: valueOf(state),
      postalCode: valueOf(postalCode),
      country: valueOf(country),
    );
  }

  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
  }
}
