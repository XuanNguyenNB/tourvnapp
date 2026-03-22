import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/exceptions/app_exception.dart';
import 'package:tour_vn/core/providers/admin_claim_provider.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';

/// Admin Login Screen — Web-only login page for administrators.
///
/// Design:
/// - Split-screen layout: branding panel (left) + login form (right)
/// - Responsive: hides branding panel on narrow screens (<900px)
/// - Only email/password login — no Google, no registration, no anonymous
/// - Validates admin claim after successful authentication
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    ref
        .read(authNotifierProvider.notifier)
        .signInWithEmailAndPassword(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showBranding = screenWidth >= 900;

    // Navigate to /admin after successful authentication
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && !user.isAnonymous && context.mounted) {
          // Check admin claim
          ref.invalidate(adminClaimProvider);
          final adminClaim = ref.read(adminClaimProvider);
          adminClaim.whenData((isAdmin) {
            if (isAdmin && context.mounted) {
              context.go('/admin');
            } else if (!isAdmin && context.mounted) {
              _showError(
                'Tài khoản này không có quyền quản trị viên.',
              );
              // Sign out non-admin user
              ref.read(authNotifierProvider.notifier).signOut();
            }
          });
        }
      });
    });

    // Listen for auth errors
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          if (!context.mounted) return;

          String message = 'Đã xảy ra lỗi. Vui lòng thử lại.';
          if (error is AppException) {
            message = error.message;
          }
          _showError(message);
        },
      );
    });

    return Scaffold(
      body: Row(
        children: [
          // ─────── LEFT: Branding Panel ───────
          if (showBranding)
            Expanded(
              flex: 3,
              child: _BrandingPanel(),
            ),

          // ─────── RIGHT: Login Form Panel ───────
          Expanded(
            flex: 2,
            child: _LoginFormPanel(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              isLoading: isLoading,
              onToggleObscure: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              onSubmit: _submitForm,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!context.mounted) return;
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
}

// ═══════════════════════════════════════════════════════════════
// Branding Panel (Left side)
// ═══════════════════════════════════════════════════════════════

class _BrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Dark navy
            Color(0xFF1E1B4B), // Dark purple
            Color(0xFF312E81), // Indigo
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPatternPainter()),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl * 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.explore,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    'TourVN',
                    style: AppTypography.headingXL.copyWith(
                      color: Colors.white,
                      fontSize: 36,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Tagline
                  Text(
                    'Hệ thống quản lý du lịch Việt Nam',
                    style: AppTypography.bodyMD.copyWith(
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl * 2),

                  // Feature highlights
                  _FeatureItem(
                    icon: Icons.dashboard_outlined,
                    text: 'Quản lý điểm đến & địa điểm',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FeatureItem(
                    icon: Icons.auto_awesome_outlined,
                    text: 'Tạo nội dung AI thông minh',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FeatureItem(
                    icon: Icons.reviews_outlined,
                    text: 'Kiểm duyệt đánh giá & bình luận',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          text,
          style: AppTypography.bodySM.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Login Form Panel (Right side)
// ═══════════════════════════════════════════════════════════════

class _LoginFormPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _LoginFormPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Admin icon
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  'TourVN Admin',
                  style: AppTypography.headingXL.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Subtitle
                Text(
                  'Bảng điều khiển quản trị',
                  style: AppTypography.bodyMD.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // ─── Form ───
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email label
                      Text(
                        'Email',
                        style: AppTypography.labelMD.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Email field
                      TextFormField(
                        controller: emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: _buildInputDecoration(
                          hint: 'admin@tourvn.com',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!value.contains('@')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Password label
                      Text(
                        'Mật khẩu',
                        style: AppTypography.labelMD.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Password field
                      TextFormField(
                        controller: passwordController,
                        enabled: !isLoading,
                        obscureText: obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: _buildInputDecoration(
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: onToggleObscure,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => onSubmit(),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Submit button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Đăng nhập',
                                  style: AppTypography.labelMD.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Footer
                Text(
                  'Chỉ dành cho quản trị viên',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMD.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.textSecondary,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Grid pattern painter for branding panel background
// ═══════════════════════════════════════════════════════════════

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
