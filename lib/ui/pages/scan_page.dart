import 'package:flutter/material.dart';
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/card/card_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import 'card_detail_page.dart';
import '../theme/wallet_tokens.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

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

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In landscape the viewport is shorter than a fixed 250pt reticle plus the
    // app bar, so the frame is sized off the shorter side of the screen.
    final screen = MediaQuery.of(context).size;
    final frameSize = (screen.shortestSide * .62).clamp(160.0, 250.0);
    return Scaffold(
      backgroundColor: isDark ? Wallet.darkGround : Colors.black,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.scanPageTitle,
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
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
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
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: LoadingView(size: 96)),
            ),
        ],
      ),
    );
  }
}
