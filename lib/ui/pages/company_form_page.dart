import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/company/company_provider.dart';
import '../../utils/image_upload.dart';
import '../widgets/company_logo.dart';
import '../widgets/image_source_sheet.dart';
import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../../data/vos/company_model.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import '../theme/wallet_tokens.dart';

class CompanyFormPage extends ConsumerStatefulWidget {
  final CompanyModel? company;
  const CompanyFormPage({super.key, this.company});

  @override
  ConsumerState<CompanyFormPage> createState() => _CompanyFormPageState();
}

class _CompanyFormPageState extends ConsumerState<CompanyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _businessTypeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // A newly picked logo, uploaded on save. _removeLogo is set when the user
  // clears an existing logo, so an untouched edit keeps it server-side.
  XFile? _logoFile;
  Uint8List? _logoBytes;
  bool _removeLogo = false;

  String? get _existingLogo => _removeLogo ? null : widget.company?.logo;
  bool get _hasLogo => _logoBytes != null || _existingLogo != null;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    if (c != null) {
      _nameCtrl.text = c.name;
      _industryCtrl.text = c.industry ?? '';
      _businessTypeCtrl.text = c.businessType ?? '';
      _descriptionCtrl.text = c.description ?? '';
      _addressCtrl.text = c.address ?? '';
      _websiteCtrl.text = c.website ?? '';
      _phoneCtrl.text = c.phone ?? '';
      _emailCtrl.text = c.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _businessTypeCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(companyProvider.notifier);
    
    // Construct payload with required fields always included
    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'industry': _industryCtrl.text.trim(),
      'business_type': _businessTypeCtrl.text.trim(),
    };

    if (_descriptionCtrl.text.trim().isNotEmpty) {
      payload['description'] = _descriptionCtrl.text.trim();
    }
    if (_addressCtrl.text.trim().isNotEmpty) {
      payload['address'] = _addressCtrl.text.trim();
    }
    if (_websiteCtrl.text.trim().isNotEmpty) {
      payload['website'] = _websiteCtrl.text.trim();
    }
    if (_phoneCtrl.text.trim().isNotEmpty) {
      payload['phone'] = _phoneCtrl.text.trim();
    }
    if (_emailCtrl.text.trim().isNotEmpty) {
      payload['email'] = _emailCtrl.text.trim();
    }

    final result = widget.company == null
        ? await notifier.createCompany(payload, logoFile: _logoFile)
        : await notifier.updateCompany(widget.company!.id, payload,
            logoFile: _logoFile, removeLogo: _removeLogo);

    if (!mounted) return;
    if (result.isSuccess) {
      final companies =
          ref.read(companyProvider).valueOrNull?.companies ?? [];
      CompanyModel? saved;
      if (widget.company != null) {
        saved = companies.cast<CompanyModel?>().firstWhere(
              (c) => c?.id == widget.company!.id,
              orElse: () => widget.company,
            );
      } else if (companies.isNotEmpty) {
        saved = companies.first;
      }
      if (saved != null) {
        Navigator.of(context).pop(saved);
      } else {
        Navigator.of(context).pop();
      }
    } else {
      final errorMsg = result.message ??
          ref.read(companyProvider).valueOrNull?.errorMessage ??
          AppLocalizations.of(context)!.companyFormSaveFailed;
      AppToast.show(
        context,
        errorMsg,
        type: AppToastType.error,
      );
    }
  }

  Future<void> _pickLogo() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showImageSourceSheet(
      context,
      title: l10n.companyFormLogoTitle,
      subtitle: l10n.companyFormLogoSheetSubtitle,
    );
    if (source == null || !mounted) return;

    final XFile? picked;
    try {
      picked = await pickImageForUpload(source, UploadImageKind.avatar);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        l10n.setupProfileImageSourceError(
          source == ImageSource.camera
              ? l10n.setupProfileSourceCamera
              : l10n.setupProfileSourceGallery,
        ),
        type: AppToastType.error,
      );
      return;
    }
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _logoFile = picked;
      _logoBytes = bytes;
      _removeLogo = false;
    });
  }

  void _clearLogo() {
    setState(() {
      _logoFile = null;
      _logoBytes = null;
      // Only an already-saved logo needs deleting on the server.
      _removeLogo = widget.company?.logo != null;
    });
  }

  /// Logo first: it's the one thing on this form people recognise a company
  /// by, and a live preview (the letter until a logo is picked) shows how it
  /// will appear on cards before anything is saved.
  Widget _buildLogoPicker(AppLocalizations l10n, bool isDark) {
    final accent = Wallet.accentOf(isDark);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Wallet.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Wallet.darkLine : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CompanyLogo(
                  name: _nameCtrl.text,
                  logo: _existingLogo,
                  bytes: _logoBytes,
                  size: 72,
                  isDark: isDark,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Wallet.darkSurface : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _hasLogo ? Icons.edit_rounded : Icons.add_a_photo_rounded,
                      size: 13,
                      color: Wallet.onAccentOf(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.companyFormLogoTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Wallet.darkInk : Wallet.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.companyFormLogoHelp,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark ? Wallet.darkMuted : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: FilledButton.tonalIcon(
                        onPressed: _pickLogo,
                        icon: Icon(
                          _hasLogo
                              ? Icons.swap_horiz_rounded
                              : Icons.add_photo_alternate_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _hasLogo
                              ? l10n.companyFormChangeLogo
                              : l10n.companyFormAddLogo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: accent,
                          backgroundColor: accent.withOpacity(.12),
                        ),
                      ),
                    ),
                    // An icon, not a text button: "Change logo" + "Remove"
                    // didn't fit on one line and Remove wrapped below.
                    if (_hasLogo) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: _clearLogo,
                        tooltip: l10n.companyFormRemoveLogo,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Colors.redAccent,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(.1),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Wallet.accentLight, size: 22),
      labelStyle: TextStyle(
        color: isDark ? Wallet.darkMuted : Colors.black54,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Wallet.darkLine : Colors.grey.withOpacity(0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      filled: true,
      fillColor: isDark ? Wallet.darkSurface : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(companyProvider).valueOrNull?.isSaving ?? false;
    final isEdit = widget.company != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: isDark ? Wallet.darkGround : AppColors.surface,
      appBar: AppBar(
        backgroundColor: isDark ? Wallet.darkGround : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEdit ? l10n.companyFormEditTitle : l10n.companyFormNewTitle,
          style: TextStyle(
            color: isDark ? Colors.white : Wallet.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      Responsive.isDesktop(context) ? 640 : double.infinity,
                ),
                child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.companyFormProfileTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Wallet.darkInk : Wallet.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.companyFormProfileSubtitle,
                    style: TextStyle(
                      color: isDark ? Wallet.darkMuted : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLogoPicker(l10n, isDark),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameCtrl,
                    // Keeps the logo preview's fallback letter in step.
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration(l10n.companyFormNameLabel, Icons.business_rounded),
                    validator: (v) => v == null || v.trim().isEmpty ? l10n.companyFormNameRequired : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _industryCtrl,
                          decoration: _inputDecoration(l10n.companyFormIndustryLabel, Icons.category_rounded),
                          validator: (v) => v == null || v.trim().isEmpty ? l10n.companyFormFieldRequired : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _businessTypeCtrl,
                          decoration: _inputDecoration(l10n.companyFormTypeLabel, Icons.work_outline_rounded),
                          validator: (v) => v == null || v.trim().isEmpty ? l10n.companyFormFieldRequired : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: _inputDecoration(l10n.companyFormDescriptionLabel, Icons.description_outlined),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.companyFormContactInfo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Wallet.darkInk : Wallet.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: _inputDecoration(l10n.companyFormAddressLabel, Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteCtrl,
                    decoration: _inputDecoration(l10n.companyFormWebsiteLabel, Icons.language_rounded),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          decoration: _inputDecoration(l10n.companyFormPhoneLabel, Icons.phone_android_rounded),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _emailCtrl,
                          decoration: _inputDecoration(l10n.companyFormEmailLabel, Icons.email_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  AppPrimaryButton(
                    text: isEdit ? l10n.companyFormUpdateButton : l10n.companyFormCreateButton,
                    loading: saving,
                    onPressed: saving ? null : _save,
                    height: 56,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
              ),
            ),
          ),
          if (saving)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: LoadingView(size: 96)),
            ),
        ],
      ),
    );
  }
}
