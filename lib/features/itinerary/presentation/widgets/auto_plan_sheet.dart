import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/ai_backend_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../destination/domain/entities/category.dart';
import '../../../recommendation/domain/entities/user_profile.dart';
import '../../../trip/presentation/providers/pending_trip_provider.dart';
import '../../domain/models/auto_plan_request.dart';
import '../../domain/services/auto_plan_service.dart';
import '../providers/auto_plan_provider.dart';

/// Tags available for filtering (reuses the same list as PreferenceSurveyScreen).
const _availableTags = [
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

/// Bottom sheet wizard for "AI Lập Kế Hoạch Tự Động".
///
/// Steps:
/// 1. Cơ bản: số ngày, nhịp độ
/// 2. Sở thích: categories, tags
/// 3. Nâng cao: budget, group, toggles
/// 4. Generate & Preview
class AutoPlanSheet extends ConsumerStatefulWidget {
  final String destinationId;
  final String destinationName;

  const AutoPlanSheet({
    super.key,
    required this.destinationId,
    required this.destinationName,
  });

  /// Show the auto-plan bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String destinationId,
    required String destinationName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AutoPlanSheet(
        destinationId: destinationId,
        destinationName: destinationName,
      ),
    );
  }

  @override
  ConsumerState<AutoPlanSheet> createState() => _AutoPlanSheetState();
}

class _AutoPlanSheetState extends ConsumerState<AutoPlanSheet> {
  int _step = 0; // 0: basic, 1: prefs, 2: advanced, 3: preview

  // Step 1 — Cơ bản
  int _days = 3;
  TravelPace _pace = TravelPace.normal;

  // Step 2 — Sở thích
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedTags = {};

  // Step 3 — Nâng cao
  BudgetLevel _budget = BudgetLevel.medium;
  GroupType _group = GroupType.solo;
  bool _useBehavior = true;
  bool _diversify = true;

  // ── Expandable stop cards ──
  final Set<String> _expandedStops = {};
  final Map<String, String> _lazyTips = {};
  final Set<String> _loadingTips = {};

  @override
  void dispose() {
    // Clear auto plan state when sheet is dismissed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
      // ignore: unused_result
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(autoPlanProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          _buildHeader(),
          const SizedBox(height: AppSpacing.sm),

          // Step indicator
          if (_step < 3) _buildStepIndicator(),
          const SizedBox(height: AppSpacing.md),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _step == 0
                  ? _buildStep1Basic()
                  : _step == 1
                  ? _buildStep2Prefs()
                  : _step == 2
                  ? _buildStep3Advanced()
                  : _buildStep4Preview(planState),
            ),
          ),

