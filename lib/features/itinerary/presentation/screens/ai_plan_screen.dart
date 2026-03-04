import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/category.dart';
import '../../../home/domain/utils/destination_emoji_helper.dart';
import '../../../recommendation/domain/entities/user_profile.dart';
import '../../../trip/presentation/providers/pending_trip_provider.dart';
import '../../domain/models/auto_plan_request.dart';
import '../../domain/services/auto_plan_service.dart';
import '../providers/auto_plan_provider.dart';

/// Tags available for filtering.
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

/// AI Plan Screen — full-page wizard.
///
/// Phase 0: Choose destination (with search)
/// Phase 1-3: AutoPlan wizard steps (basic → prefs → advanced)
/// Phase 4: Generate & preview
class AiPlanScreen extends ConsumerStatefulWidget {
  const AiPlanScreen({super.key});

  @override
  ConsumerState<AiPlanScreen> createState() => _AiPlanScreenState();
}

class _AiPlanScreenState extends ConsumerState<AiPlanScreen> {
  // ── Destination selection ──
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Destination? _selectedDestination;

  // ── Wizard state (mirrors AutoPlanSheet) ──
  int _step = 0; // 0: basic, 1: prefs, 2: advanced, 3: preview

  // Step 1 — Cơ bản
  int _days = 3;
  DateTime? _startDate;
  DateTime? _endDate;
  TravelPace _pace = TravelPace.normal;

  // Step 2 — Sở thích
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedTags = {};

  // Step 3 — Nâng cao
  BudgetLevel _budget = BudgetLevel.medium;
  final TextEditingController _budgetController = TextEditingController();
  GroupType _group = GroupType.solo;
  bool _useBehavior = true;
  bool _diversify = true;

