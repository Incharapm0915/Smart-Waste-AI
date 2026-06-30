import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/services/barcode_lookup_service.dart';
import '../widgets/add_item_sheet.dart';

enum _ScanState { scanning, loading, notFound }

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  _ScanState _state = _ScanState.scanning;
  late AnimationController _lineAnim;
  bool _torchOn = false;
  bool _processed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _lineAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lineAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processed) return;
    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;
    if (code == null) return;

    _processed = true;
    await _controller.stop();
    setState(() => _state = _ScanState.loading);

    final product = await BarcodeLookupService.lookup(code);

    if (!mounted) return;

    if (product == null) {
      setState(() => _state = _ScanState.notFound);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }

    _showAddSheet(product, code);
  }

  void _showAddSheet(ProductInfo? product, String barcode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemSheet(prefill: product, barcode: barcode),
    ).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
            _buildOverlay(),
            _buildTopBar(),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            Text(
              'Scan Barcode',
              style: AppTypography.headlineSmall.copyWith(color: Colors.white),
            ),
            GestureDetector(
              onTap: () async {
                await _controller.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _torchOn
                      ? AppColors.primary.withValues(alpha: 0.8)
                      : Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Icon(
                  _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      const frameSize = 260.0;
      final centerX = constraints.maxWidth / 2;
      final centerY = constraints.maxHeight / 2;
      final left = centerX - frameSize / 2;
      final top = centerY - frameSize / 2;

      return Stack(
        children: [
          // Dark overlay with hole
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.transparent,
              BlendMode.clear,
            ),
            child: Stack(
              children: [
                Container(color: Colors.black.withValues(alpha: 0.62)),
                Positioned(
                  left: left,
                  top: top,
                  child: Container(
                    width: frameSize,
                    height: frameSize,
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          // Custom painted frame
          CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _FramePainter(
              left: left,
              top: top,
              size: frameSize,
              color: _state == _ScanState.loading
                  ? AppColors.warning
                  : AppColors.primary,
            ),
          ),
          // Scan line
          if (_state == _ScanState.scanning)
            Positioned(
              left: left + 8,
              top: top,
              child: AnimatedBuilder(
                animation: _lineAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _lineAnim.value * (frameSize - 4)),
                  child: Container(
                    width: frameSize - 16,
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: const [
                          Colors.transparent,
                          AppColors.primary,
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).padding.bottom + 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_state == _ScanState.scanning) ...[
              const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white54, size: 28),
              const SizedBox(height: 10),
              Text(
                'Point camera at a barcode',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Works with EAN, UPC, QR codes',
                style: AppTypography.bodySmall.copyWith(color: Colors.white38),
              ),
            ] else if (_state == _ScanState.loading) ...[
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Looking up product...',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded,
                    color: AppColors.warning, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                'Product not found',
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'You can still add it manually',
                style: AppTypography.bodySmall.copyWith(color: Colors.white54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final double left;
  final double top;
  final double size;
  final Color color;

  _FramePainter({
    required this.left,
    required this.top,
    required this.size,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 28.0;

    // Top-left
    canvas.drawLine(Offset(left, top + corner), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + corner, top), paint);
    // Top-right
    canvas.drawLine(
        Offset(left + size - corner, top), Offset(left + size, top), paint);
    canvas.drawLine(
        Offset(left + size, top), Offset(left + size, top + corner), paint);
    // Bottom-left
    canvas.drawLine(
        Offset(left, top + size - corner), Offset(left, top + size), paint);
    canvas.drawLine(
        Offset(left, top + size), Offset(left + corner, top + size), paint);
    // Bottom-right
    canvas.drawLine(Offset(left + size - corner, top + size),
        Offset(left + size, top + size), paint);
    canvas.drawLine(Offset(left + size, top + size - corner),
        Offset(left + size, top + size), paint);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.color != color;
}
