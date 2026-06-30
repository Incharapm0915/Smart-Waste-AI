import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted && ref.read(authProvider) != null) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
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
                // Hero branding section
                SizedBox(
                  height: size.height * 0.40,
                  child: _buildHeroBranding(),
                ),
                // White form card
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
      height: size.height * 0.45,
      decoration: const BoxDecoration(
        gradient: AppColors.deepHeroGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: -60,
            top: size.height * 0.15,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: size.height * 0.22,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
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
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [AppColors.primaryGlowShadow],
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartWaste',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'AI',
                      style: AppTypography.headlineSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(delay: 80.ms, duration: 500.ms).slideY(begin: -0.15),
            const SizedBox(height: 24),
            Text(
              'Smarter eating,\nless waste.',
              style: AppTypography.displaySmall.copyWith(
                color: Colors.white,
                height: 1.25,
              ),
            ).animate().fadeIn(delay: 180.ms, duration: 500.ms).slideX(begin: -0.08),
            const SizedBox(height: 10),
            Text(
              'AI-powered food management for a\nsustainable tomorrow.',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 260.ms, duration: 500.ms),
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
          28,
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
            const SizedBox(height: 24),
            Text('Welcome back 👋', style: AppTypography.displaySmall)
                .animate()
                .fadeIn(delay: 320.ms, duration: 400.ms)
                .slideY(begin: 0.1),
            const SizedBox(height: 6),
            Text(
              'Sign in to manage your food smarter',
              style: AppTypography.bodyMedium,
            ).animate().fadeIn(delay: 360.ms, duration: 400.ms),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email address',
                    hint: 'your@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v!.contains('@') ? null : 'Enter a valid email',
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.08),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    validator: (v) =>
                        v!.length >= 6 ? null : 'Minimum 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ).animate().fadeIn(delay: 440.ms).slideY(begin: 0.08),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ).animate().fadeIn(delay: 460.ms),
                  const SizedBox(height: 20),
                  _buildLoginButton()
                      .animate()
                      .fadeIn(delay: 480.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: 24),
                  _buildDivider().animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 20),
                  SocialAuthButton(
                    icon: 'G',
                    label: 'Continue with Google',
                    onTap: _isGoogleLoading ? () {} : _handleGoogleLogin,
                    isLoading: _isGoogleLoading,
                  ).animate().fadeIn(delay: 520.ms),
                  const SizedBox(height: 28),
                  _buildSignupLink().animate().fadeIn(delay: 540.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.15, end: 0, delay: 120.ms, duration: 550.ms,
        curve: Curves.easeOutCubic);
  }

  Widget _buildLoginButton() {
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
          onPressed: _isLoading ? null : _handleLogin,
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
              : Text('Sign In', style: AppTypography.buttonText),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: AppTypography.bodyMedium),
        GestureDetector(
          onTap: () => context.push('/signup'),
          child: Text(
            'Sign Up',
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
