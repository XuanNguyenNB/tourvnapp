import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/profile/presentation/providers/update_preferences_provider.dart';

/// Màn hình cập nhật sở thích — tách khỏi Onboarding flow
///
/// Chỉ hiển thị phần chọn mood + destination, KHÔNG có
/// trang Welcome và Location Permission.
/// UI light theme, phù hợp với style ProfileScreen.
class UpdatePreferencesScreen extends ConsumerWidget {
  const UpdatePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updatePreferencesProvider);

    // Listen for save success
    ref.listen(updatePreferencesProvider, (prev, next) {
      if (next.savedSuccessfully && !(prev?.savedSuccessfully ?? false)) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã cập nhật sở thích'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật sở thích'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: state.canSave
                ? () => ref
                    .read(updatePreferencesProvider.notifier)
                    .savePreferences()
                : null,
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Lưu',
                    style: AppTypography.labelMD.copyWith(
                      color: state.canSave
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.accentPink,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_outline,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      'Cá nhân hóa trải nghiệm',
                      style: AppTypography.headingMD,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Thay đổi phong cách và điểm đến yêu thích',
                        style: AppTypography.bodySM.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 1: Phong cách du lịch
                  _SectionHeader(
                    icon: Icons.auto_awesome,
                    title: 'Phong cách du lịch',
                    badge: state.selectedMoods.isNotEmpty
                        ? 'Đã chọn ${state.selectedMoods.length}'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Mood.all.map((mood) {
                      final isSelected = state.selectedMoods.contains(mood);
                      return _MoodChipLight(
                        mood: mood,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(updatePreferencesProvider.notifier)
                              .toggleMood(mood);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 2: Điểm đến yêu thích
                  _SectionHeader(
                    icon: Icons.explore_outlined,
                    title: 'Điểm đến yêu thích',
                    badge: state.selectedDestinationIds.isNotEmpty
                        ? 'Đã chọn ${state.selectedDestinationIds.length}'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Chọn điểm đến để nhận gợi ý chính xác hơn',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Destination grid
                  _DestinationGrid(
                    selectedIds: state.selectedDestinationIds,
                    onToggle: (id) {
                      HapticFeedback.lightImpact();
                      ref
                          .read(updatePreferencesProvider.notifier)
                          .toggleDestination(id);
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

/// Section header với icon, title, và optional badge
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.labelMD.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge!,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Mood chip cho light theme (khác style onboarding dark theme)
class _MoodChipLight extends StatelessWidget {
  final Mood mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodChipLight({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              mood.label,
              style: AppTypography.bodySM.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grid hiển thị danh sách điểm đến
class _DestinationGrid extends ConsumerWidget {
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _DestinationGrid({
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(allDestinationsProvider);

    return destinationsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Không thể tải điểm đến',
          style: AppTypography.bodySM.copyWith(color: AppColors.textSecondary),
        ),
      ),
      data: (destinations) {
        final published =
            destinations.where((d) => d.status == 'published').toList();

        if (published.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Chưa có điểm đến nào',
              style: AppTypography.bodySM.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: published.length,
          itemBuilder: (context, index) {
            final dest = published[index];
            final isSelected = selectedIds.contains(dest.id);

            return _DestinationCardLight(
              name: dest.name,
              imageUrl: dest.heroImage,
              isSelected: isSelected,
              onTap: () => onToggle(dest.id),
            );
          },
        );
      },
    );
  }
}

/// Destination card cho light theme
class _DestinationCardLight extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _DestinationCardLight({
    required this.name,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero image
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.border.withValues(alpha: 0.3),
                  child: const Icon(
                    Icons.landscape_rounded,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                ),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),

              // Selected check
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),

              // Name
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  name,
                  style: AppTypography.bodySM.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
