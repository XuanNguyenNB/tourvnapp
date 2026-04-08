import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';

/// Màn hình Cài đặt Thông báo (UI demo cho ĐATN)
/// Các toggle KHÔNG lưu thực tế, chỉ quản lý bằng local state
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Toggle states (UI demo only — không persist)
  bool _tripNotifications = true;
  bool _reviewNotifications = true;
  bool _recommendationNotifications = true;
  bool _systemNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Cài đặt thông báo', style: AppTypography.headingLG),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Loại thông báo
            _buildSectionHeader(
              icon: Icons.category_outlined,
              title: 'Loại thông báo',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard([
              _buildToggleTile(
                icon: Icons.map_outlined,
                iconColor: const Color(0xFF3B82F6),
                title: 'Chuyến đi',
                subtitle: 'Nhắc lịch trình, cập nhật trip',
                value: _tripNotifications,
                onChanged: (v) =>
                    setState(() => _tripNotifications = v),
              ),
              const Divider(height: 1, indent: 56),
              _buildToggleTile(
                icon: Icons.star_outline,
                iconColor: const Color(0xFFF59E0B),
                title: 'Đánh giá',
                subtitle: 'Bình luận mới, lượt thích',
                value: _reviewNotifications,
                onChanged: (v) =>
                    setState(() => _reviewNotifications = v),
              ),
              const Divider(height: 1, indent: 56),
              _buildToggleTile(
                icon: Icons.auto_awesome_outlined,
                iconColor: const Color(0xFF10B981),
                title: 'Gợi ý',
                subtitle: 'Điểm đến mới, địa điểm gần bạn',
                value: _recommendationNotifications,
                onChanged: (v) =>
                    setState(() => _recommendationNotifications = v),
              ),
              const Divider(height: 1, indent: 56),
              _buildToggleTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.primary,
                title: 'Hệ thống',
                subtitle: 'Cập nhật app, bảo trì',
                value: _systemNotifications,
                onChanged: (v) =>
                    setState(() => _systemNotifications = v),
              ),
            ]),

            const SizedBox(height: AppSpacing.lg),

            // Section: Tùy chọn
            _buildSectionHeader(
              icon: Icons.tune_outlined,
              title: 'Tùy chọn',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard([
              _buildToggleTile(
                icon: Icons.volume_up_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Âm thanh',
                subtitle: 'Phát âm thanh khi có thông báo',
                value: _soundEnabled,
                onChanged: (v) =>
                    setState(() => _soundEnabled = v),
              ),
              const Divider(height: 1, indent: 56),
              _buildToggleTile(
                icon: Icons.vibration_outlined,
                iconColor: const Color(0xFFEC4899),
                title: 'Rung',
                subtitle: 'Rung khi có thông báo mới',
                value: _vibrationEnabled,
                onChanged: (v) =>
                    setState(() => _vibrationEnabled = v),
              ),
            ]),

            const SizedBox(height: AppSpacing.lg),

            // Info card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Thông báo đẩy (push notifications) sẽ được hỗ trợ trong phiên bản tương lai.',
                      style: AppTypography.bodySM.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.labelMD.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMD.copyWith(
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
