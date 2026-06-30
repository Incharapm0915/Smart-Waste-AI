import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/models/inventory_item_model.dart';
import '../../data/services/barcode_lookup_service.dart';
import '../../domain/providers/inventory_provider.dart';

class AddItemSheet extends ConsumerStatefulWidget {
  final ProductInfo? prefill;
  final String? barcode;

  const AddItemSheet({super.key, this.prefill, this.barcode});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  final _notesCtrl = TextEditingController();

  late String _category;
  String _unit = 'pcs';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  static const _categories = [
    'Dairy', 'Meat', 'Vegetables', 'Fruits', 'Grains',
    'Snacks', 'Beverages', 'Condiments', 'Frozen', 'Bakery',
    'Seafood', 'Eggs', 'Other',
  ];
  static const _units = ['pcs', 'kg', 'g', 'L', 'ml', 'pack', 'dozen'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prefill?.name ?? '');
    _qtyCtrl = TextEditingController(text: '1');
    _category = widget.prefill?.category ?? 'Other';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final item = InventoryItemModel(
      id: const Uuid().v4(),
      userId: uid,
      name: name,
      category: _category,
      emoji: InventoryItemModel.categoryEmoji(_category),
      expiryDate: _expiryDate,
      addedDate: DateTime.now(),
      quantity: double.tryParse(_qtyCtrl.text) ?? 1.0,
      unit: _unit,
      barcode: widget.barcode,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    await ref.read(inventoryNotifierProvider.notifier).addItem(item);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [AppColors.strongShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Item', style: AppTypography.headlineMedium),
                      if (widget.prefill?.brand != null)
                        Text(
                          widget.prefill!.brand!,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                  if (widget.barcode != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            widget.barcode!.length > 8
                                ? '${widget.barcode!.substring(0, 8)}…'
                                : widget.barcode!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(color: AppColors.border.withValues(alpha: 0.6)),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Item Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameCtrl,
                      hint: 'e.g. Whole Milk, Chicken Breast',
                      icon: Icons.label_outline_rounded,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Category'),
                    const SizedBox(height: 10),
                    _buildCategoryPicker(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Quantity'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _qtyCtrl,
                                hint: '1',
                                icon: Icons.numbers_rounded,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d*')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Unit'),
                              const SizedBox(height: 8),
                              _buildUnitDropdown(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Expiry Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _daysLabel(),
                              style: AppTypography.caption.copyWith(
                                color: _daysUntil() <= 3
                                    ? AppColors.warning
                                    : AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Notes (optional)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _notesCtrl,
                      hint: 'e.g. Opened, store in fridge',
                      icon: Icons.sticky_note_2_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _isSaving ? null : _save,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: _isSaving ? null : AppColors.primaryGradient,
                          color: _isSaving ? AppColors.surfaceVariant : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isSaving ? [] : [AppColors.primaryShadow],
                        ),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add to Inventory',
                                      style: AppTypography.labelLarge
                                          .copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final isSelected = _category == cat;
        return GestureDetector(
          onTap: () => setState(() => _category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.border,
              ),
              boxShadow: isSelected ? [AppColors.primaryShadow] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  InventoryItemModel.categoryEmoji(cat),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 5),
                Text(
                  cat,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _unit,
          isExpanded: true,
          style: AppTypography.bodyMedium,
          items: _units
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _unit = v);
          },
        ),
      ),
    );
  }

  int _daysUntil() => _expiryDate.difference(DateTime.now()).inDays;

  String _daysLabel() {
    final d = _daysUntil();
    if (d == 0) return 'Today';
    if (d == 1) return 'Tomorrow';
    return 'in $d days';
  }
}
