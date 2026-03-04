import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/exceptions/app_exception.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_gradients.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/core/widgets/glass_card.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';

import 'package:tour_vn/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Login Screen - First authentication touchpoint for TourVN
///
/// Provides:
/// - Google OAuth sign-in

/// - Anonymous browsing option ("Khám phá không đăng nhập")
///
/// Features:
/// - Gradient background (dark navy to indigo)
/// - Glassmorphism card for buttons
/// - Loading states during sign-in
/// - Error handling with SnackBar
/// - Navigation to Home on successful authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoginMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLoginMode) {
      ref
          .read(authNotifierProvider.notifier)
          .signInWithEmailAndPassword(email, password);
    } else {
      final displayName = _nameController.text.trim();
      ref
          .read(authNotifierProvider.notifier)
          .registerWithEmailAndPassword(email, password, displayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    // Listen for auth state changes and navigate on success
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && context.mounted) {
          if (kIsWeb) {
            context.go('/admin');
          } else {
            context.go('/');
          }
        }
      });
    });

    // Listen for errors and show SnackBar
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          if (!context.mounted) return;

          String message = 'Đã xảy ra lỗi. Vui lòng thử lại.';
          if (error is AppException) {
            message = error.message;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      );
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.loginBackground),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Logo and Branding
                      _buildLogo(),
                      const SizedBox(height: AppSpacing.xl),

                      // Welcome Text
                      Text(
                        _isLoginMode
                            ? 'Chào mừng đến TourVN'
                            : 'Tạo tài khoản TourVN',
                        style: AppTypography.headingXL.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _isLoginMode
                            ? 'Khám phá Việt Nam theo cách của bạn'
                            : 'Bắt đầu hành trình khám phá ngay hôm nay',
                        style: AppTypography.bodyMD.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(flex: 1),

                      // Sign-In Cards
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        borderRadius: 24,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Email & Password Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (!_isLoginMode) ...[
                                    TextFormField(
                                      controller: _nameController,
                                      enabled: !isLoading,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        'Tên hiển thị',
                                        Icons.person_outline,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty)
                                          return 'Vui lòng nhập tên hiển thị';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(
                                      'Email',
                                      Icons.email_outlined,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty)
                                        return 'Vui lòng nhập email';
                                      if (!value.contains('@'))
                                        return 'Email không hợp lệ';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _passwordController,
                                    enabled: !isLoading,
                                    obscureText: true,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(
                                      'Mật khẩu',
                                      Icons.lock_outline,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty)
                                        return 'Vui lòng nhập mật khẩu';
                                      if (!_isLoginMode && value.length < 6)
                                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // Submit Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _isLoginMode
                                                  ? 'Đăng nhập'
                                                  : 'Đăng ký',
                                              style: AppTypography.labelMD
                                                  .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Toggle Login/Register
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isLoginMode = !_isLoginMode;
                                        _formKey.currentState?.reset();
                                      });
                                    },
                              child: Text(
                                _isLoginMode
                                    ? 'Chưa có tài khoản? Đăng ký ngay'
                                    : 'Đã có tài khoản? Đăng nhập',
                                style: AppTypography.bodySM.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),
                            _buildDivider(),
                            const SizedBox(height: AppSpacing.sm),

                            // Google Sign-In Button
                            GoogleSignInButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      ref
                                          .read(authNotifierProvider.notifier)
                                          .signInWithGoogle();
                                    },
                              isLoading: isLoading,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Browse without sign-in option
                      _buildBrowseWithoutSignIn(context, ref, isLoading),

                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(
        alpha: 0.1,
      ), // changed withOpacity to withValues for flutter 3.27+
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      errorStyle: const TextStyle(color: AppColors.error),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 40, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              'TourVN',
              style: AppTypography.headingMD.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'hoặc',
            style: AppTypography.bodySM.copyWith(color: Colors.white54),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.white24)),
      ],
    );
  }

  Widget _buildBrowseWithoutSignIn(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
  ) {
    return TextButton(
      onPressed: isLoading
          ? null
          : () async {
              try {
                await ref.read(authRepositoryProvider).signInAnonymously();
                if (context.mounted) {
                  if (kIsWeb) {
                    context.go('/admin');
                  } else {
                    context.go('/');
                  }
                }
              } catch (e) {
                if (!context.mounted) return;

                String message = 'Không thể tiếp tục. Vui lòng thử lại.';
                if (e is AppException) {
                  message = e.message;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      child: Text(
        'Khám phá không đăng nhập',
        style: AppTypography.bodyMD.copyWith(
          color: Colors.white70,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white70,
        ),
      ),
    );
  }
}
