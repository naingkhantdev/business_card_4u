import 'package:flutter/material.dart';
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/card/card_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import 'card_detail_page.dart';
import '../theme/wallet_tokens.dart';

class ScanPage extends ConsumerStatefulWidget {
  /// Shows the user's own QR, for when the other person should scan instead.
  /// Called after this page has closed. Omitted, the option isn't offered.
  final VoidCallback? onShowMyQr;

  const ScanPage({super.key, this.onShowMyQr});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _openCode(code);
  }

  Future<void> _openCode(String code) async {
    setState(() => _isProcessing = true);

    try {
      final card = await ref.read(cardProvider.notifier).scanQr(code);
      if (!mounted) return;

      if (card != null) {
        Navigator.pushReplacement(
          context,
          AppPageRoute(builder: (_) => CardDetailPage(card: card)),
        );
      } else {
        AppToast.show(
          context,
          AppLocalizations.of(context)!.scanPageCardNotFound,
          type: AppToastType.error,
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          AppLocalizations.of(context)!.scanPageErrorScanning,
          type: AppToastType.error,
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Reads a QR out of a saved image: a screenshot someone sent, or a code
  /// that won't focus on camera. Also the way forward when the camera is off.
  Future<void> _scanFromPhoto() async {
    if (_isProcessing) return;
    final l10n = AppLocalizations.of(context)!;
    final XFile? image;
    try {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {
      if (mounted) {
        AppToast.show(context, l10n.scanPageErrorScanning,
            type: AppToastType.error);
      }
      return;
    }
    if (image == null || !mounted) return;

    BarcodeCapture? capture;
    try {
      capture = await controller.analyzeImage(image.path);
    } catch (_) {
      capture = null;
    }
    if (!mounted) return;

    final code = capture?.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) {
      AppToast.show(context, l10n.scanPageNoQrInPhoto,
          type: AppToastType.error);
      return;
    }
    await _openCode(code);
  }

  void _showMyQr() {
    final onShowMyQr = widget.onShowMyQr;
    if (onShowMyQr == null) return;
    Navigator.pop(context);
    onShowMyQr();
  }

  /// Replaces the black preview when the camera can't run, so the page says
  /// why and still offers a way to finish the job.
  Widget _buildError(BuildContext context, MobileScannerException error) {
    final l10n = AppLocalizations.of(context)!;
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: Wallet.darkGround,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: Wallet.margin, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.08),
                  ),
                  child: Icon(
                    denied
                        ? Icons.no_photography_outlined
                        : Icons.videocam_off_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  denied
                      ? l10n.scanPageCameraDeniedTitle
                      : l10n.scanPageCameraErrorTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  denied
                      ? l10n.scanPageCameraDeniedBody
                      : l10n.scanPageCameraErrorBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Colors.white.withOpacity(.72),
                  ),
                ),
                const SizedBox(height: 24),
                // The photo route works with the camera off, so it leads.
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _scanFromPhoto,
                    style: FilledButton.styleFrom(
                      backgroundColor: Wallet.accentDark,
                      foregroundColor: Wallet.onAccentOf(true),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: Text(
                      l10n.scanPageScanFromPhoto,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await controller.stop();
                        await controller.start();
                      } catch (_) {}
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(l10n.scanPageTryAgain),
                  ),
                ),
                if (widget.onShowMyQr != null) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _showMyQr,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(l10n.scanPageShowMyQr),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A round control over the camera, readable on any background.
  Widget _roundControl({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool active = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active ? Colors.white : Colors.black.withOpacity(.45),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon,
                  size: 24, color: active ? Colors.black : Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    // In landscape the viewport is shorter than a fixed 250pt reticle plus the
    // app bar, so the frame is sized off the shorter side of the screen.
    final screen = MediaQuery.of(context).size;
    final frameSize = (screen.shortestSide * .62).clamp(160.0, 250.0);
    return Scaffold(
      backgroundColor: isDark ? Wallet.darkGround : Colors.black,
      appBar: AppBar(
        title: Text(
          l10n.scanPageTitle,
          style: TextStyle(
            color: Wallet.inkOf(isDark),
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: isDark ? Wallet.darkGround : Colors.white,
        elevation: 0,
        surfaceTintColor: isDark ? Wallet.darkGround : Colors.white,
        iconTheme: IconThemeData(color: Wallet.inkOf(isDark)),
      ),
      body: ValueListenableBuilder<MobileScannerState>(
        valueListenable: controller,
        builder: (context, state, _) {
          // The error builder covers the preview; the overlay below would
          // only sit on top of it.
          final hasError = state.error != null;
          final torch = state.torchState;
          final torchAvailable = torch != TorchState.unavailable;
          final torchOn = torch == TorchState.on;

          return Stack(
            children: [
              MobileScanner(
                controller: controller,
                onDetect: _handleBarcode,
                errorBuilder: (context, error, _) => _buildError(context, error),
              ),
              if (!hasError) ...[
                Center(
                  child: Container(
                    width: frameSize,
                    height: frameSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(Wallet.radiusCard),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.24),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                // Says what to aim at, just under the frame.
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: frameSize + 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.scanPageHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          Wallet.margin, 0, Wallet.margin, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (torchAvailable) ...[
                                _roundControl(
                                  icon: torchOn
                                      ? Icons.flashlight_on_rounded
                                      : Icons.flashlight_off_rounded,
                                  label: l10n.scanPageTorch,
                                  active: torchOn,
                                  onTap: () => controller.toggleTorch(),
                                ),
                                const SizedBox(width: 40),
                              ],
                              _roundControl(
                                icon: Icons.photo_library_outlined,
                                label: l10n.scanPageFromPhoto,
                                onTap: _scanFromPhoto,
                              ),
                            ],
                          ),
                          if (widget.onShowMyQr != null) ...[
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: _showMyQr,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black.withOpacity(.45),
                                minimumSize: const Size(0, 48),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                shape: const StadiumBorder(),
                              ),
                              icon: const Icon(Icons.qr_code_2_rounded,
                                  size: 20),
                              label: Text(
                                l10n.scanPageShowMyQr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(child: LoadingView(size: 96)),
                ),
            ],
          );
        },
      ),
    );
  }
}
