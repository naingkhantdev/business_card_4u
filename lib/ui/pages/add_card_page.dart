import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../providers/ocr/card_scanner_provider.dart';
import '../../utils/app_result.dart';
import '../../network/image_url.dart';
import '../../data/vos/address_model.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
import '../../data/vos/scanned_card_data.dart';
import '../../exception/custom_exception.dart';
import '../theme/app_colors.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import 'company_select_page.dart';

class AddCardPage extends ConsumerStatefulWidget {
  final BusinessCardModel? card; // Pass card for edit mode
  final String? cardType; // 'user_card' for own profile, 'saved_card' for manual

  const AddCardPage({super.key, this.card, this.cardType});

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

  /// Paths of card photos already stored on the server (edit mode).
  final _frontImageCtrl = TextEditingController();
  final _backImageCtrl = TextEditingController();

  int? _selectedCompanyId;
  String? _selectedCompanyName;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  XFile? _pickedFrontImage;
  Uint8List? _pickedFrontBytes;
  XFile? _pickedBackImage;
  Uint8List? _pickedBackBytes;

  bool _isScanning = false;

  /// Company read off the card. It is only a hint: cards link to companies by
  /// id, so the user still picks the real record.
  String? _scannedCompanyName;

  bool get isEditing => widget.card != null;

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
      _frontImageCtrl.text = c.frontImage ?? '';
      _backImageCtrl.text = c.backImage ?? '';
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
  }

  Future<void> _pickImage() async {
    debugPrint("Picking image...");
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        debugPrint("Image picked: ${pickedFile.path}");
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedImage = pickedFile;
          _pickedImageBytes = bytes;
        });
      } else {
        debugPrint("No image picked");
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  /// Asks where the card photo should come from. Camera first: these are
  /// photos of a card the user is holding.
  Future<ImageSource?> _askPhotoSource(String title) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCardPhoto(_CardSide side) async {
    final source = await _askPhotoSource(
      side == _CardSide.front ? 'Front of card' : 'Back of card',
    );
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        // Text recognition needs detail, so the photo is kept close to full size.
        imageQuality: 90,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (side == _CardSide.front) {
          _pickedFrontImage = picked;
          _pickedFrontBytes = bytes;
        } else {
          _pickedBackImage = picked;
          _pickedBackBytes = bytes;
        }
      });

      if (side == _CardSide.front) {
        await _autoFillFromFrontPhoto();
      }
    } on PlatformException catch (e) {
      // mobile_scanner puts CAMERA in the merged manifest, so Android requires
      // the permission to be granted before the camera intent will open.
      debugPrint('Card photo picker failed: $e');
      if (!mounted) return;
      final deniedCamera = source == ImageSource.camera &&
          '${e.code} ${e.message}'.toLowerCase().contains('denied');
      _showToast(
        deniedCamera
            ? 'Camera permission is off. Allow it in Settings, or pick the photo from your gallery.'
            : 'Could not open that photo',
        isError: true,
      );
    } catch (e) {
      debugPrint('Error picking card photo: $e');
      if (mounted) _showToast('Could not open that photo', isError: true);
    }
  }

  void _clearCardPhoto(_CardSide side) {
    setState(() {
      if (side == _CardSide.front) {
        _pickedFrontImage = null;
        _pickedFrontBytes = null;
        _scannedCompanyName = null;
      } else {
        _pickedBackImage = null;
        _pickedBackBytes = null;
      }
    });
  }

  /// Reads the front photo with on-device OCR and fills the form.
  Future<void> _autoFillFromFrontPhoto() async {
    final photo = _pickedFrontImage;
    if (photo == null) {
      _showToast('Add a front photo first', isError: true);
      return;
    }

    setState(() => _isScanning = true);
    try {
      final scanned = await ref.read(cardScannerProvider).scan(photo.path);
      if (!mounted) return;

      if (scanned.isEmpty) {
        _showToast('No readable text on this photo', isError: true);
        return;
      }

      final filled = _applyScannedData(scanned);
      _showToast(
        filled.isEmpty
            ? 'Nothing to fill — those fields already have values'
            : 'Filled from photo: ${filled.join(', ')}',
      );
    } on CustomException catch (e) {
      if (mounted) _showToast(e.errorVo.message, isError: true);
    } catch (e) {
      debugPrint('Card scan failed: $e');
      if (mounted) _showToast('Could not read this photo', isError: true);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  /// Writes scanned values into empty fields only — anything the user already
  /// typed wins over a guess. Returns the labels of the fields that were filled.
  List<String> _applyScannedData(ScannedCardData scanned) {
    final filled = <String>[];

    void fill(TextEditingController controller, String? value, String label) {
      final text = value?.trim() ?? '';
      if (text.isEmpty || controller.text.trim().isNotEmpty) return;
      controller.text = text;
      filled.add(label);
    }

    fill(_nameCtrl, scanned.name, 'name');
    fill(_positionCtrl, scanned.position, 'position');
    fill(_phonesCtrl, scanned.phones.join(', '), 'phones');
    fill(_emailsCtrl, scanned.emails.join(', '), 'emails');
    // The card has no website field, so it is kept in the bio when that is free.
    fill(_bioCtrl, scanned.website, 'website');

    final address = scanned.address;
    if (address != null) {
      final emptyEntries = _addressEntries.where((entry) => entry.isEmpty);
      if (emptyEntries.isNotEmpty) {
        final target = emptyEntries.first;
        target.street.text = address.street ?? '';
        target.postalCode.text = address.postalCode ?? '';
        filled.add('address');
      }
    }

    setState(() {
      _scannedCompanyName =
          _selectedCompanyId == null ? scanned.companyName : null;
    });

    return filled;
  }

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
    _frontImageCtrl.dispose();
    _backImageCtrl.dispose();
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
        _scannedCompanyName = null;
      });
    }
  }

  bool get _hasRemoteProfileImage =>
      ImageUrl.resolve(_profileImageCtrl.text) != null;

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
    final frontImage = _frontImageCtrl.text.trim();
    final backImage = _backImageCtrl.text.trim();

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
        // Preserve the existing type; omitting it blanks card_type server-side.
        cardType: widget.card!.cardType,
        frontImage: frontImage.isEmpty ? null : frontImage,
        backImage: backImage.isEmpty ? null : backImage,
        frontImageFile: _pickedFrontImage,
        backImageFile: _pickedBackImage,
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
        frontImage: frontImage.isEmpty ? null : frontImage,
        backImage: backImage.isEmpty ? null : backImage,
        frontImageFile: _pickedFrontImage,
        backImageFile: _pickedBackImage,
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
          isDark ? const Color(0xFF060B16) : const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Business Card' : 'Add Business Card',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600)),
        backgroundColor: isDark ? const Color(0xFF060B16) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: isEditing
            ? [
                IconButton(
                  onPressed: isCreating ? null : _submit,
                  icon: Icon(
                    Icons.save_outlined,
                    color: isCreating
                        ? const Color(0xFF94A3B8)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Card Photos"),
                  const SizedBox(height: 4),
                  Text(
                    "Photograph the card. The front is read automatically to fill the form below.",
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? const Color(0xFF98A7C2) : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCardPhotosSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Personal Info"),
                  const SizedBox(height: 16),

                  // Profile Image Picker
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF10182B)
                                  : Colors.grey[200],
                              border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF24304B)
                                      : Colors.grey[300]!,
                                  width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _pickedImageBytes != null
                                ? Image.memory(
                                    _pickedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : _hasRemoteProfileImage
                                    ? Image.network(
                                        ImageUrl.resolve(
                                            _profileImageCtrl.text)!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.person,
                                          size: 50,
                                          color: isDark
                                              ? const Color(0xFF98A7C2)
                                              : Colors.grey,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 50,
                                        color: isDark
                                            ? const Color(0xFF98A7C2)
                                            : Colors.grey,
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildPremiumTextField(
                    controller: _nameCtrl,
                    label: "Full Name",
                    hint: "e.g. John Doe",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    controller: _positionCtrl,
                    label: "Position",
                    hint: "e.g. Software Engineer",
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Company"),
                  const SizedBox(height: 16),
                  _buildCompanySelector(),
                  if (_scannedCompanyName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.document_scanner_outlined,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF98A7C2)
                                : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Read from the card: "$_scannedCompanyName" — select or create it above.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF98A7C2)
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionTitle("Contact Details"),
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    controller: _phonesCtrl,
                    label: "Phones",
                    hint: "e.g. 998991112233, ...",
                    icon: Icons.phone_outlined,
                    validator: _validatePhones,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    controller: _emailsCtrl,
                    label: "Emails",
                    hint: "e.g. mail@example.com, ...",
                    icon: Icons.email_outlined,
                    validator: _validateEmails,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Addresses"),
                  const SizedBox(height: 16),
                  ..._buildAddressSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("More"),
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    controller: _bioCtrl,
                    label: "Bio",
                    hint: "Short description...",
                    icon: Icons.info_outline,
                    maxLines: 3,
                  ),
                  // const SizedBox(height: 16),
                  // _buildPremiumTextField(
                  //   controller: _profileImageCtrl,
                  //   label: "Profile Image URL",
                  //   hint: "https://...",
                  //   icon: Icons.image_outlined,
                  // ),
                  const SizedBox(height: 32),
                  if (!isEditing)
                    AppPrimaryButton(
                      text: 'Create Card',
                      loading: isCreating,
                      onPressed: isCreating ? null : _submit,
                      height: 50,
                      borderRadius: BorderRadius.circular(12),
                      fontSize: 16,
                    ),
                  const SizedBox(height: 24),
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

  List<Widget> _buildAddressSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final widgets = <Widget>[];

    for (var i = 0; i < _addressEntries.length; i++) {
      final entry = _addressEntries[i];
      widgets.add(Container(
        margin: EdgeInsets.only(top: i == 0 ? 0 : 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2A44) : Colors.grey[300]!,
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
                          ? const Color(0xFF98A7C2)
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

  Widget _buildCardPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildCardPhotoTile(
                side: _CardSide.front,
                label: 'Front',
                bytes: _pickedFrontBytes,
                storedPath: _frontImageCtrl.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardPhotoTile(
                side: _CardSide.back,
                label: 'Back',
                bytes: _pickedBackBytes,
                storedPath: _backImageCtrl.text,
              ),
            ),
          ],
        ),
        if (_pickedFrontImage != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isScanning ? null : _autoFillFromFrontPhoto,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high, size: 18),
              label: Text(_isScanning ? 'Reading card...' : 'Fill from front photo'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardPhotoTile({
    required _CardSide side,
    required String label,
    required Uint8List? bytes,
    required String storedPath,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storedUrl = bytes == null ? ImageUrl.resolve(storedPath) : null;
    final hasPhoto = bytes != null || storedUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _isScanning ? null : () => _pickCardPhoto(side),
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1426) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F2A44) : Colors.grey[300]!,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : storedUrl != null
                      ? Image.network(
                          storedUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _cardPhotoPlaceholder(isDark, label),
                        )
                      : _cardPhotoPlaceholder(isDark, label),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF98A7C2) : Colors.grey[600],
              ),
            ),
            const Spacer(),
            // Only a freshly picked photo can be dropped: the API keeps the
            // stored photo when no new file is sent, it cannot clear it.
            if (bytes != null)
              InkWell(
                onTap: _isScanning ? null : () => _clearCardPhoto(side),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: Colors.redAccent),
                ),
              )
            else if (hasPhoto)
              Icon(Icons.check_circle,
                  size: 14, color: Colors.green.withOpacity(0.8)),
          ],
        ),
      ],
    );
  }

  Widget _cardPhotoPlaceholder(bool isDark, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          label == 'Front'
              ? Icons.add_a_photo_outlined
              : Icons.flip_to_back_outlined,
          size: 26,
          color: isDark ? const Color(0xFF98A7C2) : Colors.grey[500],
        ),
        const SizedBox(height: 6),
        Text(
          '$label photo',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF98A7C2) : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1426) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2A44) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon,
                  color: isDark ? const Color(0xFF98A7C2) : Colors.grey[400])
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF0D1426) : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(
          color: isDark ? const Color(0xFFEAF1FF) : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCompanySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: _pickCompany,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1426) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2A44) : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.16 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF18243E) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.business,
                color:
                    isDark ? const Color(0xFF8FB6FF) : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected Company",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF98A7C2) : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedCompanyName ?? "None",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedCompanyName != null
                          ? (isDark ? const Color(0xFFEAF1FF) : Colors.black87)
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? const Color(0xFF98A7C2) : Colors.grey[400],
            ),
          ],
        ),
      ),
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

/// Which face of the physical card a photo belongs to.
enum _CardSide { front, back }
