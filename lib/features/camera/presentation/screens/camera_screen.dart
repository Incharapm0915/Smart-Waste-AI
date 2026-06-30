import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../features/inventory/domain/providers/inventory_provider.dart';
import '../../domain/providers/camera_provider.dart';
import '../widgets/detected_item_card.dart';
import '../widgets/scan_overlay.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isProcessing = false;
  List<DetectedItem> _detectedItems = [];
  String _processingStep = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _detectedItems = [];
    });
    await _processImage(File(picked.path));
  }

  Future<void> _processImage(File image) async {
    setState(() {
      _isProcessing = true;
      _processingStep = 'Analyzing image...';
    });
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _processingStep = 'Detecting items...');
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _processingStep = 'Reading expiry dates...');
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _processingStep = 'Classifying food types...');
      final results =
          await ref.read(cameraProvider.notifier).processImage(image);
      setState(() {
        _detectedItems = results;
        _isProcessing = false;
        _processingStep = '';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingStep = '';
      });
      if (mounted) {
        _showError('Processing failed: ${e.toString()}');
      }
    }
  }

  Future<void> _saveAllItems() async {
    final notifier = ref.read(inventoryNotifierProvider.notifier);
    int saved = 0;
    for (final item in _detectedItems.where((i) => i.isSelected)) {
      await notifier.addItem(item.toInventoryItem());
      saved++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$saved item${saved != 1 ? 's' : ''} added to inventory'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.go('/inventory');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildScanZone(),
                    const SizedBox(height: 24),
                    if (_isProcessing) _buildProcessingIndicator(),
                    if (!_isProcessing &&
                        _detectedItems.isEmpty &&
                        _selectedImage == null)
                      _buildScanOptions(),
                    if (!_isProcessing && _detectedItems.isNotEmpty)
                      _buildDetectedResults(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppColors.border,
      leading: GestureDetector(
        onTap: () => context.go('/home'),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [AppColors.softShadow],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: AppColors.textPrimary),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text('Scan Food', style: AppTypography.headlineMedium),
        ],
      ),
      actions: [
        if (_detectedItems.isNotEmpty)
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedImage = null;
                _detectedItems = [];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Retake',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildScanZone() {
    return GestureDetector(
      onTap: _selectedImage == null
          ? () => _pickImage(ImageSource.camera)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        height: _selectedImage != null ? 290 : 230,
        decoration: BoxDecoration(
          color: _selectedImage != null
              ? Colors.black
              : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: _selectedImage != null
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.28),
            width: 1.5,
          ),
          boxShadow: _selectedImage != null ? [] : [AppColors.softShadow],
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImage!, fit: BoxFit.cover),
                    if (_isProcessing) const ScanOverlay(),
                    if (!_isProcessing && _detectedItems.isNotEmpty)
                      _buildDetectionBadge(),
                  ],
                ),
              )
            : _buildScanPrompt(),
      ),
    );
  }

  Widget _buildScanPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, child) => Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.07),
            child: child,
          ),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [AppColors.primaryGlowShadow],
            ),
            child: const Icon(Icons.camera_alt_rounded,
                size: 38, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        Text('Tap to scan groceries', style: AppTypography.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'AI detects items & reads expiry dates',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetectionBadge() {
    return Positioned(
      top: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AppColors.primaryShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              '${_detectedItems.length} found',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.3);
  }

  Widget _buildProcessingIndicator() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('AI Processing', style: AppTypography.headlineSmall),
          const SizedBox(height: 6),
          Text(
            _processingStep,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          _buildProcessingSteps(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08);
  }

  Widget _buildProcessingSteps() {
    final steps = [
      ('Object Detection', Icons.image_search_rounded),
      ('OCR Expiry Scan', Icons.text_fields_rounded),
      ('Category Classification', Icons.category_rounded),
    ];
    return Column(
      children: steps.map((step) {
        final isActive = _processingStep
            .toLowerCase()
            .contains(step.$1.toLowerCase().split(' ').first.toLowerCase());
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isActive
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      )
                    : Icon(step.$2,
                        size: 18, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 10),
              Text(
                step.$1,
                style: AppTypography.bodySmall.copyWith(
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScanOptions() {
    return Column(
      children: [
        _buildOptionButton(
          icon: Icons.camera_alt_rounded,
          label: 'Take Photo',
          sublabel: 'Use camera to scan items',
          color: AppColors.primary,
          onTap: () => _pickImage(ImageSource.camera),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.06),
        const SizedBox(height: 12),
        _buildOptionButton(
          icon: Icons.photo_library_rounded,
          label: 'Choose from Gallery',
          sublabel: 'Select an existing photo',
          color: AppColors.warning,
          onTap: () => _pickImage(ImageSource.gallery),
        ).animate().fadeIn(delay: 180.ms).slideX(begin: 0.06),
        const SizedBox(height: 20),
        _buildTipBanner()
            .animate()
            .fadeIn(delay: 260.ms),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [AppColors.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.headlineSmall),
                  const SizedBox(height: 3),
                  Text(
                    sublabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                color: AppColors.primary, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: Point camera at the expiry label for best OCR accuracy',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedResults() {
    final selectedCount = _detectedItems.where((i) => i.isSelected).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('Detected Items', style: AppTypography.headlineMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18)),
              ),
              child: Text(
                '$selectedCount selected',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._detectedItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DetectedItemCard(
              item: item,
              onToggle: () {
                setState(() {
                  _detectedItems[index] =
                      item.copyWith(isSelected: !item.isSelected);
                });
              },
              onExpiryChanged: (date) {
                setState(() {
                  _detectedItems[index] = item.copyWith(expiryDate: date);
                });
              },
            ),
          ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.06);
        }),
        const SizedBox(height: 24),
        if (selectedCount > 0)
          GestureDetector(
            onTap: _saveAllItems,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [AppColors.primaryShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Add $selectedCount item${selectedCount != 1 ? 's' : ''} to Inventory',
                    style: AppTypography.buttonText,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
      ],
    );
  }
}
