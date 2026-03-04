import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == _step;
          final isDone = i < _step;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDone || isActive
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.primary
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
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
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            final day = i + 1;
            final selected = _days == day;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  label: Text('$day'),
                  selected: selected,
                  onSelected: (_) => setState(() => _days = day),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        _label('🚶 Nhịp độ'),
        const SizedBox(height: 8),
        Row(
          children: TravelPace.values.map((p) {
            final selected = _pace == p;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(
                    '${_paceEmoji(p)} ${p.label}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _pace = p),
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
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_pace.label}: ~${_pace.locationsPerDay} điểm/ngày × $_days ngày = ~${_pace.locationsPerDay * _days} điểm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        // AI Title & Description
        if (result.tripTitle != null) ...[
          Text(
            result.tripTitle!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          if (result.tripDescription != null)
            Text(
              result.tripDescription!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
          const SizedBox(height: 16),
        ],

        // Summary card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã tạo ${result.request.numberOfDays} ngày lịch trình!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${result.totalStops} điểm dừng • ~${result.totalTravelTimeMin} phút di chuyển',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Day-by-day preview
        ...result.days.asMap().entries.map((entry) {
          final day = entry.value;
          return _buildDayPreview(day);
        }),

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildDayPreview(AutoPlanDay day) {
    if (day.stops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Ngày ${day.dayIndex + 1}: Ngày tự do 🌴',
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ngày ${day.dayIndex + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (day.dayTheme != null)
                Expanded(
                  child: Text(
                    day.dayTheme!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Text(
                  '${day.stops.length} điểm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
          if (day.dayDescription != null) ...[
            const SizedBox(height: 6),
            Text(
              day.dayDescription!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Stops timeline
          ...day.stops.asMap().entries.map((entry) {
            final stop = entry.value;
            final isLast = entry.key == day.stops.length - 1;
            return _buildStopItem(stop, isLast: isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildStopItem(AutoPlanStop stop, {bool isLast = false}) {
    return Column(
      children: [
        // Travel leg (if has previous travel info)
        if (stop.travelFromPrevious != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 4, top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car,
                  size: 12,
                  color: const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  '${stop.travelFromPrevious!.formattedTravelTime} • ${stop.travelFromPrevious!.formattedDistance}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        // Stop item
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time
            SizedBox(
              width: 42,
              child: Text(
                stop.startTimeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            // Dot + line
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _slotColor(stop.timeSlotName),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stop.location.categoryEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stop.location.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _slotBadge(stop.timeSlotName),
                      const SizedBox(width: 6),
                      Text(
                        '${stop.durationMin} phút',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  // AI Stop Description
                  if (stop.aiDescription != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        stop.aiDescription!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  // Reasons
                  if (stop.reasons.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: stop.reasons
                            .take(2)
                            .map(
                              (r) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (!isLast) const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
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
