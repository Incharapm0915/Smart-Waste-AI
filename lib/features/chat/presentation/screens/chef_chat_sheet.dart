import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../features/inventory/domain/providers/inventory_provider.dart';
import '../../data/models/chat_message_model.dart';
import '../../domain/providers/chef_provider.dart';

// Chef brand colours
const _chefOrange = Color(0xFFFF6B35);
const _chefAmber = Color(0xFFFF9500);
const _chefGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_chefOrange, _chefAmber],
);
const _chefSurface = Color(0xFFFFF5F0);
const _chefBorder = Color(0xFFFFD4C0);

void showChefChatSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => const _ChefSheetWrapper(),
  );
}

class _ChefSheetWrapper extends StatelessWidget {
  const _ChefSheetWrapper();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) =>
          _ChefContent(scrollController: scrollController),
    );
  }
}

class _ChefContent extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _ChefContent({required this.scrollController});

  @override
  ConsumerState<_ChefContent> createState() => _ChefContentState();
}

class _ChefContentState extends ConsumerState<_ChefContent> {
  final _inputController = TextEditingController();
  final _listScrollController = ScrollController();
  bool _isSending = false;

  static const _suggestions = [
    '📅 Plan my meals for the week',
    '🍝 Recipe for pasta carbonara',
    '🍛 How to make butter chicken',
    '🔄 What can substitute eggs?',
    '🍳 Recipe for fried rice',
    '👨‍🍳 Give me chef tips',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  List<String> _getInventoryNames() {
    final inventoryAsync = ref.read(inventoryProvider);
    return inventoryAsync.value?.map((i) => i.name).toList() ?? [];
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    _inputController.clear();
    setState(() => _isSending = true);
    HapticFeedback.lightImpact();
    await ref
        .read(chefProvider.notifier)
        .sendMessage(text, inventoryItems: _getInventoryNames());
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(
          _listScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chefProvider);
    final hasLoading = messages.any((m) => m.isLoading);
    if (!hasLoading && _isSending) _scrollToBottom();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(context),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: messages.length <= 1
                    ? _buildWelcomeState(messages.first)
                    : _buildMessageList(messages),
              ),
              _buildInputRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: _chefGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _chefOrange.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('👨‍🍳', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Chef', style: AppTypography.headlineSmall),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _chefOrange,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .fade(
                          begin: 1,
                          end: 0.2,
                          duration: 900.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(width: 5),
                    Text(
                      'Culinary Expert · Powered by AI',
                      style: AppTypography.bodySmall.copyWith(
                        color: _chefOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(chefProvider.notifier).clearChat();
            },
            icon: const Icon(Icons.refresh_rounded,
                size: 20, color: AppColors.textTertiary),
            tooltip: 'Clear chat',
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded,
                size: 20, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState(ChatMessage welcome) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature badges
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureBadge(icon: '🍽️', label: 'Any Recipe'),
              _FeatureBadge(icon: '📅', label: 'Meal Planning'),
              _FeatureBadge(icon: '🔄', label: 'Substitutions'),
              _FeatureBadge(icon: '💡', label: 'Chef Tips'),
            ],
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 350.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),
          const SizedBox(height: 20),
          _ChefBubble(message: welcome, index: 0),
          const SizedBox(height: 20),
          Text('Try asking…', style: AppTypography.labelMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.asMap().entries.map((e) {
              return _SuggestionChip(
                label: e.value,
                delay: e.key * 60,
                onTap: () => _send(e.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _listScrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      itemCount: messages.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ChefBubble(message: messages[i], index: i),
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ask for a recipe, meal plan, substitution…',
                  hintStyle: AppTypography.bodySmall,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: _send,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _send(_inputController.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _isSending
                    ? const LinearGradient(colors: [
                        AppColors.textTertiary,
                        AppColors.textTertiary,
                      ])
                    : _chefGradient,
                shape: BoxShape.circle,
                boxShadow: _isSending
                    ? []
                    : [
                        BoxShadow(
                          color: _chefOrange.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _isSending
                  ? const _TypingIndicator(color: Colors.white, size: 6)
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature badge ────────────────────────────────────────────────────────────

class _FeatureBadge extends StatelessWidget {
  final String icon;
  final String label;
  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _chefSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _chefBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: _chefOrange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bubble ───────────────────────────────────────────────────────────────────

class _ChefBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;
  const _ChefBubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) return _buildTypingBubble();
    return message.isUser ? _buildUserBubble() : _buildBotBubble();
  }

  Widget _buildUserBubble() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: _chefGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: _chefOrange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: _chefGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, color: Colors.white, size: 16),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 50.ms, duration: 300.ms)
        .slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Widget _buildBotBubble() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _chefSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _chefBorder),
          ),
          child: const Center(
            child: Text('👨‍🍳', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.border),
              boxShadow: [AppColors.softShadow],
            ),
            child: Text(
              message.text,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary, height: 1.55),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 50.ms, duration: 300.ms)
        .slideX(begin: -0.1, curve: Curves.easeOutCubic);
  }

  Widget _buildTypingBubble() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _chefSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _chefBorder),
          ),
          child: const Center(
            child: Text('👨‍🍳', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: const _TypingIndicator(
              color: AppColors.textTertiary, size: 8),
        ),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }
}

// ─── Typing dots ──────────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final Color color;
  final double size;
  const _TypingIndicator({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? size * 0.6 : 0),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat())
              .moveY(
                begin: 0,
                end: -size * 0.8,
                delay: Duration(milliseconds: i * 150),
                duration: 450.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .moveY(
                begin: -size * 0.8,
                end: 0,
                duration: 450.ms,
                curve: Curves.easeInOut,
              ),
        );
      }),
    );
  }
}

// ─── Suggestion chip ─────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final int delay;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _chefBorder),
          boxShadow: [AppColors.softShadow],
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay + 200),
          duration: 300.ms,
        )
        .slideY(begin: 0.15, curve: Curves.easeOutCubic);
  }
}
