import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
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
import '../../../../core/config/app_config.dart';
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

  // ── Expandable stop cards ──
  final Set<String> _expandedStops = {};
  final Map<String, String> _lazyTips = {};
  final Set<String> _loadingTips = {};

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
    final isPickingDest = _selectedDestination == null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      extendBodyBehindAppBar: isPickingDest,
      appBar: AppBar(
        backgroundColor: isPickingDest ? Colors.transparent : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(
          color: isPickingDest ? Colors.white : AppColors.textPrimary,
          onPressed: _handleBack,
        ),
        title: isPickingDest
            ? null
            : Text(
                _selectedDestination!.name,
                style: AppTypography.headingMD.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: !isPickingDest,
        child: isPickingDest ? _buildDestinationPicker() : _buildWizard(),
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
      children: [
        // ── Gradient Hero Header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFF4338CA)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✨ AI Lập Lịch Trình',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn điểm đến và để AI tạo hành trình hoàn hảo',
                style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 20),
              // ── Glassmorphic Search ──
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Tìm điểm đến...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, size: 20, color: Colors.white.withValues(alpha: 0.7)),
                            onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── Destination List ──
        Expanded(
          child: destinationsAsync.when(
            data: (destinations) {
              final filtered = _filterDestinations(destinations);
              if (filtered.isEmpty) {
                return const Center(child: Text('🔍 Không tìm thấy', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final d = filtered[index];
                  return _DestinationTile(destination: d, onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedDestination = d);
                  });
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Không thể tải danh sách', style: AppTypography.bodyMD.copyWith(color: AppColors.textSecondary)),
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
    const icons = [Icons.tune, Icons.favorite_border, Icons.settings_outlined];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: List.generate(5, (i) {
          // i=0,2,4 are dots; i=1,3 are connectors
          if (i.isOdd) {
            final lineIdx = i ~/ 2;
            final isDone = lineIdx < _step;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: isDone
                      ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)])
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
                width: isActive ? 44 : 36,
                height: isActive ? 44 : 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (isActive || isDone)
                      ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)])
                      : null,
                  color: (isActive || isDone) ? null : const Color(0xFFF1F5F9),
                  boxShadow: isActive ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
                  ] : null,
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : icons[stepIdx],
                  color: (isActive || isDone) ? Colors.white : const Color(0xFF94A3B8),
                  size: isActive ? 22 : 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[stepIdx],
                style: TextStyle(
                  fontSize: 12,
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

        // Day quick-select — circular glow buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [2, 3, 5, 7].map((d) {
            final isSelected = _days == d && !hasDates;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() { _days = d; _startDate = null; _endDate = null; });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)])
                      : null,
                  color: isSelected ? null : Colors.white,
                  border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: isSelected ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 1),
                  ] : [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$d',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'ngày',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
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
        // Pace cards — gradient-bordered
        ...TravelPace.values.map((p) {
          final selected = _pace == p;
          return GestureDetector(
            onTap: () => setState(() => _pace = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected ? [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8),
                ] : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Text(_paceEmoji(p), style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: selected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '~${p.locationsPerDay} điểm/ngày × $_days ngày = ~${p.locationsPerDay * _days} điểm',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                ],
              ),
            ),
          );
        }),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFFA78BFA)],
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI đang lập kế hoạch...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đang phân tích sở thích, tối ưu tuyến đường\nvà sắp xếp lịch trình cho bạn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
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
        // ── Gradient Hero Banner ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.tripTitle != null)
                Text(
                  result.tripTitle!,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
                ),
              if (result.tripDescription != null) ...[
                const SizedBox(height: 6),
                Text(
                  result.tripDescription!,
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              // Stats row
              Row(
                children: [
                  _heroBadge(Icons.calendar_today_rounded, '${result.request.numberOfDays} ngày'),
                  const SizedBox(width: 12),
                  _heroBadge(Icons.place_rounded, '${result.totalStops} điểm'),
                  const SizedBox(width: 12),
                  _heroBadge(Icons.directions_car_rounded, '~${result.totalTravelTimeMin}p'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }


  Widget _buildDayPreview(AutoPlanDay day) {
    if (day.stops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Ngày ${day.dayIndex + 1}: Ngày tự do 🌴',
            style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header — gradient pill
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ngày ${day.dayIndex + 1}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${day.stops.length} điểm',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              if (day.dayTheme != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day.dayTheme!,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Stop cards with travel bubbles between them
        ...day.stops.asMap().entries.expand((e) {
          final stop = e.value;
          final isLast = e.key == day.stops.length - 1;
          final widgets = <Widget>[];

          // Travel info bubble (between cards)
          if (stop.travelFromPrevious != null) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 2, bottom: 2),
                child: Row(
                  children: [
                    Container(
                      width: 2, height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.primary.withValues(alpha: 0.08)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_car, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            '${stop.travelFromPrevious!.formattedTravelTime} • ${stop.travelFromPrevious!.formattedDistance}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
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
                    // Lazy generate tip if not available
                    if (stop.aiDescription == null && !_lazyTips.containsKey(stopKey) && !_loadingTips.contains(stopKey)) {
                      _generateLazyTip(stopKey, stop);
                    }
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(bottom: isLast ? 20 : 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExpanded ? const Color(0xFFFAF5FF) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpanded ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isExpanded
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                      blurRadius: isExpanded ? 16 : 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main row
                    Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: _slotColorBg(stop.timeSlotName),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(stop.location.categoryEmoji, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.location.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _timeChip(stop.startTimeLabel),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${stop.durationMin} phút',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
                            size: 22,
                            color: isExpanded ? AppColors.primary : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                    // Expanded content
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withValues(alpha: 0.06), AppColors.primary.withValues(alpha: 0.02)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text('Lời khuyên AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // AI description or loading
                            if (stop.aiDescription != null)
                              Text(
                                stop.aiDescription!,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                              )
                            else if (_lazyTips.containsKey(stopKey))
                              Text(
                                _lazyTips[stopKey]!,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                              )
                            else if (_loadingTips.contains(stopKey))
                              Row(
                                children: [
                                  SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI đang tạo lời khuyên...',
                                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'Chạm để nhận lời khuyên từ AI',
                                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                              ),
                            // Reasons tags
                            if (stop.reasons.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: stop.reasons.map((r) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(r, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF16A34A))),
                                )).toList(),
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

  Widget _timeChip(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        time,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
    );
  }

  Color _slotColorBg(String slot) {
    switch (slot) {
      case 'morning': return const Color(0xFFFFF7ED);
      case 'noon': return const Color(0xFFFEF9C3);
      case 'afternoon': return const Color(0xFFEFF6FF);
      case 'evening': return const Color(0xFFF0F0FF);
      default: return const Color(0xFFF8FAFC);
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Quay lại', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED), Color(0xFF6D28D9)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (_step < 2) { setState(() => _step++); } else { _onGenerate(); }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _step < 2 ? 'Tiếp tục' : '✨ Tạo lịch trình',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
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
              onPressed: () => setState(() => _step = 2),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Sửa cài đặt', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: _onGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('🔄 Thử lại', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton(
              onPressed: planState.isEnriching ? null : _onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('✅ Áp dụng lịch trình', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  // ── Lazy AI tip generation ──
  Future<void> _generateLazyTip(String stopKey, AutoPlanStop stop) async {
    setState(() => _loadingTips.add(stopKey));
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${AppConfig.geminiApiKey}',
      );
      final prompt = 'Bạn là hướng dẫn viên du lịch Việt Nam chuyên nghiệp. '
          'Địa điểm: ${stop.location.name} (loại: ${stop.location.category}). '
          'Thời gian ghé: ${stop.startTimeLabel} - ${stop.endTimeLabel} (${stop.durationMin} phút). '
          'Viết 2-3 câu lời khuyên gọn bằng tiếng Việt cho du khách khi đến đây: '
          'nên làm gì, mẹo hữu ích, lưu ý. Chỉ trả lời thuần text ngắn gọn.';

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': 150},
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        setState(() {
          _lazyTips[stopKey] = text ?? 'Hãy dành ${stop.durationMin} phút khám phá ${stop.location.name}.';
          _loadingTips.remove(stopKey);
        });
      } else if (mounted) {
        setState(() {
          _lazyTips[stopKey] = 'Hãy dành ${stop.durationMin} phút khám phá ${stop.location.name}. Đây là điểm ${stop.location.category} được đánh giá cao.';
          _loadingTips.remove(stopKey);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lazyTips[stopKey] = 'Hãy dành ${stop.durationMin} phút khám phá ${stop.location.name}. Đây là điểm ${stop.location.category} được đánh giá cao trong khu vực.';
          _loadingTips.remove(stopKey);
        });
      }
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (destination.description.isNotEmpty)
                    Text(
                      destination.description,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