          // Bottom buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _step < 3
                  ? _buildNavigationButtons()
                  : _buildPreviewButtons(planState),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Lập Kế Hoạch',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  widget.destinationName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step indicator
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    const labels = ['Cơ bản', 'Sở thích', 'Nâng cao'];
    const icons = [Icons.tune, Icons.favorite_border, Icons.settings_outlined];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: List.generate(5, (i) {
          if (i.isOdd) {
            final lineIdx = i ~/ 2;
            final isDone = lineIdx < _step;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: isDone
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                        )
                      : null,
                  color: isDone ? null : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isActive = stepIdx == _step;
          final isDone = stepIdx < _step;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 40 : 32,
                height: isActive ? 40 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (isActive || isDone)
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        )
                      : null,
                  color: (isActive || isDone) ? null : const Color(0xFFF1F5F9),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : icons[stepIdx],
                  color: (isActive || isDone)
                      ? Colors.white
                      : const Color(0xFF94A3B8),
                  size: isActive ? 20 : 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepIdx],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.primary : const Color(0xFF94A3B8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 1 — Cơ bản
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStep1Basic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        _label('📅 Số ngày'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [1, 2, 3, 5, 7].map((d) {
            final selected = _days == d;
            return GestureDetector(
              onTap: () => setState(() => _days = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        )
                      : null,
                  color: selected ? null : Colors.white,
                  border: selected
                      ? null
                      : Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$d',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'ngày',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.8)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _label('🚶 Nhịp độ'),
        const SizedBox(height: 10),
        ...TravelPace.values.map((p) {
          final selected = _pace == p;
          return GestureDetector(
            onTap: () => setState(() => _pace = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(_paceEmoji(p), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '~${p.locationsPerDay} điểm/ngày',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 2 — Sở thích
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStep2Prefs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        _label('🗂️ Loại hình yêu thích'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Category.defaultCategories.map((cat) {
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
        ),
        const SizedBox(height: AppSpacing.lg),
        _label('🏷️ Phong cách'),
        const SizedBox(height: 8),
        Wrap(
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
        ),
        if (_selectedCategories.isEmpty && _selectedTags.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bỏ qua nếu muốn AI tự chọn đa dạng',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 3 — Nâng cao
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStep3Advanced() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        _label('💰 Ngân sách'),
        const SizedBox(height: 8),
        Row(
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
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _label('👥 Kiểu đi'),
        const SizedBox(height: 8),
        Row(
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
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _label('⚙️ Tuỳ chọn'),
        const SizedBox(height: 8),
        _toggleTile(
          title: 'Cá nhân hóa theo hành vi',
          subtitle: 'Dùng lịch sử tương tác để gợi ý phù hợp hơn',
          value: _useBehavior,
          onChanged: (v) => setState(() => _useBehavior = v),
        ),
        _toggleTile(
          title: 'Đa dạng điểm đến',
          subtitle: 'Trải đều nhiều loại hình thay vì tập trung',
          value: _diversify,
          onChanged: (v) => setState(() => _diversify = v),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 4 — Generate & Preview
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStep4Preview(AutoPlanState planState) {
    if (planState.isGenerating) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'AI đang lập kế hoạch...',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
            ),
            SizedBox(height: 8),
            Text(
              'Đang phân tích sở thích, tối ưu tuyến đường\nvà sắp xếp lịch trình cho bạn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    if (planState.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      planState.errorMessage!,
                      style: TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final result = planState.result;
    if (result == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (planState.isEnriching)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI đang viết lời dẫn hấp dẫn cho lịch trình...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _buildPreviewContent(result),
      ],
    );
  }

  Widget _buildPreviewContent(AutoPlanResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Gradient Hero Banner ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.tripTitle != null)
                Text(
                  result.tripTitle!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              if (result.tripDescription != null) ...[
                const SizedBox(height: 6),
                Text(
                  result.tripDescription!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _heroBadge(
                    Icons.calendar_today_rounded,
                    '${result.request.numberOfDays} ngày',
                  ),
                  const SizedBox(width: 10),
                  _heroBadge(Icons.place_rounded, '${result.totalStops} điểm'),
                  const SizedBox(width: 10),
                  _heroBadge(
                    Icons.directions_car_rounded,
                    '~${result.totalTravelTimeMin}p',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Day-by-day cards ──
        ...result.days.asMap().entries.map((entry) {
          final day = entry.value;
          return _buildDayPreview(day);
        }),

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _heroBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPreview(AutoPlanDay day) {
    if (day.stops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Ngày ${day.dayIndex + 1}: Ngày tự do 🌴',
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header — gradient pill
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Ngày ${day.dayIndex + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${day.stops.length} điểm',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              if (day.dayTheme != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day.dayTheme!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Stop cards with travel bubbles
        ...day.stops.asMap().entries.expand((e) {
          final stop = e.value;
          final isLast = e.key == day.stops.length - 1;
          final widgets = <Widget>[];

          // Travel info bubble
          if (stop.travelFromPrevious != null) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 10,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${stop.travelFromPrevious!.formattedTravelTime} • ${stop.travelFromPrevious!.formattedDistance}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Stop card — expandable
          final stopKey = '${day.dayIndex}_${e.key}';
          final isExpanded = _expandedStops.contains(stopKey);
          widgets.add(
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedStops.remove(stopKey);
                  } else {
                    _expandedStops.add(stopKey);
                    if (stop.aiDescription == null &&
                        !_lazyTips.containsKey(stopKey) &&
                        !_loadingTips.contains(stopKey)) {
                      _generateLazyTip(stopKey, stop);
                    }
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(bottom: isLast ? 16 : 3),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isExpanded ? const Color(0xFFFAF5FF) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isExpanded
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : const Color(0xFFF1F5F9),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isExpanded
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: isExpanded ? 14 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _slotColorBg(stop.timeSlotName),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              stop.location.categoryEmoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.location.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  _timeChip(stop.startTimeLabel),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${stop.durationMin} phút',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: isExpanded
                                ? AppColors.primary
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.06),
                              AppColors.primary.withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Lời khuyên AI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (stop.aiDescription != null)
                              Text(
                                stop.aiDescription!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                  height: 1.5,
                                ),
                              )
                            else if (_lazyTips.containsKey(stopKey))
                              Text(
                                _lazyTips[stopKey]!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                  height: 1.5,
                                ),
                              )
                            else if (_loadingTips.contains(stopKey))
                              Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'AI đang tạo lời khuyên...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'Chạm để nhận lời khuyên từ AI',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            if (stop.reasons.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 3,
                                children: stop.reasons
                                    .map(
                                      (r) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          r,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );

          return widgets;
        }),
      ],
    );
  }

  // ── Lazy AI tip generation ──
  Future<void> _generateLazyTip(String stopKey, AutoPlanStop stop) async {
    setState(() => _loadingTips.add(stopKey));
    try {
      final text = await ref
          .read(aiBackendServiceProvider)
          .generateStopTip(
            locationName: stop.location.name,
            category: stop.location.category,
            startTimeLabel: stop.startTimeLabel,
            endTimeLabel: stop.endTimeLabel,
            durationMin: stop.durationMin,
          );

      if (mounted) {
        setState(() {
          _lazyTips[stopKey] = text.isNotEmpty
              ? text
              : 'Hay danh ${stop.durationMin} phut kham pha ${stop.location.name}.';
          _loadingTips.remove(stopKey);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lazyTips[stopKey] =
              'Hay danh ${stop.durationMin} phut kham pha ${stop.location.name}. '
              'Day la diem ${stop.location.category} duoc danh gia cao trong khu vuc.';
          _loadingTips.remove(stopKey);
        });
      }
    }
  }

  Widget _timeChip(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Color _slotColorBg(String slot) {
    switch (slot) {
      case 'morning':
        return const Color(0xFFFFF7ED);
      case 'noon':
        return const Color(0xFFFEF9C3);
      case 'afternoon':
        return const Color(0xFFEFF6FF);
      case 'evening':
        return const Color(0xFFF0F0FF);
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Navigation buttons
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step--),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Quay lại'),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _step < 2 ? () => setState(() => _step++) : _onGenerate,
            icon: Icon(
              _step < 2 ? Icons.arrow_forward : Icons.auto_awesome,
              size: 18,
            ),
            label: Text(
              _step < 2 ? 'Tiếp theo' : 'Tạo lịch trình AI',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewButtons(AutoPlanState planState) {
    if (planState.isGenerating) return const SizedBox.shrink();

    if (planState.errorMessage != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Chỉnh tuỳ chọn'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _onGenerate,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    if (planState.result == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: planState.isEnriching ? null : _onGenerate,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tạo lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: planState.isEnriching ? null : _onApply,
            icon: const Icon(Icons.check, size: 18),
            label: const Text(
              'Áp dụng',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────

  void _onGenerate() {
    setState(() => _step = 3);

    final request = AutoPlanRequest(
      destinationId: widget.destinationId,
      destinationName: widget.destinationName,
      numberOfDays: _days,
      preferredCategoryIds: _selectedCategories.toList(),
      preferredTags: _selectedTags.toList(),
      pace: _pace,
      budgetLevel: _budget,
      groupType: _group,
      useBehaviorSignals: _useBehavior,
      diversify: _diversify,
    );

    ref.read(autoPlanProvider.notifier).generate(request);
  }

  void _onApply() {
    final result = ref.read(autoPlanProvider).result;
    if (result == null) return;

    // Set trip days into pending state.
    ref
        .read(pendingTripProvider.notifier)
        .setFromTripDays(
          days: result.toTripDays(),
          destinationId: widget.destinationId,
          destinationName: widget.destinationName,
        );

    // Clear auto plan state.
    ref.read(autoPlanProvider.notifier).clear();

    // Close sheet.
    Navigator.of(context).pop();

    // Navigate to Visual Planner.
    context.pushNamed(AppRoutes.visualPlanner);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    );
  }

  String _paceEmoji(TravelPace p) {
    switch (p) {
      case TravelPace.relaxed:
        return '🐢';
      case TravelPace.normal:
        return '🚶';
      case TravelPace.packed:
        return '🏃';
    }
  }

  Color _slotColor(String slot) {
    switch (slot) {
      case 'morning':
        return const Color(0xFFF59E0B); // amber
      case 'afternoon':
        return const Color(0xFF3B82F6); // blue
      case 'evening':
        return const Color(0xFF8B5CF6); // violet
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Widget _slotBadge(String slot) {
    String label;
    String emoji;
    switch (slot) {
      case 'morning':
        label = 'Sáng';
        emoji = '🌅';
        break;
      case 'afternoon':
        label = 'Chiều';
        emoji = '☀️';
        break;
      case 'evening':
        label = 'Tối';
        emoji = '🌙';
        break;
      default:
        label = slot;
        emoji = '📍';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _slotColor(slot).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _slotColor(slot),
        ),
      ),
    );
  }
}
