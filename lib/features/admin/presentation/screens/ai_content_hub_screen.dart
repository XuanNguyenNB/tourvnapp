import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_ai_content_provider.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../review/domain/entities/review.dart';
import '../providers/admin_destination_provider.dart';

/// Admin screen for AI content generation and review.
///
/// Two main sections:
/// 1. Generate: Input prompt to generate content via Gemini AI
/// 2. Pending Review: View, edit, approve, or reject AI-generated drafts
class AiContentHubScreen extends ConsumerStatefulWidget {
  const AiContentHubScreen({super.key});

  @override
  ConsumerState<AiContentHubScreen> createState() => _AiContentHubScreenState();
}

class _AiContentHubScreenState extends ConsumerState<AiContentHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _promptController = TextEditingController();
  String _generateType = 'destination'; // 'destination', 'location', 'review'

  // For location/review: select parent destination
  String? _selectedDestinationId;
  String? _selectedDestinationName;
  int _locationCount = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 24, 36, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
                const SizedBox(width: 12),
                const Text(
                  'AI Content',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Tab bar
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 18),
                        SizedBox(width: 6),
                        Text('Tạo nội dung'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pending_actions, size: 18),
                        SizedBox(width: 6),
                        Text('Chờ duyệt'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildGenerateTab(aiState), _buildPendingTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ── GENERATE TAB ────────────────────────────────────────

  Widget _buildGenerateTab(AiContentState aiState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type selector
          Text(
            'Loại nội dung',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _typeChip('Điểm đến', 'destination', Icons.map),
              _typeChip('Địa điểm', 'location', Icons.place),
              _typeChip('Bài viết', 'review', Icons.article),
            ],
          ),

          const SizedBox(height: 20),

          // Destination selector (for locations / reviews)
          if (_generateType != 'destination') ...[
            Text(
              'Thuộc điểm đến',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildDestinationSelector(),
            const SizedBox(height: 20),
          ],

          // Count selector (for locations)
          if (_generateType == 'location') ...[
            Text(
              'Số lượng',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [3, 5, 10].map((n) {
                final selected = _locationCount == n;
                return ChoiceChip(
                  label: Text('$n'),
                  selected: selected,
                  onSelected: (_) => setState(() => _locationCount = n),
                  selectedColor: const Color(
                    0xFF6366F1,
                  ).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF6366F1),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Prompt
          Text(
            'Mô tả yêu cầu',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _getHintText(),
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
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
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Generate button
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
              label: Text(
                aiState.isGenerating ? 'Đang tạo...' : 'Tạo bằng AI',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Success / Error feedback
          if (aiState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiState.error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (aiState.lastGeneratedType != null && !aiState.isGenerating) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Đã tạo ${aiState.generatedCount} ${_typeLabel(aiState.lastGeneratedType!)} thành công! Chuyển sang tab "Chờ duyệt" để xem.',
                    style: TextStyle(color: Colors.green[700], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
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
      onSelected: (_) => setState(() => _generateType = value),
      selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF6366F1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? const Color(0xFF6366F1) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildDestinationSelector() {
    final destsAsync = ref.watch(adminDestinationProvider);

    if (destsAsync.isInitialLoading) {
      return const LinearProgressIndicator();
    }

    if (destsAsync.error != null) {
      return Text('Lỗi: ${destsAsync.error}');
    }

    final dests = destsAsync.items;

    return DropdownButtonFormField<String>(
      value: _selectedDestinationId,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      hint: const Text('Chọn điểm đến...'),
      items: dests
          .where((d) => d.status == 'published')
          .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
          .toList(),
      onChanged: (val) {
        final dest = dests.firstWhere((d) => d.id == val);
        setState(() {
          _selectedDestinationId = val;
          _selectedDestinationName = dest.name;
        });
      },
    );
  }

  String _getHintText() {
    switch (_generateType) {
      case 'destination':
        return 'VD: Ninh Bình - Tràng An, Bái Đính';
      case 'location':
        return 'VD: Top quán cà phê view đẹp ở Đà Lạt';
      case 'review':
        return 'VD: Review 3 ngày 2 đêm ở Phú Quốc';
      default:
        return '';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'destination':
        return 'điểm đến';
      case 'location':
        return 'địa điểm';
      case 'review':
        return 'bài viết';
      default:
        return type;
    }
  }

  void _onGenerate() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final notifier = ref.read(aiContentNotifierProvider.notifier);

    switch (_generateType) {
      case 'destination':
        notifier.generateDestination(prompt);
        break;
      case 'location':
        if (_selectedDestinationId == null) {
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
        notifier.generateReview(
          prompt: prompt,
          destinationId: _selectedDestinationId,
          destinationName: _selectedDestinationName,
        );
        break;
    }
  }

  // ── PENDING REVIEW TAB ─────────────────────────────────

  Widget _buildPendingTab() {
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
              onApprove: () => _approveLocation(loc),
              onReject: () => _rejectLocation(loc.id),
            ),
          ),
          const SizedBox(height: 24),
          _buildPendingSection<Review>(
            title: '📝 Bài viết chờ duyệt',
            provider: pendingReviewsProvider,
            itemBuilder: (review) => _PendingCard(
              title: review.title,
              subtitle: review.fullText.length > 100
                  ? '${review.fullText.substring(0, 100)}...'
                  : review.fullText,
              imageUrl: review.heroImage,
              onApprove: () => _approveReview(review),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          error: (e, _) => Text('Lỗi: $e'),
        ),
      ],
    );
  }

  void _approveDestination(Destination dest) async {
    await ref.read(aiContentNotifierProvider.notifier).approveDestination(dest);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã duyệt: ${dest.name}')));
    }
  }

  void _rejectDestination(String id) async {
    await ref.read(aiContentNotifierProvider.notifier).rejectDestination(id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
    }
  }

  void _approveLocation(Location loc) async {
    await ref.read(aiContentNotifierProvider.notifier).approveLocation(loc);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã duyệt: ${loc.name}')));
    }
  }

  void _rejectLocation(String id) async {
    await ref.read(aiContentNotifierProvider.notifier).rejectLocation(id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
    }
  }

  void _approveReview(Review review) async {
    await ref.read(aiContentNotifierProvider.notifier).approveReview(review);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã duyệt: ${review.title}')));
    }
  }

  void _rejectReview(String id) async {
    await ref.read(aiContentNotifierProvider.notifier).rejectReview(id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
    }
  }
}

// ── Pending Item Card Widget ─────────────────────────────

class _PendingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image thumbnail
            ClipRRect(
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
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AI Draft',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Action buttons
            Column(
              children: [
                IconButton(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: 'Duyệt',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                IconButton(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'Từ chối',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 24, color: Colors.grey),
    );
  }
}
