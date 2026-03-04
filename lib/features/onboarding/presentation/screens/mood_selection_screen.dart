import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tour_vn/core/services/onboarding_service.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';
import 'package:tour_vn/core/widgets/gradient_button.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';
import 'package:tour_vn/features/onboarding/domain/entities/mood.dart';
import 'package:tour_vn/features/onboarding/presentation/providers/destination_selection_provider.dart';
import 'package:tour_vn/features/onboarding/presentation/providers/mood_selection_provider.dart';
import 'package:tour_vn/features/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:tour_vn/features/onboarding/presentation/widgets/mood_chip.dart';
import 'package:tour_vn/features/home/presentation/providers/user_location_provider.dart';

/// Màn hình Onboarding chọn phong cách du lịch + địa điểm muốn đi.
///
/// Flow: Welcome → Mood Selection + Destination Picker → Home
class MoodSelectionScreen extends ConsumerStatefulWidget {
  const MoodSelectionScreen({super.key});

  @override
  ConsumerState<MoodSelectionScreen> createState() =>
      _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends ConsumerState<MoodSelectionScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;

  // Animation controller for entrance animations
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _goToMoodSelection() {
    HapticFeedback.mediumImpact();
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A), // Slate-900
                Color(0xFF1E1B4B), // Indigo-950
                Color(0xFF0F172A), // Slate-900
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Aurora glow effects - premium background
              _buildAuroraGlow(
                top: -50,
                left: -80,
                size: 280,
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
              _buildAuroraGlow(
                top: 150,
                right: -100,
                size: 250,
                color: const Color(0xFFF6339A).withValues(alpha: 0.15),
              ),
              _buildAuroraGlow(
                bottom: 100,
                left: -60,
                size: 200,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
              ),

              // Main content - PageView
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  // Reset animation for new pages
                  if (page >= 1) {
                    _animController.reset();
                    _animController.forward();
                  }
                },
                children: [
                  _buildWelcomePage(),
                  _buildSelectionPage(),
                  _buildLocationPermissionPage(),
                ],
              ),

              // Page indicator dots
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PAGE 1: WELCOME ───────────────────────────────────────────────

  Widget _buildWelcomePage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                const Spacer(flex: 2),

                // App logo with gradient
                _buildAnimatedLogo(),

                const SizedBox(height: 40),

                // Main heading
                Text(
                  'Chào bạn! 👋',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'TourVN giúp bạn khám phá\nnhững điểm đến tuyệt vời\ntrên khắp Việt Nam 🇻🇳',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Feature highlights
                _buildFeatureHighlights(),

                const Spacer(flex: 3),

                // CTA Button
                GradientButton(
                  text: 'Bắt đầu khám phá',
                  onPressed: _goToMoodSelection,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  height: 56,
                ),

                const SizedBox(height: 60), // Space for page dots
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accentPink],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.white],
          ).createShader(bounds),
          child: Text('✈️', style: const TextStyle(fontSize: 44)),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    final features = [
      ('🗺️', 'Gợi ý địa điểm phù hợp với bạn'),
      ('⭐', 'Đánh giá chân thực từ cộng đồng'),
      ('📍', 'Lên lịch trình du lịch thông minh'),
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(feature.$1, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                feature.$2,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── PAGE 2: MOOD + DESTINATION SELECTION ──────────────────────────

  Widget _buildSelectionPage() {
    final moodState = ref.watch(moodSelectionProvider);
    final destState = ref.watch(destinationSelectionProvider);
    final onboardingState = ref.watch(onboardingNotifierProvider);

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              // Header (fixed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Back button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Cá nhân hóa trải nghiệm',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chọn sở thích và nơi bạn muốn đến 🎯',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ──── Section 1: Mood Selection ────
                      _buildSectionHeader(
                        icon: '✨',
                        title: 'Phong cách du lịch',
                        subtitle: 'Đã chọn ${moodState.selectedMoods.length}',
                        showSubtitle: moodState.hasSelection,
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Mood.all.map((mood) {
                          return MoodChip(
                            mood: mood,
                            isSelected: moodState.isSelected(mood),
                            onTap: () => ref
                                .read(moodSelectionProvider.notifier)
                                .toggleMood(mood),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // ──── Section 2: Destination Picker ────
                      _buildSectionHeader(
                        icon: '🗺️',
                        title: 'Bạn muốn đi đâu?',
                        subtitle: 'Đã chọn ${destState.count}',
                        showSubtitle: destState.hasSelection,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Chọn điểm đến để nhận gợi ý chính xác hơn',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Search bar
                      _buildDestinationSearch(),

                      const SizedBox(height: 16),

                      // Destination grid
                      _buildDestinationGrid(),

                      const SizedBox(height: 100), // Space for button
                    ],
                  ),
                ),
              ),

              // CTA Button (fixed bottom)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildCTASection(
                  moodState: moodState,
                  destState: destState,
                  isLoading: onboardingState.isLoading,
                ),
              ),

              const SizedBox(height: 60), // Space for page dots
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String icon,
    required String title,
    String? subtitle,
    bool showSubtitle = false,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        if (showSubtitle && subtitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDestinationSearch() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tìm điểm đến...',
          hintStyle: GoogleFonts.beVietnamPro(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.4),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDestinationGrid() {
    final destinationsAsync = ref.watch(allDestinationsProvider);

    return destinationsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: Colors.white54,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Không thể tải điểm đến',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      ),
      data: (destinations) {
        // Filter by search query
        var filtered = destinations
            .where((d) => d.status == 'published')
            .toList();
        final query = _searchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          filtered = filtered
              .where((d) => d.name.toLowerCase().contains(query))
              .toList();
        }

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Không tìm thấy điểm đến nào',
              style: GoogleFonts.beVietnamPro(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
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
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final dest = filtered[index];
            return _DestinationCard(
              destination: dest,
              isSelected: ref
                  .watch(destinationSelectionProvider)
                  .isSelected(dest.id),
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(destinationSelectionProvider.notifier).toggle(dest.id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCTASection({
    required MoodSelectionState moodState,
    required DestinationSelectionState destState,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    final hasAny = moodState.hasSelection || destState.hasSelection;

    return Column(
      children: [
        GradientButton(
          text: hasAny ? 'Khám phá ngay! 🚀' : 'Chọn ít nhất 1 mục',
          onPressed: hasAny
              ? () => _handleContinue(moodState, destState)
              : null,
          height: 56,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: isLoading ? null : _handleSkip,
          child: Text(
            'Để sau, tôi muốn xem trước',
            style: AppTypography.bodySM.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SHARED WIDGETS ────────────────────────────────────────────────

  Widget _buildAuroraGlow({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: color.a * 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  // ─── PAGE 3: LOCATION PERMISSION ────────────────────────────────

  Widget _buildLocationPermissionPage() {
    final onboardingState = ref.watch(onboardingNotifierProvider);

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Location icon with glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [const Color(0xFF06B6D4), AppColors.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Bật vị trí để\ntrải nghiệm tốt hơn',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'TourVN cần vị trí của bạn để:',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  // Benefits
                  _buildBenefitItem(
                    icon: Icons.near_me_rounded,
                    color: const Color(0xFF06B6D4),
                    title: 'Gợi ý địa điểm gần bạn',
                    subtitle: 'Tìm quán ăn, cafe, điểm đến trong phạm vi gần',
                  ),
                  const SizedBox(height: 14),
                  _buildBenefitItem(
                    icon: Icons.straighten_rounded,
                    color: AppColors.primary,
                    title: 'Hiển thị khoảng cách',
                    subtitle: 'Biết ngay từng điểm đến cách bạn bao xa',
                  ),
                  const SizedBox(height: 14),
                  _buildBenefitItem(
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFFF59E0B),
                    title: 'Gợi ý thông minh hơn',
                    subtitle: 'Ưu tiên điểm đến phù hợp với vị trí hiện tại',
                  ),

                  const SizedBox(height: 32),

                  // CTA: Allow
                  if (onboardingState.isLoading)
                    const SizedBox(
                      height: 56,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    GradientButton(
                      text: '📍 Cho phép truy cập vị trí',
                      onPressed: _handleFinishWithGPS,
                      height: 56,
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // Skip
                  TextButton(
                    onPressed: onboardingState.isLoading
                        ? null
                        : _handleFinishWithoutGPS,
                    child: Text(
                      'Để sau, không cần vị trí',
                      style: AppTypography.bodySM.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60), // Space for page dots
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HANDLERS ──────────────────────────────────────────────────────

  /// From page 2 → navigate to page 3 (GPS permission page).
  void _handleContinue(
    MoodSelectionState moodState,
    DestinationSelectionState destState,
  ) {
    HapticFeedback.mediumImpact();
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  /// From page 3 → complete onboarding + request GPS.
  Future<void> _handleFinishWithGPS() async {
    HapticFeedback.mediumImpact();

    // Request GPS first (shows native dialog)
    bool granted = false;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      granted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      // Non-critical
    }

    // If granted, pre-load position so home screen has distances immediately
    if (granted) {
      try {
        await ref.read(userLocationProvider.notifier).loadPosition();
      } catch (_) {
        // Non-critical
      }
    }

    // Then complete onboarding
    await _completeAndNavigate();
  }

  /// From page 3 → skip GPS, just complete.
  Future<void> _handleFinishWithoutGPS() async {
    HapticFeedback.lightImpact();
    await _completeAndNavigate();
  }

  /// Save profile + navigate to home.
  Future<void> _completeAndNavigate() async {
    final moodState = ref.read(moodSelectionProvider);
    final destState = ref.read(destinationSelectionProvider);

    final success = await ref
        .read(onboardingNotifierProvider.notifier)
        .completeOnboarding(
          moodState.selectedMoods,
          selectedDestinationIds: destState.selectedIds.toList(),
        );

    if (!mounted) return;

    if (success) {
      ref.invalidate(shouldShowOnboardingProvider);
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xảy ra lỗi. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSkip() async {
    HapticFeedback.lightImpact();

    final success = await ref
        .read(onboardingNotifierProvider.notifier)
        .skipOnboarding();

    if (!mounted) return;

    if (success) {
      // Invalidate provider cache để router redirect không loop
      ref.invalidate(shouldShowOnboardingProvider);
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xảy ra lỗi. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ─── DESTINATION CARD ──────────────────────────────────────────────

class _DestinationCard extends StatelessWidget {
  final dynamic destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.destination,
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
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero image
              CachedNetworkImage(
                imageUrl: destination.heroImage,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: Colors.white.withValues(alpha: 0.05)),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.05),
                  child: const Icon(
                    Icons.landscape_rounded,
                    color: Colors.white24,
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
                      Colors.black.withValues(alpha: 0.75),
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

              // Name only
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  destination.name,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
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
