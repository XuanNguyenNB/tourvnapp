import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:url_launcher/url_launcher.dart';

/// Màn hình Trợ giúp — FAQ & liên hệ hỗ trợ
///
/// Features:
/// - FAQ expandable tiles
/// - Thông tin liên hệ hỗ trợ
/// - Nút gửi phản hồi
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'Làm sao để tạo lịch trình du lịch?',
      'Bạn có thể tạo lịch trình bằng 2 cách:\n\n'
          '1. **AI tự động**: Vào tab "Chuyến đi" → bấm nút "+" → chọn '
          '"AI lên kế hoạch". Nhập điểm đến, số ngày và AI sẽ gợi ý lịch trình chi tiết.\n\n'
          '2. **Tạo thủ công**: Vào tab "Chuyến đi" → bấm "Tạo chuyến đi" → '
          'thêm các hoạt động theo ý bạn.',
    ),
    (
      'Tôi có thể dùng app offline không?',
      'Hiện tại TourVN cần kết nối internet để:\n'
          '• Tải thông tin địa điểm mới nhất\n'
          '• Sử dụng AI gợi ý lịch trình\n'
          '• Đồng bộ chuyến đi giữa các thiết bị\n\n'
          'Tuy nhiên, các chuyến đi đã lưu sẽ được cache và bạn có thể xem '
          'lại khi không có mạng.',
    ),
    (
      'Làm sao để thay đổi sở thích?',
      'Vào **Hồ sơ** → **Cập nhật sở thích** → thay đổi phong cách du lịch '
          'và điểm đến yêu thích → bấm **Lưu**.\n\n'
          'Sở thích mới sẽ được áp dụng ngay cho phần gợi ý trên trang chủ.',
    ),
    (
      'Dữ liệu của tôi được lưu ở đâu?',
      'Dữ liệu của bạn được lưu trữ an toàn trên **Firebase Cloud** của Google. '
          'Bao gồm:\n'
          '• Thông tin tài khoản (mã hóa)\n'
          '• Chuyến đi đã tạo\n'
          '• Đánh giá & bình luận\n'
          '• Sở thích du lịch\n\n'
          'Bạn có thể yêu cầu xóa dữ liệu trong mục **Quyền riêng tư**.',
    ),
    (
      'Làm sao để chia sẻ chuyến đi?',
      'Tính năng chia sẻ chuyến đi đang được phát triển. '
          'Trong phiên bản tiếp theo, bạn sẽ có thể:\n'
          '• Chia sẻ lịch trình qua link\n'
          '• Mời bạn bè cùng chỉnh sửa\n'
          '• Xuất lịch trình dạng PDF',
    ),
    (
      'Gợi ý AI hoạt động như thế nào?',
      'TourVN sử dụng **Google Gemini AI** để tạo lịch trình cá nhân hóa. '
          'AI xem xét:\n'
          '• Sở thích du lịch của bạn\n'
          '• Điểm đến bạn chọn\n'
          '• Số ngày đi, ngân sách\n'
          '• Đánh giá từ cộng đồng\n\n'
          'Kết quả là lịch trình chi tiết theo từng ngày, bao gồm địa điểm, '
          'thời gian, và mẹo di chuyển.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp'),
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
                      const Color(0xFF06B6D4),
                      AppColors.primary,
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
                  Icons.support_agent_outlined,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Chúng tôi luôn sẵn sàng hỗ trợ',
                style: AppTypography.headingMD,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Tìm câu trả lời hoặc liên hệ với chúng tôi',
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Section 1: FAQ
            _buildSectionHeader(
              icon: Icons.quiz_outlined,
              title: 'Câu hỏi thường gặp',
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Column(
                  children: List.generate(_faqs.length, (index) {
                    final faq = _faqs[index];
                    return Column(
                      children: [
                        if (index > 0)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                        _FaqTile(question: faq.$1, answer: faq.$2),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Section 2: Liên hệ hỗ trợ
            _buildSectionHeader(
              icon: Icons.contact_support_outlined,
              title: 'Liên hệ hỗ trợ',
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _ContactItem(
                    icon: Icons.email_outlined,
                    title: 'Email hỗ trợ',
                    value: 'support@tourvn.app',
                    onTap: () => _launchEmail(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ContactItem(
                    icon: Icons.phone_outlined,
                    title: 'Hotline',
                    value: '1900-xxxx (8h - 22h)',
                    onTap: null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ContactItem(
                    icon: Icons.access_time_outlined,
                    title: 'Thời gian phản hồi',
                    value: 'Trong vòng 24 giờ',
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Section 3: Gửi phản hồi
            _buildSectionHeader(
              icon: Icons.rate_review_outlined,
              title: 'Gửi phản hồi',
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Bạn có góp ý hoặc phát hiện lỗi?',
                    style: AppTypography.bodyMD,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Phản hồi của bạn giúp TourVN ngày càng tốt hơn',
                    style: AppTypography.bodySM.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchEmail(context),
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Gửi phản hồi qua Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
        Text(title, style: AppTypography.labelMD.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@tourvn.app',
      queryParameters: {
        'subject': 'TourVN - Phản hồi từ người dùng',
      },
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Copy email to clipboard as fallback
        await Clipboard.setData(
          const ClipboardData(text: 'support@tourvn.app'),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã sao chép email hỗ trợ'),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(
        const ClipboardData(text: 'support@tourvn.app'),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã sao chép email hỗ trợ'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
    }
  }
}

/// FAQ tile với animation expand/collapse
class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          question,
          style: AppTypography.bodySM.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: AppTypography.bodySM.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Item liên hệ hỗ trợ
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(value, style: AppTypography.bodySM),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
