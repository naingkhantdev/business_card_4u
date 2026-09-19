import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../providers/company/company_provider.dart';
import '../../providers/ocr/card_scanner_provider.dart';
import '../../utils/app_result.dart';
import '../../network/image_url.dart';
import '../../data/vos/address_model.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../data/vos/scanned_card_data.dart';
import '../theme/app_colors.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/image_source_sheet.dart';
import '../widgets/loading_view.dart';
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

  /// Scanned company name the user said not to file as a new company, so a
  /// rescan (e.g. reading the back of the same card) doesn't ask again.
  String? _companyCreationDeclinedFor;

  /// Field keys that were filled by OCR rather than typed, so the form can
  /// mark them as needing a glance.
  final Set<String> _scannedFields = {};

  bool _isRescanning = false;

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
    final source = await _askImageSource('Profile photo');
    if (source == null) return;

    final pickedFile = await _pick(source);
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
    final source =
        await _askImageSource(isFront ? 'Card front' : 'Card back');
    if (source == null) return;

    final pickedFile = await _pick(source);
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

    setState(() => _isRescanning = true);
    try {
      final scanned = await ref.read(cardScannerProvider).scan(front.path);
      if (!mounted) return;

      if (scanned.isEmpty) {
        if (!silentWhenEmpty) {
          _showToast(
            "Couldn't read any text from that photo. Try better lighting, or fill the form in yourself.",
            isError: true,
          );
        }
        return;
      }

      setState(() => _applyScanned(scanned));
      unawaited(_resolveScannedCompany());
      if (!silentWhenEmpty) {
        _showToast('Scanned details added. Check them before saving.');
      }
    } catch (e) {
      debugPrint('OCR failed: $e');
      if (!mounted) return;
      if (!silentWhenEmpty) {
        _showToast('Could not scan that photo. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isRescanning = false);
    }
  }

  Future<XFile?> _pick(ImageSource source) async {
    try {
      return await ImagePicker().pickImage(source: source);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        _showToast('Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}.',
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
      MaterialPageRoute(builder: (_) => const CompanySelectPage()),
    );
    if (result != null && result is CompanyModel) {
      setState(() {
        _selectedCompanyId = result.id;
        _selectedCompanyName = result.name;
        // A hand-picked company overrides whatever the scan concluded, so the
        // scan's own note about it should stop being shown.
        _scannedCompanyName = null;
        _companyCreatedByScan = null;
        _companyCreationDeclinedFor = null;
      });
    }
  }

  /// Links the card to the company OCR read off it when one already on file
  /// matches. When none does, asks before filing a new one — unlike a
  /// straight name match, creating a record is a real decision, and a scan
  /// occasionally misreads a name badly enough that it shouldn't happen
  /// unasked.
  ///
  /// Declining leaves the scan unresolved rather than trying again: the hint
  /// keeps pointing at the picker, and a rescan of the same card won't ask a
  /// second time for the same name.
  ///
  /// Failures stay quiet — the hint falls back to pointing at the picker, so a
  /// card can still be saved by hand.
  Future<void> _resolveScannedCompany() async {
    final name = _scannedCompanyName;
    if (name == null ||
        _selectedCompanyId != null ||
        _isResolvingCompany ||
        _companyCreationDeclinedFor == name) {
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

    // Nothing matched — ask before creating one. The dialog closes the
    // "resolving" state itself; the field a scan produced may have already
    // been overridden or re-scanned by the time the user answers.
    setState(() => _isResolvingCompany = false);
    final shouldCreate = await _confirmCreateCompany(name);
    if (!mounted || _scannedCompanyName != name || _selectedCompanyId != null) {
      return;
    }
    if (!shouldCreate) {
      setState(() => _companyCreationDeclinedFor = name);
      return;
    }

    setState(() => _isResolvingCompany = true);
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

  /// Asks whether the scanned name should be filed as a new company. Styled
  /// like the other confirmation dialogs in the app (Manage Companies'
  /// delete prompt) so it doesn't look like a stray system dialog.
  Future<bool> _confirmCreateCompany(String name) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,
        backgroundColor: isDark ? Wallet.darkSurface : Colors.white,
        surfaceTintColor: isDark ? Wallet.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add new company?',
          style: TextStyle(color: isDark ? Wallet.darkInk : Wallet.ink),
        ),
        content: Text(
          'No company named "$name" is on file yet. '
          'Add it as a new company?',
          style: TextStyle(
            color: isDark ? Wallet.darkMuted : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Not now',
              style: TextStyle(
                color: isDark ? Wallet.darkMuted : Colors.grey,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add company'),
          ),
        ],
      ),
    );
    return result ?? false;
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
        return 'Invalid email: $e';
      }
    }
    return null;
  }

  String? _validatePhones(String? value) {
    final phones = _splitToList(value ?? '');
    for (final p in phones) {
      if (p.length < 6) return 'Each phone must be at least 6 characters';
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
      // Success toast is shown by the caller after pop (to avoid timing issues with navigation)
      Navigator.of(context).pop(true);
    } else {
      final msg = result.message;
      _showToast(
        (msg != null && msg.isNotEmpty && msg != 'null')
            ? msg
            : (isEditing ? 'Failed to update card' : 'Failed to create card'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreating =
        ref.watch(cardProvider).valueOrNull?.isCreating ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? Wallet.darkGround : const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Business Card' : 'Add Business Card',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600)),
        backgroundColor: isDark ? Wallet.darkGround : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      bottomNavigationBar: _buildSubmitBar(isCreating, isDark),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardPhotosPanel(),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.badge_outlined,
                    title: 'Personal info',
                    subtitle: isOwnProfileCard
                        ? 'Your photo, name, and role as others see them'
                        : 'The name and role printed on the card',
                    children: [
                      if (isOwnProfileCard) ...[
                        _buildProfilePhotoRow(),
                        const SizedBox(height: 16),
                      ],
                      _buildPremiumTextField(
                        controller: _nameCtrl,
                        fieldKey: 'name',
                        label: "Full name",
                        hint: "e.g. John Doe",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                      _buildPremiumTextField(
                        controller: _positionCtrl,
                        fieldKey: 'position',
                        label: "Position",
                        hint: "e.g. Software Engineer",
                        icon: Icons.work_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.apartment_outlined,
                    title: 'Company',
                    subtitle: 'Links this card to a company record',
                    children: [
                      _buildCompanySelector(),
                      ..._buildScannedCompanyHint(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.contact_phone_outlined,
                    title: 'Contact details',
                    subtitle: 'Separate several entries with commas',
                    children: [
                      _buildPremiumTextField(
                        controller: _phonesCtrl,
                        fieldKey: 'phones',
                        label: "Phones",
                        hint: "e.g. 998991112233, ...",
                        icon: Icons.phone_outlined,
                        validator: _validatePhones,
                      ),
                      const SizedBox(height: 14),
                      _buildPremiumTextField(
                        controller: _emailsCtrl,
                        fieldKey: 'emails',
                        label: "Emails",
                        hint: "e.g. mail@example.com, ...",
                        icon: Icons.email_outlined,
                        validator: _validateEmails,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.place_outlined,
                    title: 'Addresses',
                    subtitle: 'Where this person works',
                    children: _buildAddressSection(),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.notes_outlined,
                    title: 'More',
                    subtitle: 'Anything worth remembering about this contact',
                    children: [
                      _buildPremiumTextField(
                        controller: _bioCtrl,
                        label: "Bio",
                        hint: "Short description...",
                        icon: Icons.info_outline,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ],
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
    );
  }

  /// Photos of the physical card, first because they are what a scanned card
  /// starts from — and what fills the rest of the form in.
  Widget _buildCardPhotosPanel() {
    final hasFront = _frontImageBytes != null || _frontImageUrl != null;

    return _buildSection(
      icon: Icons.credit_card_outlined,
      title: isOwnProfileCard ? 'Your card photos' : 'Card photos',
      subtitle: hasFront
          ? 'Tap a photo to replace it. Scanning only fills empty fields.'
          : (isOwnProfileCard
              ? 'Add both sides of your printed card so people can see the '
                  'real thing.'
              : 'Add a photo of the card to fill this form automatically.'),
      trailing: hasFront
          ? TextButton.icon(
              onPressed: _isRescanning ? null : () => _runOcr(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
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
              label: Text(_isRescanning ? 'Reading…' : 'Rescan'),
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
        color: isDark ? Wallet.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Wallet.darkLine : Wallet.ground,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D101828),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
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
                          color: isDark
                              ? const Color(0xFF8C9DBA)
                              : const Color(0xFF6B7688),
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
        color: isDark ? const Color(0xFF080E1C) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Wallet.darkLine : Wallet.ground,
          ),
        ),
      ),
      child: AppPrimaryButton(
        text: isEditing ? 'Save changes' : 'Create card',
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Wallet.darkSurface
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      hasPhoto
                          ? Icons.edit_rounded
                          : Icons.add_a_photo_rounded,
                      size: 12,
                      color: Colors.white,
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
                  hasPhoto ? 'Change profile photo' : 'Add a profile photo',
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
                  'Shown at the top of your card and next to your name in '
                  'search results.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark
                        ? const Color(0xFF8C9DBA)
                        : const Color(0xFF6B7688),
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
      color: isDark ? Wallet.darkSurface : const Color(0xFFF1ECFF),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: isDark ? AppColors.primaryLight : AppColors.primary,
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
    final hasImage = bytes != null || remoteUrl != null;

    return GestureDetector(
      onTap: () => _pickCardImage(isFront: isFront),
      child: AspectRatio(
        // Roughly the proportions of a printed business card, so the preview
        // reads as the card itself rather than a generic image slot.
        aspectRatio: 1.7,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Wallet.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasImage
                  ? (isDark ? Wallet.darkLine : Colors.grey.shade300)
                  : AppColors.primary.withOpacity(0.4),
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
                      label,
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
            color: isDark ? Wallet.accentDark : AppColors.primary,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Wallet.darkInk : Wallet.ink,
            ),
          ),
          Text(
            label == 'Back' ? 'Optional' : 'Required to scan',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Wallet.darkMuted : Colors.grey[600],
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

    final IconData icon;
    final String message;
    // Only the unresolved state asks for a decision; the others are reports.
    final bool needsChoice;

    if (_isResolvingCompany) {
      icon = Icons.hourglass_top;
      message = 'Filing "$scannedName"…';
      needsChoice = false;
    } else if (_companyCreatedByScan == true) {
      icon = Icons.add_business_outlined;
      message = 'Added "$scannedName" as a new company. '
          'Its industry and business type can be filled in any time.';
      needsChoice = false;
    } else if (_companyCreatedByScan == false) {
      icon = Icons.auto_awesome;
      message = 'Matched "$scannedName" to a company already on file.';
      needsChoice = false;
    } else {
      icon = Icons.auto_awesome;
      message = 'Scanned "$scannedName" — pick the matching company';
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
            color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
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
                  needsChoice ? 'Choose' : 'Change',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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
    final tint = isDark ? AppColors.primaryLight : AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.20 : 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.40 : 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 11, color: tint),
          const SizedBox(width: 5),
          Text(
            'Scanned',
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
    final widgets = <Widget>[];

    for (var i = 0; i < _addressEntries.length; i++) {
      final entry = _addressEntries[i];
      widgets.add(Container(
        margin: EdgeInsets.only(top: i == 0 ? 0 : 14),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0A0F1C)
              : const Color(0xFFFBFCFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Wallet.darkLine
                : Wallet.ground,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Address ${i + 1}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Wallet.darkMuted
                          : Colors.grey[600],
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
                        size: 20, color: Colors.redAccent),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPremiumTextField(
              controller: entry.street,
              label: "Street",
              hint: "e.g. 123 Main St",
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
                    label: "City",
                    hint: "e.g. Yangon",
                    validator: (_) => entry.isEmpty || entry.hasCity
                        ? null
                        : 'City is required',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPremiumTextField(
                    controller: entry.state,
                    label: "State / Region",
                    hint: "Optional",
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
                    label: "Postal Code",
                    hint: "Optional",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPremiumTextField(
                    controller: entry.country,
                    label: "Country",
                    hint: "e.g. Myanmar",
                    validator: (_) => entry.isEmpty || entry.hasCountry
                        ? null
                        : 'Country is required',
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
        label: const Text("Add address"),
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
        ? AppColors.primary.withOpacity(isDark ? 0.38 : 0.26)
        : (isDark ? const Color(0xFF232F4C) : const Color(0xFFE2E8F2));
    final fill = isScanned
        ? AppColors.primary.withOpacity(isDark ? 0.10 : 0.04)
        : (isDark ? Wallet.darkSurface : const Color(0xFFF9FAFC));
    const error = Color(0xFFDC2626);

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
                    isDark ? const Color(0xFF9FB0CC) : const Color(0xFF5B6779),
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
              color: isDark ? Wallet.darkFaint : const Color(0xFFA3ADBD),
            ),
            prefixIcon: icon != null
                ? Icon(icon,
                    size: 20,
                    color: isScanned
                        ? AppColors.primary.withOpacity(isDark ? 0.85 : 0.7)
                        : (isDark
                            ? const Color(0xFF7A8AA8)
                            : const Color(0xFF9AA5B5)))
                : null,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 0),
            filled: true,
            fillColor: fill,
            isDense: true,
            contentPadding: EdgeInsets.fromLTRB(icon != null ? 0 : 14, 14, 14, 14),
            enabledBorder: outline(idle, 1),
            focusedBorder: outline(AppColors.primary, 1.6),
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
    final hasCompany = _selectedCompanyName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected company',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: isDark ? const Color(0xFF9FB0CC) : const Color(0xFF5B6779),
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: _pickCompany,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Wallet.darkSurface
                  : const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Wallet.darkLine
                    : const Color(0xFFE2E8F2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.business_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.primaryLight
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCompanyName ?? 'Choose a company',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          hasCompany ? FontWeight.w600 : FontWeight.w400,
                      color: hasCompany
                          ? (isDark
                              ? Wallet.darkInk
                              : Wallet.ink)
                          : (isDark
                              ? Wallet.darkFaint
                              : const Color(0xFFA3ADBD)),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF7A8AA8)
                      : const Color(0xFF9AA5B5),
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
