import 'package:flutter/material.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';

/// Màn hình Quyền riêng tư — chính sách bảo mật, quản lý quyền
///
/// Hiển thị thông tin bảo mật tài khoản cho user.
/// Toggle settings chỉ là UI demo (không lưu thực tế).
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  // Demo toggle states (không lưu thực tế)
  bool _locationEnabled = true;
  bool _personalizedEnabled = true;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quyền riêng tư'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header icon
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Bảo mật & Quyền riêng tư',
                style: AppTypography.headingMD,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Quản lý dữ liệu và quyền của bạn',
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Section 1: Chính sách bảo mật
            _buildSection(
              title: 'Chính sách bảo mật',
              icon: Icons.article_outlined,
              child: Text(
                'TourVN cam kết bảo vệ quyền riêng tư của bạn. '
                'Chúng tôi chỉ thu thập dữ liệu cần thiết để cung cấp '
                'trải nghiệm du lịch cá nhân hóa tốt nhất. Dữ liệu của bạn '
                'được mã hóa và lưu trữ an toàn trên Firebase Cloud.',
                style: AppTypography.bodyMD.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 2: Dữ liệu được thu thập
            _buildSection(
              title: 'Dữ liệu được thu thập',
              icon: Icons.storage_outlined,
              child: Column(
                children: [
                  _DataItem(
                    icon: Icons.person_outline,
                    title: 'Thông tin tài khoản',
                    description: 'Tên, email, ảnh đại diện từ Google',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DataItem(
                    icon: Icons.favorite_outline,
                    title: 'Sở thích du lịch',
                    description: 'Phong cách, điểm đến yêu thích',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DataItem(
                    icon: Icons.location_on_outlined,
                    title: 'Vị trí (tùy chọn)',
                    description: 'Chỉ khi bạn cho phép, để gợi ý gần bạn',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DataItem(
                    icon: Icons.map_outlined,
                    title: 'Lịch trình đã tạo',
                    description: 'Chuyến đi, đánh giá, bình luận',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 3: Quản lý quyền
            _buildSection(
              title: 'Quản lý quyền',
              icon: Icons.tune_outlined,
              child: Column(
                children: [
                  _ToggleItem(
                    icon: Icons.location_on_outlined,
                    title: 'Truy cập vị trí',
                    description: 'Gợi ý địa điểm gần bạn',
                    value: _locationEnabled,
                    onChanged: (v) => setState(() => _locationEnabled = v),
                  ),
                  const Divider(height: 24),
                  _ToggleItem(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Gợi ý cá nhân hóa',
                    description: 'Sử dụng sở thích để gợi ý nội dung',
                    value: _personalizedEnabled,
                    onChanged: (v) => setState(() => _personalizedEnabled = v),
                  ),
                  const Divider(height: 24),
                  _ToggleItem(
                    icon: Icons.notifications_outlined,
                    title: 'Thông báo',
                    description: 'Nhận thông báo về chuyến đi và gợi ý',
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 4: Quyền của bạn
            _buildSection(
              title: 'Quyền của bạn',
              icon: Icons.verified_user_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RightItem(
                    icon: Icons.download_outlined,
                    text: 'Bạn có quyền yêu cầu xuất toàn bộ dữ liệu',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RightItem(
                    icon: Icons.edit_outlined,
                    text: 'Bạn có quyền chỉnh sửa thông tin cá nhân',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RightItem(
                    icon: Icons.delete_outline,
                    text: 'Bạn có quyền yêu cầu xóa toàn bộ dữ liệu',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Nút xóa tài khoản
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteAccountDialog(context),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Xóa tài khoản'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Footer
            Center(
              child: Text(
                'Cập nhật lần cuối: 08/04/2026',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.labelMD.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text(
          'Hành động này sẽ xóa vĩnh viễn tài khoản và toàn bộ dữ liệu '
          'của bạn. Bạn không thể hoàn tác sau khi xóa.\n\n'
          'Vui lòng liên hệ support@tourvn.app để yêu cầu xóa tài khoản.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Đã hiểu',
              style: AppTypography.labelMD.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item hiển thị loại dữ liệu được thu thập
class _DataItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _DataItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodySM),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Toggle item cho quản lý quyền
class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodySM),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}

/// Item hiển thị quyền của user
class _RightItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RightItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.success),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySM.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
