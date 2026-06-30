import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms to continue'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.authHeroDark,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _buildHeroBackground(size),
            Column(
              children: [
                SizedBox(
                  height: size.height * 0.32,
                  child: _buildHeroBranding(),
                ),
                Expanded(child: _buildFormCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBackground(Size size) {
    return Container(
      width: size.width,
      height: size.height * 0.38,
      decoration: const BoxDecoration(gradient: AppColors.deepHeroGradient),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: -50,
            top: size.height * 0.12,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBranding() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: Colors.white),
              ),
            ).animate().fadeIn(delay: 60.ms).slideY(begin: -0.1),
            const SizedBox(height: 20),
            Text(
              'Create account ✨',
              style: AppTypography.displaySmall.copyWith(color: Colors.white),
            ).animate().fadeIn(delay: 140.ms).slideX(begin: -0.08),
            const SizedBox(height: 8),
            Text(
              'Join 10,000+ people reducing food waste',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          28,
          24,
          28,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Your details', style: AppTypography.headlineMedium)
                .animate()
                .fadeIn(delay: 280.ms),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AuthTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'John Doe',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        v!.length >= 2 ? null : 'Enter your name',
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email address',
                    hint: 'your@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v!.contains('@') ? null : 'Enter a valid email',
                  ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.08),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Min 8 characters',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    validator: (v) =>
                        v!.length >= 8 ? null : 'Minimum 8 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.08),
                  const SizedBox(height: 16),
                  _buildPasswordStrength()
                      .animate()
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 18),
                  _buildTermsCheckbox()
                      .animate()
                      .fadeIn(delay: 420.ms),
                  const SizedBox(height: 24),
                  _buildSignupButton()
                      .animate()
                      .fadeIn(delay: 440.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: 20),
                  _buildLoginLink().animate().fadeIn(delay: 460.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(
        begin: 0.15,
        end: 0,
        delay: 100.ms,
        duration: 520.ms,
        curve: Curves.easeOutCubic);
  }

  Widget _buildPasswordStrength() {
    return AnimatedBuilder(
      animation: _passwordController,
      builder: (context, _) {
        final pw = _passwordController.text;
        if (pw.isEmpty) return const SizedBox.shrink();
        int str = 0;
        if (pw.length >= 8) str++;
        if (pw.contains(RegExp(r'[A-Z]'))) str++;
        if (pw.contains(RegExp(r'[0-9]'))) str++;
        if (pw.contains(RegExp(r'[!@#$%^&*]'))) str++;

        final colors = [
          AppColors.danger,
          AppColors.warning,
          AppColors.warning,
          AppColors.safe
        ];
        final labels = ['Weak', 'Fair', 'Good', 'Strong'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 5 : 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i < str
                            ? colors[str - 1]
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (str > 0)
              Text(
                'Password strength: ${labels[str - 1]}',
                style: AppTypography.caption
                    .copyWith(color: colors[str - 1]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _agreedToTerms ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _agreedToTerms ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _isLoading ? null : AppColors.primaryGradient,
          color: _isLoading ? AppColors.surfaceVariant : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading ? [] : [AppColors.primaryShadow],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSignup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : Text('Create Account', style: AppTypography.buttonText),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: AppTypography.bodyMedium),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            'Sign In',
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
