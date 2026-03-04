import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/user_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../destination/domain/entities/category.dart';
import '../../../destination/presentation/providers/location_provider.dart';

/// Preference survey screen for collecting user travel preferences.
///
/// Can be shown during onboarding (first login) or from profile settings.
/// Saves data to Firestore via [UserProfileRepository].
class PreferenceSurveyScreen extends ConsumerStatefulWidget {
  /// If true, shows a skip button and navigates to home after.
  final bool isOnboarding;

  const PreferenceSurveyScreen({super.key, this.isOnboarding = false});

  @override
  ConsumerState<PreferenceSurveyScreen> createState() =>
      _PreferenceSurveyScreenState();
}

class _PreferenceSurveyScreenState
    extends ConsumerState<PreferenceSurveyScreen> {
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedTags = {};
  TravelPace _pace = TravelPace.normal;
  BudgetLevel _budget = BudgetLevel.medium;
  GroupType _group = GroupType.solo;
  bool _saving = false;

  static const _availableTags = [
    ('romantic', '❤️ Lãng mạn'),
    ('adventure', '🏔️ Phiêu lưu'),
    ('hidden-gem', '💎 Ít người biết'),
    ('family-friendly', '👨‍👩‍👧 Gia đình'),
    ('instagram-worthy', '📸 Check-in'),
    ('budget-friendly', '💰 Tiết kiệm'),
    ('luxury', '✨ Sang trọng'),
    ('local-favorite', '⭐ Dân địa phương'),
    ('chill', '🧘 Thư giãn'),
    ('nightlife', '🎉 Về đêm'),
  ];

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryTabsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sở thích của bạn'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: widget.isOnboarding
            ? [TextButton(onPressed: _skip, child: const Text('Bỏ qua'))]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero text
            const Text(
              'Hãy cho chúng tôi biết bạn thích gì\nđể nhận gợi ý phù hợp hơn! 🎯',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 1: Categories
            _buildSectionTitle('🗂️ Loại hình yêu thích'),
            const SizedBox(height: AppSpacing.sm),
            categoriesAsync.when(
              data: (cats) => _buildCategoryChips(
                cats.where((c) => c.id != 'all').toList(),
              ),
              loading: () => const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _buildCategoryChips(Category.defaultCategories),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 2: Tags
            _buildSectionTitle('🏷️ Phong cách du lịch'),
            const SizedBox(height: AppSpacing.sm),
            _buildTagChips(),
            const SizedBox(height: AppSpacing.lg),

            // Section 3: Travel Pace
            _buildSectionTitle('🚶 Nhịp độ di chuyển'),
            const SizedBox(height: AppSpacing.sm),
            _buildPaceSelector(),
            const SizedBox(height: AppSpacing.lg),

            // Section 4: Budget
            _buildSectionTitle('💰 Ngân sách'),
            const SizedBox(height: AppSpacing.sm),
            _buildBudgetSelector(),
            const SizedBox(height: AppSpacing.lg),

            // Section 5: Group Type
            _buildSectionTitle('👥 Kiểu đi'),
            const SizedBox(height: AppSpacing.sm),
            _buildGroupSelector(),
            const SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Lưu sở thích',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    );
  }

  Widget _buildCategoryChips(List<Category> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final selected = _selectedCategories.contains(cat.id);
        return FilterChip(
          label: Text('${cat.emoji} ${cat.name}'),
          selected: selected,
          onSelected: (v) => setState(() {
            v
                ? _selectedCategories.add(cat.id)
                : _selectedCategories.remove(cat.id);
          }),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableTags.map((tag) {
        final selected = _selectedTags.contains(tag.$1);
        return FilterChip(
          label: Text(tag.$2),
          selected: selected,
          onSelected: (v) => setState(() {
            v ? _selectedTags.add(tag.$1) : _selectedTags.remove(tag.$1);
          }),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaceSelector() {
    return Row(
      children: TravelPace.values.map((p) {
        final selected = _pace == p;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(p.label),
              selected: selected,
              onSelected: (_) => setState(() => _pace = p),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetSelector() {
    return Row(
      children: BudgetLevel.values.map((b) {
        final selected = _budget == b;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(b.label),
              selected: selected,
              onSelected: (_) => setState(() => _budget = b),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupSelector() {
    return Row(
      children: GroupType.values.map((g) {
        final selected = _group == g;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              avatar: Text(g.emoji, style: const TextStyle(fontSize: 14)),
              label: Text(g.label, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _group = g),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final profile = UserProfile(
        userId: user.uid,
        preferredCategoryIds: _selectedCategories.toList(),
        preferredTags: _selectedTags.toList(),
        travelPace: _pace,
        budgetLevel: _budget,
        groupType: _group,
        updatedAt: DateTime.now(),
      );

      await ref.read(userProfileRepositoryProvider).saveProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu sở thích thành công! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skip() {
    Navigator.of(context).pop();
  }
}