  @override
  void dispose() {
    _searchController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: _handleBack,
        ),
        title: Text(
          _selectedDestination == null
              ? 'AI lên lịch trình'
              : _selectedDestination!.name,
          style: AppTypography.headingMD.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _selectedDestination == null
            ? _buildDestinationPicker()
            : _buildWizard(),
      ),
    );
  }

  void _handleBack() {
    if (_selectedDestination != null) {
      // Go back to destination picker
      setState(() {
        _selectedDestination = null;
        _step = 0;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Phase 0 — Destination picker with search
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDestinationPicker() {
    final destinationsAsync = ref.watch(allDestinationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✨ Bạn muốn đến đâu?',
                style: AppTypography.headingLG.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chọn điểm đến và để AI tạo lịch trình hoàn hảo cho bạn',
                style: AppTypography.bodySM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Tìm điểm đến...',
              hintStyle: AppTypography.bodyMD.copyWith(
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Destination list
        Expanded(
          child: destinationsAsync.when(
            data: (destinations) {
              final filtered = _filterDestinations(destinations);
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Không tìm thấy điểm đến',
                        style: AppTypography.bodyMD.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.sm,
                  bottom: 100,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final d = filtered[index];
                  return _DestinationTile(
                    destination: d,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedDestination = d);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Không thể tải danh sách điểm đến',
                style: AppTypography.bodyMD.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Destination> _filterDestinations(List<Destination> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Phase 1-4 — Wizard (integrated from AutoPlanSheet)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildWizard() {
    final planState = ref.watch(autoPlanProvider);
    final dest = _selectedDestination!;

    return Column(
      children: [
        // Destination header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                    Text(
                      dest.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Text(
                      'Tuỳ chỉnh lịch trình',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              // Change destination button
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedDestination = null;
                  _step = 0;
                }),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Đổi'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Step indicator
        if (_step < 3) _buildStepIndicator(),
        const SizedBox(height: AppSpacing.md),

        // Content
        Expanded(
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            100,
          ),
          child: _step < 3
              ? _buildNavigationButtons()
              : _buildPreviewButtons(planState),
        ),
      ],
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
    final hasDates = _startDate != null && _endDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        _label('📅 Thời gian'),
        const SizedBox(height: 8),

        // Date range display / picker trigger
        GestureDetector(
          onTap: () => _pickDateRange(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasDates
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDates ? AppColors.primary : Colors.grey.shade300,
                width: hasDates ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: hasDates ? AppColors.primary : Colors.grey.shade500,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: hasDates
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatDate(_startDate!)} → ${_formatDate(_endDate!)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDays(_days),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Chọn ngày đi cụ thể (tuỳ chọn)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: hasDates ? AppColors.primary : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Quick-select chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [2, 3, 5, 7].map((d) {
            final isSelected = _days == d && !hasDates;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _days = d;
                  _startDate = null;
                  _endDate = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  '$d ngày',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialStart = _startDate ?? now;
    final initialEnd = _endDate ?? now.add(Duration(days: _days - 1));

    final result = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      locale: const Locale('vi', 'VN'),
      helpText: 'Chọn ngày đi & ngày về',
      cancelText: 'Huỷ',
      confirmText: 'Xong',
      saveText: 'Xong',
      fieldStartHintText: 'Ngày đi',
      fieldEndHintText: 'Ngày về',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      final days = result.end.difference(result.start).inDays + 1;
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
        _days = days.clamp(1, 30);
      });
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String _formatDays(int days) {
    if (days <= 1) return '1 ngày (đi về trong ngày)';
    return '$days ngày ${days - 1} đêm';
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

        // 3 preset levels
        Row(
          children: BudgetLevel.values.map((b) {
            final selected = _budget == b;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _budget = b;
                      _budgetController.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _budgetEmoji(b),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _budgetHint(b),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Custom budget input
        TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Hoặc nhập ngân sách cụ thể (VNĐ/ngày)',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(
              Icons.attach_money,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
            suffixText: 'VNĐ/ngày',
            suffixStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
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
        child: Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ngày ${day.dayIndex + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${day.stops.length} điểm',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              if (day.dayTheme != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day.dayTheme!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Stops
          ...day.stops.asMap().entries.map((e) {
            final stop = e.value;
            final isLast = e.key == day.stops.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
              child: Row(
                children: [
                  _slotBadge(stop.timeSlotName),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stop.location.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    stop.location.categoryEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Quay lại'),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              if (_step < 2) {
                setState(() => _step++);
              } else {
                _onGenerate();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(_step < 2 ? 'Tiếp tục' : '✨ Tạo lịch trình'),
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
              onPressed: () => setState(() => _step = 2),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Sửa cài đặt'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text('🔄 Thử lại'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: planState.isEnriching ? null : _onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text('✅ Áp dụng lịch trình'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 2),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Sửa cài đặt'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _onGenerate,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('🔄 Tạo lại'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────

  void _onGenerate() {
    final dest = _selectedDestination!;
    final request = AutoPlanRequest(
      destinationId: dest.id,
      destinationName: dest.name,
      numberOfDays: _days,
      pace: _pace,
      preferredCategoryIds: _selectedCategories.toList(),
      preferredTags: _selectedTags.toList(),
      budgetLevel: _budget,
      groupType: _group,
      useBehaviorSignals: _useBehavior,
      diversify: _diversify,
    );
    ref.read(autoPlanProvider.notifier).generate(request);
    setState(() => _step = 3);
  }

  void _onApply() {
    final planState = ref.read(autoPlanProvider);
    final result = planState.result;
    if (result == null) return;

    final dest = _selectedDestination!;

    // Set trip days into pending state with AI-generated title
    ref
        .read(pendingTripProvider.notifier)
        .setFromTripDays(
          days: result.toTripDays(),
          destinationId: dest.id,
          destinationName: dest.name,
          tripName: result.tripTitle,
          startDate: _startDate,
        );

    // Clear auto plan state
    ref.read(autoPlanProvider.notifier).clear();

    // Navigate to Visual Planner
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
        color: Color(0xFF334155),
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

  String _budgetEmoji(BudgetLevel b) {
    switch (b) {
      case BudgetLevel.low:
        return '💰';
      case BudgetLevel.medium:
        return '💵';
      case BudgetLevel.high:
        return '💎';
    }
  }

  String _budgetHint(BudgetLevel b) {
    switch (b) {
      case BudgetLevel.low:
        return '< 500k/ngày';
      case BudgetLevel.medium:
        return '500k-1.5tr';
      case BudgetLevel.high:
        return '> 1.5tr/ngày';
    }
  }

  Widget _slotBadge(String slot) {
    Color bg;
    String label;
    switch (slot) {
      case 'morning':
        bg = const Color(0xFFFFF7ED);
        label = '🌅';
        break;
      case 'noon':
        bg = const Color(0xFFFEF9C3);
        label = '☀️';
        break;
      case 'afternoon':
        bg = const Color(0xFFEFF6FF);
        label = '🌤️';
        break;
      case 'evening':
        bg = const Color(0xFFF0F0FF);
        label = '🌙';
        break;
      default:
        bg = const Color(0xFFF8FAFC);
        label = '📍';
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 14))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Destination tile widget (unchanged)
// ─────────────────────────────────────────────────────────────────────

class _DestinationTile extends StatelessWidget {
  final Destination destination;
  final VoidCallback onTap;

  const _DestinationTile({required this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final emoji = DestinationEmojiHelper.getEmoji(destination.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: AppTypography.headingMD.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (destination.description.isNotEmpty)
                    Text(
                      destination.description,
                      style: AppTypography.bodySM.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
