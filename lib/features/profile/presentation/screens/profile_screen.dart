import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/auth/presentation/providers/auth_provider.dart';
import 'package:tour_vn/features/profile/presentation/providers/profile_providers.dart';
import 'package:tour_vn/features/profile/presentation/widgets/profile_settings_section.dart';
import 'package:tour_vn/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:tour_vn/features/profile/presentation/widgets/profile_stats_shimmer.dart';
import 'package:tour_vn/features/profile/presentation/widgets/recent_trips_section.dart';
import 'package:tour_vn/features/trip/domain/services/trip_save_service.dart';
import 'package:tour_vn/features/profile/domain/entities/user_stats.dart';

/// Profile screen - User profile with stats, trips, and sign-out
///
/// Story 2.7: Enhanced profile with stats and recent trips
/// Story 2.6: Sign-out functionality preserved
///
/// Features:
/// - User avatar, name, email
/// - Stats row (trips, saves, reviews)
/// - Recent trips carousel
/// - Settings section
/// - Sign-out for authenticated users
/// - Sign-in prompt for anonymous users
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAnonymous = ref.watch(isAnonymousProvider);
    final authState = ref.watch(authNotifierProvider);

    // Listen for auth state changes to navigate after sign-out
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user == null && context.mounted) {
          context.go('/login');
        }
      });
    });

    // Listen for auth errors to show SnackBar
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.hasError && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ'), centerTitle: true),
      body: SafeArea(
        child: isAnonymous
            ? _buildAnonymousContent(context, ref, authState.isLoading)
            : _buildAuthenticatedContent(
                context,
                ref,
                user,
                authState.isLoading,
              ),
      ),
    );
  }

  /// Authenticated user content with stats and trips
  Widget _buildAuthenticatedContent(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // User info
          _UserInfoSection(user: user),
          const SizedBox(height: AppSpacing.lg),
          // Stats row with shimmer loading
          _StatsSection(),
          const SizedBox(height: AppSpacing.xl),
          // Recent trips
          const RecentTripsSection(),
          const SizedBox(height: AppSpacing.xl),
          // Settings
          const ProfileSettingsSection(),
          const SizedBox(height: AppSpacing.xl),
          // Sign out button
          _SignOutButton(
            isLoading: isLoading,
            onPressed: () => _showSignOutConfirmation(context, ref),
          ),
          const SizedBox(height: 120), // Tránh đè với bottom nav bar
        ],
      ),
    );
  }

  /// Anonymous user content with sign-in prompt
  Widget _buildAnonymousContent(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const _AnonymousUserSection(),
          const Spacer(),
          _SignInButton(onPressed: () => context.push('/login')),
          const SizedBox(height: 120), // Tránh đè với bottom nav bar
        ],
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Hủy',
              style: AppTypography.labelMD.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleSignOut(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Đăng xuất',
              style: AppTypography.labelMD.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    ref.read(pendingTripProvider.notifier).clear();
    await ref.read(authNotifierProvider.notifier).signOut();
  }
}

/// User info section with avatar, name, email
class _UserInfoSection extends StatelessWidget {
  final dynamic user;

  const _UserInfoSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final String initial = user.displayName?.isNotEmpty == true
        ? user.displayName![0].toUpperCase()
        : 'U';

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  initial,
                  style: AppTypography.headingXL.copyWith(
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          user.displayName ?? 'Người dùng',
          style: AppTypography.headingLG,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (user.email != null)
          Text(
            user.email!,
            style: AppTypography.bodySM.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

/// Stats section with async loading
class _StatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return statsAsync.when(
      data: (stats) => ProfileStatsRow(stats: stats),
      loading: () => const ProfileStatsShimmer(),
      error: (e, st) => ProfileStatsRow(
        stats: const UserStats(tripCount: 0, savesCount: 0, reviewsCount: 0),
      ),
    );
  }
}

/// Anonymous user section
class _AnonymousUserSection extends StatelessWidget {
  const _AnonymousUserSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.border,
          child: const Icon(
            Icons.person_outline,
            size: 48,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Khách', style: AppTypography.headingLG),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Đăng nhập để lưu chuyến đi của bạn',
          style: AppTypography.bodySM.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Benefits list for AC #4
        _BenefitsList(),
      ],
    );
  }
}

/// Benefits list for anonymous users (Task 3.2)
class _BenefitsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _BenefitItem(icon: Icons.save_alt, text: 'Lưu chuyến đi của bạn'),
          const SizedBox(height: AppSpacing.sm),
          _BenefitItem(icon: Icons.sync, text: 'Đồng bộ giữa các thiết bị'),
          const SizedBox(height: AppSpacing.sm),
          _BenefitItem(icon: Icons.share, text: 'Chia sẻ với bạn bè'),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: AppTypography.bodySM),
      ],
    );
  }
}

/// Sign out button
class _SignOutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SignOutButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            : const Icon(Icons.logout),
        label: Text(
          isLoading ? 'Đang đăng xuất...' : 'Đăng xuất',
          style: AppTypography.labelMD,
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

/// Sign in button for anonymous users
class _SignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.login),
        label: const Text('Đăng nhập'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
