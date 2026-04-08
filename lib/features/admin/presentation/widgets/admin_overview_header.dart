import 'package:flutter/material.dart';

class AdminOverviewHeader extends StatelessWidget {
  const AdminOverviewHeader({
    super.key,
    required this.onRefresh,
    this.adminName,
  });

  final VoidCallback onRefresh;
  final String? adminName;

  @override
  Widget build(BuildContext context) {
    final resolvedName = adminName?.trim().isNotEmpty == true
        ? adminName!.trim()
        : 'quản trị viên';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào $resolvedName',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Đây là bảng điều hành nội bộ để theo dõi nội dung, kiểm duyệt và các bản nháp AI.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        );

        final refresh = FilledButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Làm mới'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 16), refresh],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: copy),
            const SizedBox(width: 16),
            refresh,
          ],
        );
      },
    );
  }
}
