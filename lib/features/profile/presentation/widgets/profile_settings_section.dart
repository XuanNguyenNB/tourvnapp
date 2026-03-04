import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';

/// ProfileSettingsSection - Settings menu options on Profile screen
///
/// Displays settings options as list tiles.
/// Sign-out is handled separately in ProfileScreen (from Story 2.6).
class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text('Cài đặt', style: AppTypography.headingMD),
        const SizedBox(height: AppSpacing.sm),
        // Settings container
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              // Mood preferences - Story 6.4
              _SettingsTile(
                icon: Icons.favorite_outline,
                title: 'Cập nhật sở thích',
                subtitle: 'Thay đổi phong cách du lịch của bạn',
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/onboarding?edit=true');
                },
              ),
              const Divider(height: 1, indent: 56),
              // Account settings
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Thông tin tài khoản',
                subtitle: 'Chỉnh sửa hồ sơ',
                onTap: () => _showComingSoon(context),
              ),
              const Divider(height: 1, indent: 56),
              // Notifications
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Thông báo',
                subtitle: 'Quản lý thông báo',
                onTap: () => _showComingSoon(context),
              ),
              const Divider(height: 1, indent: 56),
              // Privacy
              _SettingsTile(
                icon: Icons.security_outlined,
                title: 'Quyền riêng tư',
                subtitle: 'Bảo mật tài khoản',
                onTap: () => _showComingSoon(context),
              ),
              const Divider(height: 1, indent: 56),
              // Help & Support
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Trợ giúp',
                subtitle: 'FAQ và hỗ trợ',
                onTap: () => _showComingSoon(context),
              ),
              const Divider(height: 1, indent: 56),
              // About
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Về TourVN',
                subtitle: 'Phiên bản 1.0.0',
                onTap: () => _showComingSoon(context),
                showChevron: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tính năng đang phát triển'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

/// Individual settings tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTypography.bodySM),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
