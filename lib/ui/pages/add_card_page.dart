import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/card/card_provider.dart';
import '../../utils/app_result.dart';
import '../../network/image_url.dart';
import '../../data/vos/business_card_model.dart';
import '../../data/vos/company_model.dart';
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
  final _addressesCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _profileImageCtrl = TextEditingController();
  int? _selectedCompanyId;
  String? _selectedCompanyName;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

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
      _addressesCtrl.text = c.addresses.join(', ');
      _bioCtrl.text = c.bio ?? '';
      _profileImageCtrl.text = c.profileImage ?? '';
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _positionCtrl.dispose();
    _phonesCtrl.dispose();
    _emailsCtrl.dispose();
    _addressesCtrl.dispose();
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
    final addresses = _splitToList(_addressesCtrl.text);
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
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    controller: _addressesCtrl,
                    label: "Addresses",
                    hint: "e.g. 123 Main St, ...",
                    icon: Icons.location_on_outlined,
                  ),
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

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
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
