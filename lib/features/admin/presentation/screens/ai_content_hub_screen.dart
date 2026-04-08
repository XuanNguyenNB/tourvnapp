import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai_backend_service.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../review/domain/entities/review.dart';
import '../providers/admin_ai_content_provider.dart';
import '../providers/admin_reference_data_provider.dart';

const Map<String, List<String>> _promptPresets = {
  'destination': ['Điểm đến nổi bật', '3N2Đ', 'Phong cách trẻ'],
  'location': ['Top 5 local', 'Check-in', 'Ẩm thực đặc trưng'],
  'review': ['Review chân thực', 'Guide 1 ngày', 'Top list'],
};

class AiContentHubScreen extends ConsumerStatefulWidget {
  const AiContentHubScreen({super.key});

  @override
  ConsumerState<AiContentHubScreen> createState() => _AiContentHubScreenState();
}

class _AiContentHubScreenState extends ConsumerState<AiContentHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _promptController = TextEditingController();

  String _generateType = 'destination';
  String? _selectedDestinationId;
  String? _selectedDestinationName;
  final Set<String> _selectedReviewLocationIds = <String>{};
  int _locationCount = 5;
  int _reviewCount = 1;
  String _articleStyle = 'review';
  bool _autoSelectedDone = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _promptController.text = _getDefaultPrompt();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiContentNotifierProvider);
    final healthAsync = ref.watch(aiBackendHealthProvider);

    ref.listen<AiContentState>(aiContentNotifierProvider, (previous, next) {
      if (!mounted) return;

      final previousMessage = previous?.successMessage;
      if (next.successMessage != null &&
          next.successMessage != previousMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }

      if ((previous?.isGenerating ?? false) &&
          !next.isGenerating &&
          next.lastGeneratedType == 'demo-pack' &&
          next.demoPackStep == DemoPackStep.completed) {
        _tabController.animateTo(1);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 24, 36, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
                    const SizedBox(width: 12),
                    const Text(
                      'Nội dung AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (aiState.isGenerating)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đang tạo nội dung...',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAiHealthBadge(healthAsync, aiState),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 16, 36, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Tạo nội dung'),
                  Tab(text: 'Chờ duyệt'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildGenerateTab(aiState), _buildPendingTab(aiState)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateTab(AiContentState aiState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Loại nội dung'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _typeChip('Điểm đến', 'destination', Icons.map_outlined),
              _typeChip('Địa điểm', 'location', Icons.place_outlined),
              _typeChip('Bài viết', 'review', Icons.article_outlined),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('Preset nhanh'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_promptPresets[_generateType] ?? const <String>[])
                .map(
                  (preset) => ActionChip(
                    label: Text(preset),
                    avatar: const Icon(Icons.auto_awesome, size: 16),
                    onPressed: () => _applyPreset(preset),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          if (_generateType != 'destination') ...[
            _sectionLabel('Thuộc điểm đến'),
            const SizedBox(height: 8),
            _buildDestinationSelector(),
            if (_generateType == 'review') ...[
              const SizedBox(height: 8),
              Text(
                'Bắt buộc chọn điểm đến để AI bám đúng ngữ cảnh, gắn đúng địa điểm và lấy được nguồn web phục vụ demo.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 20),
          ],
          if (_generateType == 'review' && _selectedDestinationId != null) ...[
            _sectionLabel('Địa điểm cần nhấn mạnh'),
            const SizedBox(height: 8),
            _buildReviewLocationSelector(),
            const SizedBox(height: 20),
          ],
          if (_generateType == 'location') ...[
            _sectionLabel('Số lượng'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [3, 5, 10].map((n) {
                return ChoiceChip(
                  label: Text('$n'),
                  selected: _locationCount == n,
                  onSelected: (_) => setState(() => _locationCount = n),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (_generateType == 'review') ...[
            _sectionLabel('Loại bài viết'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _styleChip('📝 Review', 'review'),
                _styleChip('📘 Guide', 'guide'),
                _styleChip('🏆 Top list', 'top-list'),
                _styleChip('💡 Tips', 'tips'),
              ],
            ),
            const SizedBox(height: 20),
            _sectionLabel('Số lượng bài'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 3, 5].map((n) {
                return ChoiceChip(
                  label: Text(n == 1 ? '1 bài' : '$n bài'),
                  selected: _reviewCount == n,
                  onSelected: (_) => setState(() => _reviewCount = n),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          _sectionLabel('Mô tả yêu cầu'),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _getHintText(),
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (aiState.demoPackStep != DemoPackStep.idle) ...[
            _buildDemoPackStepper(aiState),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: aiState.isGenerating ? null : _onGenerate,
              icon: aiState.isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(aiState.isGenerating ? 'Đang tạo...' : 'Tạo bằng AI'),
            ),
          ),
          if (aiState.error != null) ...[
            const SizedBox(height: 16),
            _messageCard(
              icon: Icons.error_outline,
              text: aiState.error!,
              background: Colors.red.shade50,
              border: Colors.red.shade200,
              foreground: Colors.red.shade700,
            ),
          ],
          if (aiState.successMessage != null && !aiState.isGenerating) ...[
            const SizedBox(height: 16),
            _messageCard(
              icon: Icons.check_circle,
              text: aiState.successMessage!,
              background: Colors.green.shade50,
              border: Colors.green.shade200,
              foreground: Colors.green.shade700,
            ),
            const SizedBox(height: 24),
            _buildDraftPreviewSection(aiState),
          ],
        ],
      ),
    );
  }

  /// Preview section showing AI drafts as they would appear in the app.
  Widget _buildDraftPreviewSection(AiContentState aiState) {
    final lastType = aiState.lastGeneratedType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.phone_android, size: 20, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              'Xem trước trên ứng dụng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Mô phỏng AI draft vừa tạo hiển thị trên app',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),
        if (lastType == 'destination') _buildDestinationDraftPreview(),
        if (lastType == 'location') _buildLocationDraftPreview(),
        if (lastType == 'review') _buildReviewDraftPreviewCards(),
      ],
    );
  }

  Widget _buildDestinationDraftPreview() {
    final asyncDests = ref.watch(pendingDestinationsProvider);
    return asyncDests.when(
      data: (dests) {
        if (dests.isEmpty) return _emptyPreviewCard('Chưa có điểm đến draft.');
        return Column(
          children: dests.take(3).map((dest) => _AppStylePreviewCard(
            imageUrl: dest.heroImage,
            title: dest.name,
            description: dest.description,
            badge: 'Điểm đến',
            badgeColor: Colors.blue,
            onApprove: () => _approveDestination(dest),
          )).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _emptyPreviewCard('Lỗi: $e'),
    );
  }

  Widget _buildLocationDraftPreview() {
    final asyncLocs = ref.watch(pendingLocationsProvider);
    return asyncLocs.when(
      data: (locs) {
        if (locs.isEmpty) return _emptyPreviewCard('Chưa có địa điểm draft.');
        return Column(
          children: locs.take(5).map((loc) => _AppStylePreviewCard(
            imageUrl: loc.image,
            title: loc.name,
            description: '${loc.categoryDisplay} • ${loc.address}',
            badge: loc.categoryDisplay,
            badgeColor: Colors.orange,
            onApprove: () => _approveLocation(loc),
          )).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _emptyPreviewCard('Lỗi: $e'),
    );
  }

  Widget _buildReviewDraftPreviewCards() {
    final asyncReviews = ref.watch(pendingDraftReviewsProvider);
    return asyncReviews.when(
      data: (reviews) {
        if (reviews.isEmpty) return _emptyPreviewCard('Chưa có bài viết draft.');
        return Column(
          children: reviews.take(3).map((review) => _AppStylePreviewCard(
            imageUrl: review.heroImage,
            title: review.title,
            description: review.aiSummary ?? review.fullText,
            badge: 'Bài viết',
            badgeColor: Colors.green,
          )).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _emptyPreviewCard('Lỗi: $e'),
    );
  }

  Widget _emptyPreviewCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildPendingTab(AiContentState aiState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPendingSection<Destination>(
            title: '📍 Điểm đến chờ duyệt',
            provider: pendingDestinationsProvider,
            itemBuilder: (dest) => _PendingCard(
              title: dest.name,
              subtitle: dest.description,
              imageUrl: dest.heroImage,
              highlighted: false,
              onApprove: () => _approveDestination(dest),
              onReject: () => _rejectDestination(dest.id),
            ),
          ),
          const SizedBox(height: 24),
          _buildPendingSection<Location>(
            title: '📌 Địa điểm chờ duyệt',
            provider: pendingLocationsProvider,
            itemBuilder: (loc) => _PendingCard(
              title: loc.name,
              subtitle:
                  '${loc.resolvedDestinationName} • ${loc.categoryDisplay}',
              imageUrl: loc.image,
              highlighted: aiState.highlightedLocationIds.contains(loc.id),
              onApprove: () => _approveLocation(loc),
              onReject: () => _rejectLocation(loc.id),
            ),
          ),
          const SizedBox(height: 24),
          _buildReviewDraftSection(aiState),
          const SizedBox(height: 24),
          _buildPendingSection<Review>(
            title: '📝 Bài viết chờ duyệt',
            provider: pendingPreviewReviewsProvider,
            itemBuilder: (review) => _ReviewPreviewCard(
              review: review,
              locationLabels: {
                for (final location
                    in ref.watch(adminLocationLookupProvider).asData?.value ??
                        const <Location>[])
                  location.id: location.name,
              },
              highlighted: aiState.highlightedReviewIds.contains(review.id),
              onOpenPreview: () => _showReviewPreviewDialog(review),
              onPublish: () => _publishReview(review),
              onReject: () => _rejectReview(review.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection<T>({
    required String title,
    required FutureProvider<List<T>> provider,
    required Widget Function(T item) itemBuilder,
  }) {
    final asyncData = ref.watch(provider);
    final resolvedTitle = identical(provider, pendingPreviewReviewsProvider)
        ? '📰 Bài viết preview'
        : title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        asyncData.when(
          data: (items) {
            return Row(
              children: [
                Text(
                  '$resolvedTitle (${items.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (items.length > 1)
                  TextButton.icon(
                    onPressed: () => _bulkApproveAll(provider),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Duyệt tất cả'),
                  ),
              ],
            );
          },
          loading: () => Text(
            resolvedTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          error: (_, __) => Text(
            resolvedTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        asyncData.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Không có nội dung chờ duyệt',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(children: items.map(itemBuilder).toList());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Lỗi: $error'),
        ),
      ],
    );
  }

  Widget _buildReviewDraftSection(AiContentState aiState) {
    final draftsAsync = ref.watch(pendingDraftReviewsProvider);
    final locationMap = {
      for (final location
          in ref.watch(adminLocationLookupProvider).asData?.value ??
              const <Location>[])
        location.id: location.name,
    };

    return _buildReviewSection(
      title: '🧠 Ý tưởng bài viết',
      asyncReviews: draftsAsync,
      emptyMessage: 'Chưa có ý tưởng bài viết AI chờ duyệt.',
      itemBuilder: (review) => _ReviewDraftCard(
        review: review,
        locationLabels: locationMap,
        highlighted: aiState.highlightedReviewIds.contains(review.id),
        onOpenDetails: () => _showReviewPreviewDialog(review),
        onCreatePreview: () => _expandReviewDraft(review),
        onReject: () => _rejectReview(review.id),
      ),
    );
  }

  Widget _buildReviewPreviewSection(AiContentState aiState) {
    final previewsAsync = ref.watch(pendingPreviewReviewsProvider);
    final locationMap = {
      for (final location
          in ref.watch(adminLocationLookupProvider).asData?.value ??
              const <Location>[])
        location.id: location.name,
    };

    return _buildReviewSection(
      title: '📰 Bài viết preview',
      asyncReviews: previewsAsync,
      emptyMessage: 'Chưa có bài viết preview chờ xuất bản.',
      itemBuilder: (review) => _ReviewPreviewCard(
        review: review,
        locationLabels: locationMap,
        highlighted: aiState.highlightedReviewIds.contains(review.id),
        onOpenPreview: () => _showReviewPreviewDialog(review),
        onPublish: () => _publishReview(review),
        onReject: () => _rejectReview(review.id),
      ),
    );
  }

  Widget _buildReviewSection({
    required String title,
    required AsyncValue<List<Review>> asyncReviews,
    required String emptyMessage,
    required Widget Function(Review review) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        asyncReviews.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              );
            }

            return Column(children: reviews.map(itemBuilder).toList());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Lỗi: $error'),
        ),
      ],
    );
  }

  Widget _buildAiHealthBadge(
    AsyncValue<AiBackendHealth?> healthAsync,
    AiContentState aiState,
  ) {
    return healthAsync.when(
      loading: () => _healthChip(
        icon: Icons.autorenew_rounded,
        text: 'AI đang kiểm tra kết nối',
        background: const Color(0xFFE0E7FF),
        foreground: const Color(0xFF4338CA),
      ),
      error: (_, __) => _healthChip(
        icon: Icons.wifi_off_rounded,
        text: 'AI offline • chế độ dự phòng',
        background: const Color(0xFFFEF3C7),
        foreground: const Color(0xFF92400E),
      ),
      data: (health) {
        final isOnline = health?.isOnline ?? false;
        final label = isOnline ? 'AI Online' : 'AI Offline';
        return _healthChip(
          icon: isOnline ? Icons.bolt_rounded : Icons.cloud_off_rounded,
          text: label,
          background: isOnline
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFFEF3C7),
          foreground: isOnline
              ? const Color(0xFF166534)
              : const Color(0xFF92400E),
        );
      },
    );
  }

  Widget _healthChip({
    required IconData icon,
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoPackCard(AiContentState aiState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                'Tạo gói demo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sinh 5 địa điểm và 3 bài viết AI draft cho ${_selectedDestinationName ?? 'điểm đến đã chọn'}.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: aiState.isGenerating ? null : _onGenerateDemoPack,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Tạo 5 địa điểm + 3 bài viết'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoPackStepper(AiContentState aiState) {
    Widget step({
      required String title,
      required bool active,
      required bool done,
    }) {
      final color = done || active
          ? const Color(0xFF6366F1)
          : const Color(0xFFCBD5E1);
      return Expanded(
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: done || active ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: Icon(
                done ? Icons.check : Icons.circle,
                size: done ? 16 : 10,
                color: done || active ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final current = aiState.demoPackStep;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          step(
            title: 'Đang tạo địa điểm',
            active: current == DemoPackStep.locations,
            done:
                current == DemoPackStep.reviews ||
                current == DemoPackStep.completed,
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
          step(
            title: 'Đang tạo bài viết',
            active: current == DemoPackStep.reviews,
            done: current == DemoPackStep.completed,
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
          step(
            title: 'Hoàn tất',
            active: current == DemoPackStep.completed,
            done: current == DemoPackStep.completed,
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, String value, IconData icon) {
    final selected = _generateType == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _generateType = value;
        if (value != 'review') {
          _selectedReviewLocationIds.clear();
        }
        _promptController.text = _getDefaultPrompt();
      }),
    );
  }

  Widget _styleChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _articleStyle == value,
      onSelected: (_) => setState(() => _articleStyle = value),
    );
  }

  Widget _buildDestinationSelector() {
    final destinations = ref
        .watch(adminDestinationLookupProvider)
        .asData
        ?.value;
    if (destinations == null) {
      return const LinearProgressIndicator();
    }

    final selectable =
        destinations
            .where((d) => d.status == 'published' || d.status == 'draft_ai')
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    // Auto-select random destination if none selected yet
    if (!_autoSelectedDone && _selectedDestinationId == null && selectable.isNotEmpty) {
      _autoSelectedDone = true;
      final random = (selectable.toList()..shuffle()).first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedDestinationId = random.id;
            _selectedDestinationName = random.name;
            _promptController.text = _getDefaultPrompt();
          });
        }
      });
    }

    return DropdownButtonFormField<String>(
      value: _selectedDestinationId,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: const Text('Chọn điểm đến...'),
      items: selectable
          .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        final dest = selectable.firstWhere((d) => d.id == value);
        setState(() {
          _selectedDestinationId = value;
          _selectedDestinationName = dest.name;
          _selectedReviewLocationIds.clear();
          _promptController.text = _getDefaultPrompt();
        });
      },
    );
  }

  Widget _buildReviewLocationSelector() {
    final destinationId = _selectedDestinationId;
    if (destinationId == null) {
      return const SizedBox.shrink();
    }

    final locationsAsync = ref.watch(adminLocationLookupProvider);
    return locationsAsync.when(
      data: (locations) {
        final eligible =
            locations
                .where(
                  (location) =>
                      location.destinationId == destinationId &&
                      (location.status == 'published' ||
                          location.status == 'draft_ai'),
                )
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: eligible.map((location) {
            final selected = _selectedReviewLocationIds.contains(location.id);
            return FilterChip(
              label: Text('${location.categoryEmoji} ${location.name}'),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  if (selected) {
                    _selectedReviewLocationIds.remove(location.id);
                  } else {
                    _selectedReviewLocationIds.add(location.id);
                  }
                });
              },
            );
          }).toList(),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('Không tải được địa điểm: $error'),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String text,
    required Color background,
    required Color border,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
    );
  }

  String _getHintText() {
    switch (_generateType) {
      case 'destination':
        return 'Ví dụ: Điểm đến biển sôi động, nhiều trải nghiệm, hợp nhóm bạn trẻ.';
      case 'location':
        return 'Ví dụ: Top quán cà phê có ảnh đẹp, dễ demo bản đồ và review.';
      case 'review':
        return 'Ví dụ: Viết review 1 ngày, giọng văn tự nhiên, nhắc đến các điểm nổi bật.';
      default:
        return '';
    }
  }

  String _getDefaultPrompt() {
    final destName = _selectedDestinationName ?? 'điểm đến nổi bật';
    switch (_generateType) {
      case 'destination':
        return 'Tạo điểm đến du lịch hấp dẫn tại Việt Nam, có bãi biển, nhiều trải nghiệm cho nhóm bạn trẻ và gia đình.';
      case 'location':
        return 'Tạo danh sách địa điểm nổi bật tại $destName bao gồm chùa, cà phê, bãi biển, tham quan. Nội dung ngắn gọn, giàu tính khám phá.';
      case 'review':
        return 'Viết bài review du lịch $destName, giọng văn tự nhiên và chân thực, nhắc đến ẩm thực, cảnh đẹp và trải nghiệm đặc sắc nhất.';
      default:
        return '';
    }
  }

  void _applyPreset(String preset) {
    final destinationName = _selectedDestinationName ?? 'điểm đến đã chọn';
    final prompt = switch (_generateType) {
      'destination' =>
        'Tạo nội dung theo preset "$preset" cho một điểm đến nổi bật, trình bày hấp dẫn và dễ demo.',
      'location' =>
        'Tạo danh sách địa điểm cho $destinationName theo preset "$preset", nội dung ngắn gọn và giàu tính khám phá.',
      'review' =>
        'Viết bài cho $destinationName theo preset "$preset", giọng văn tự nhiên, nhiều thông tin và gây ấn tượng khi demo.',
      _ => preset,
    };

    _promptController
      ..text = prompt
      ..selection = TextSelection.collapsed(offset: prompt.length);
  }

  void _onGenerate() {
    var prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      prompt = _getDefaultPrompt();
      _promptController.text = prompt;
    }

    final notifier = ref.read(aiContentNotifierProvider.notifier);
    switch (_generateType) {
      case 'destination':
        notifier.generateDestination(prompt);
        break;
      case 'location':
        if (_selectedDestinationId == null ||
            _selectedDestinationName == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn điểm đến')),
          );
          return;
        }
        notifier.generateLocations(
          destinationId: _selectedDestinationId!,
          destinationName: _selectedDestinationName!,
          prompt: prompt,
          count: _locationCount,
        );
        break;
      case 'review':
        if (_selectedDestinationId == null ||
            _selectedDestinationName == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Vui lòng chọn điểm đến trước khi tạo bài viết AI',
              ),
            ),
          );
          return;
        }
        if (_reviewCount > 1) {
          notifier.generateMultipleReviews(
            prompt: prompt,
            destinationId: _selectedDestinationId!,
            destinationName: _selectedDestinationName!,
            articleStyle: _articleStyle,
            focusLocationIds: _selectedReviewLocationIds,
            count: _reviewCount,
          );
        } else {
          notifier.generateReview(
            prompt: prompt,
            destinationId: _selectedDestinationId,
            destinationName: _selectedDestinationName,
            articleStyle: _articleStyle,
            focusLocationIds: _selectedReviewLocationIds,
          );
        }
        break;
    }
  }

  void _onGenerateDemoPack() {
    if (_selectedDestinationId == null || _selectedDestinationName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn điểm đến để tạo gói demo')),
      );
      return;
    }

    ref
        .read(aiContentNotifierProvider.notifier)
        .generateDemoPack(
          destinationId: _selectedDestinationId!,
          destinationName: _selectedDestinationName!,
          prompt: _promptController.text.trim(),
        );
  }

  Future<void> _bulkApproveAll<T>(FutureProvider<List<T>> provider) async {
    final items = ref.read(provider).value ?? [];
    if (items.isEmpty) return;

    final notifier = ref.read(aiContentNotifierProvider.notifier);
    var count = 0;
    for (final item in items) {
      if (item is Destination) {
        await notifier.approveDestination(item);
        count++;
      } else if (item is Location) {
        await notifier.approveLocation(item);
        count++;
      } else if (item is Review) {
        await notifier.publishReview(item);
        count++;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã duyệt $count mục')));
  }

  void _showPreviewDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReviewPreviewDialog(Review review) {
    final locationLabels = {
      for (final location
          in ref.read(adminLocationLookupProvider).asData?.value ??
              const <Location>[])
        location.id: location.name,
    };

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960, maxHeight: 760),
          child: _AdminReviewPreviewDialog(
            review: review,
            locationLabels: locationLabels,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );
  }

  Future<void> _approveDestination(Destination dest) async {
    await ref.read(aiContentNotifierProvider.notifier).approveDestination(dest);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã duyệt: ${dest.name}')));
  }

  Future<void> _rejectDestination(String id) async {
    await ref.read(aiContentNotifierProvider.notifier).rejectDestination(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
  }

  Future<void> _approveLocation(Location loc) async {
    await ref.read(aiContentNotifierProvider.notifier).approveLocation(loc);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã duyệt: ${loc.name}')));
  }

  Future<void> _rejectLocation(String id) async {
    await ref.read(aiContentNotifierProvider.notifier).rejectLocation(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
  }

  Future<void> _expandReviewDraft(Review review) async {
    await ref
        .read(aiContentNotifierProvider.notifier)
        .expandReviewDraft(review);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã duyệt: ${review.title}')));
  }

  Future<void> _publishReview(Review review) async {
    await ref.read(aiContentNotifierProvider.notifier).publishReview(review);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã xuất bản: ${review.title}')));
  }

  Future<void> _rejectReview(String id) async {
    await ref.read(aiContentNotifierProvider.notifier).rejectReview(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.highlighted,
    required this.onApprove,
    required this.onReject,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final bool highlighted;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted
                ? const Color(0xFF6366F1)
                : Colors.orange.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _thumbnail(imageUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: onReject,
                        child: const Text('Từ chối'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onApprove,
                        child: const Text('Duyệt'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholderImage(),
            )
          : _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.image_outlined),
    );
  }
}

class _ReviewDraftCard extends StatelessWidget {
  const _ReviewDraftCard({
    required this.review,
    required this.locationLabels,
    required this.highlighted,
    required this.onOpenDetails,
    required this.onCreatePreview,
    required this.onReject,
  });

  final Review review;
  final Map<String, String> locationLabels;
  final bool highlighted;
  final VoidCallback onOpenDetails;
  final VoidCallback onCreatePreview;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final outline = review.aiOutline.take(4).toList();
    final summary = review.aiSummary?.trim().isNotEmpty == true
        ? review.aiSummary!.trim()
        : review.fullText.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF6366F1)
              : const Color(0xFFE2E8F0),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StageChip(
                icon: Icons.auto_awesome_rounded,
                text: 'Ý tưởng AI',
                background: const Color(0xFFEDE9FE),
                foreground: const Color(0xFF6D28D9),
              ),
              const SizedBox(width: 8),
              if (review.destinationName?.isNotEmpty == true)
                _StageChip(
                  icon: Icons.place_outlined,
                  text: review.destinationName!,
                  background: const Color(0xFFF8FAFC),
                  foreground: const Color(0xFF475569),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            review.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF475569),
              ),
            ),
          ],
          if (review.aiAngle?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Góc bài: ${review.aiAngle!.trim()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
          if (outline.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Outline đề xuất',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            ...outline.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 7,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (review.relatedLocationIds.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReviewLocationChipWrap(
              locationIds: review.relatedLocationIds,
              locationLabels: locationLabels,
            ),
          ],
          if (review.sourceReferences.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReviewSourceList(references: review.sourceReferences, maxItems: 3),
          ],
          if (review.heroImageCandidates.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReviewImageStrip(candidates: review.heroImageCandidates),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              TextButton.icon(
                onPressed: onOpenDetails,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Xem chi tiết'),
              ),
              OutlinedButton(onPressed: onReject, child: const Text('Từ chối')),
              FilledButton.icon(
                onPressed: onCreatePreview,
                icon: const Icon(Icons.article_outlined),
                label: const Text('Tạo preview'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewPreviewCard extends StatelessWidget {
  const _ReviewPreviewCard({
    required this.review,
    required this.locationLabels,
    required this.highlighted,
    required this.onOpenPreview,
    required this.onPublish,
    required this.onReject,
  });

  final Review review;
  final Map<String, String> locationLabels;
  final bool highlighted;
  final VoidCallback onOpenPreview;
  final VoidCallback onPublish;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final excerpt = review.aiSummary?.trim().isNotEmpty == true
        ? review.aiSummary!.trim()
        : review.fullText.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF6366F1)
              : const Color(0xFFE2E8F0),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeroImage(imageUrl: review.heroImage),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _StageChip(
                      icon: Icons.visibility_outlined,
                      text: 'Preview AI',
                      background: Color(0xFFDCFCE7),
                      foreground: Color(0xFF166534),
                    ),
                    const SizedBox(width: 8),
                    _StageChip(
                      icon: Icons.link_outlined,
                      text: '${review.sourceReferences.length} nguồn',
                      background: const Color(0xFFF8FAFC),
                      foreground: const Color(0xFF475569),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  review.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (excerpt.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    excerpt,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
                if (review.relatedLocationIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ReviewLocationChipWrap(
                    locationIds: review.relatedLocationIds,
                    locationLabels: locationLabels,
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    TextButton.icon(
                      onPressed: onOpenPreview,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Mở preview'),
                    ),
                    OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Từ chối'),
                    ),
                    FilledButton.icon(
                      onPressed: onPublish,
                      icon: const Icon(Icons.publish_rounded),
                      label: const Text('Xuất bản'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReviewPreviewDialog extends StatelessWidget {
  const _AdminReviewPreviewDialog({
    required this.review,
    required this.locationLabels,
    required this.onClose,
  });

  final Review review;
  final Map<String, String> locationLabels;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final heroImage = review.heroImage.isNotEmpty
        ? review.heroImage
        : (review.heroImageCandidates.isNotEmpty
              ? review.heroImageCandidates.first.imageUrl
              : '');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.isAiDraft
                      ? 'Duyệt ý tưởng bài viết'
                      : 'Preview bài viết AI',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heroImage.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 2.2,
                      child: Image.network(
                        heroImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.image_outlined, size: 48),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StageChip(
                      icon: review.isAiDraft
                          ? Icons.edit_note_rounded
                          : Icons.visibility_outlined,
                      text: review.isAiDraft ? 'Draft AI' : 'Preview AI',
                      background: review.isAiDraft
                          ? const Color(0xFFEDE9FE)
                          : const Color(0xFFDCFCE7),
                      foreground: review.isAiDraft
                          ? const Color(0xFF6D28D9)
                          : const Color(0xFF166534),
                    ),
                    if (review.destinationName?.isNotEmpty == true)
                      _StageChip(
                        icon: Icons.place_outlined,
                        text: review.destinationName!,
                        background: const Color(0xFFF8FAFC),
                        foreground: const Color(0xFF475569),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  review.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                if (review.aiSummary?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    review.aiSummary!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
                if (review.aiAngle?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Góc bài: ${review.aiAngle}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
                if (review.relatedLocationIds.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _SectionTitle(text: 'Địa điểm liên quan'),
                  const SizedBox(height: 10),
                  _ReviewLocationChipWrap(
                    locationIds: review.relatedLocationIds,
                    locationLabels: locationLabels,
                  ),
                ],
                if (review.aiOutline.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionTitle(text: 'Outline AI'),
                  const SizedBox(height: 10),
                  ...review.aiOutline.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(
                              Icons.circle,
                              size: 7,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (review.fullText.trim().isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionTitle(
                    text: review.isAiDraft
                        ? 'Nội dung nháp'
                        : 'Bài viết preview',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: MarkdownBody(
                      data: review.fullText,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: Color(0xFF1E293B),
                        ),
                        h1: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                        h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          height: 1.4,
                        ),
                        h3: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                          height: 1.4,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        em: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF475569),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border(
                            left: BorderSide(
                              color: const Color(0xFF8B5CF6),
                              width: 3,
                            ),
                          ),
                        ),
                        listBullet: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ),
                ],
                if (review.sourceReferences.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionTitle(text: 'Nguồn tham khảo AI'),
                  const SizedBox(height: 10),
                  _ReviewSourceList(references: review.sourceReferences),
                ],
                if (review.heroImageCandidates.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionTitle(text: 'Ảnh web gợi ý'),
                  const SizedBox(height: 10),
                  _ReviewImageStrip(candidates: review.heroImageCandidates),
                ],
                if (review.heroImageSourceUrl?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Nguồn ảnh bìa: ${review.heroImageSourceUrl}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeroImage extends StatelessWidget {
  const _PreviewHeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 140,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: 140,
      height: 140,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.image_outlined, size: 36),
    );
  }
}

class _ReviewLocationChipWrap extends StatelessWidget {
  const _ReviewLocationChipWrap({
    required this.locationIds,
    required this.locationLabels,
  });

  final List<String> locationIds;
  final Map<String, String> locationLabels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: locationIds
          .map(
            (id) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                locationLabels[id] ?? id,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReviewSourceList extends StatelessWidget {
  const _ReviewSourceList({required this.references, this.maxItems});

  final List<dynamic> references;
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final items = maxItems == null
        ? references
        : references.take(maxItems!).toList();

    return Column(
      children: items.map((reference) {
        final title = reference.title as String;
        final url = reference.url as String;
        final domain = reference.domain as String?;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                domain?.isNotEmpty == true ? '$domain • $url' : url,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewImageStrip extends StatelessWidget {
  const _ReviewImageStrip({required this.candidates});

  final List<dynamic> candidates;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: candidates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final candidate = candidates[index];
          final imageUrl = candidate.imageUrl as String;
          final sourceUrl = candidate.sourceUrl as String;
          return Container(
            width: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.image_outlined),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.black.withValues(alpha: 0.42),
                      child: Text(
                        sourceUrl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Simulates how an AI draft looks in the real app.
class _AppStylePreviewCard extends StatelessWidget {
  const _AppStylePreviewCard({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    this.onApprove,
  });

  final String imageUrl;
  final String title;
  final String description;
  final String badge;
  final Color badgeColor;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image with gradient overlay
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  )
                else
                  _placeholderImage(),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Draft status
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'AI Draft',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Title on image
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black45),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                if (onApprove != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Duyệt & Xuất bản'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: BorderSide(color: Colors.green[300]!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Chưa có ảnh',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
