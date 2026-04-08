import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../destination/domain/entities/category.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../review/domain/entities/review.dart';
import '../providers/admin_category_provider.dart';
import '../providers/admin_reference_data_provider.dart';
import '../providers/admin_review_provider.dart';
import '../providers/admin_stats_provider.dart';

class ReviewFormDialog extends ConsumerStatefulWidget {
  const ReviewFormDialog({super.key, this.review});

  final Review? review;

  @override
  ConsumerState<ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends ConsumerState<ReviewFormDialog> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _heroImageController;
  late final TextEditingController _authorController;
  late final TextEditingController _contentController;

  late DateTime _selectedDate;
  String _generatedId = '';
  String? _selectedDestinationId;
  String? _selectedCategory;
  final Set<String> _selectedLocationIds = <String>{};

  bool _isSaving = false;
  bool _isDirty = false;
  String? _saveError;

  String _generateId() => _uuid.v4().replaceAll('-', '').substring(0, 20);

  @override
  void initState() {
    super.initState();
    final review = widget.review;
    _titleController = TextEditingController(text: review?.title ?? '');
    _heroImageController = TextEditingController(text: review?.heroImage ?? '');
    _authorController = TextEditingController(
      text: review?.authorName ?? 'Quản trị viên',
    );
    _contentController = TextEditingController(text: review?.fullText ?? '');
    _selectedDate = review?.createdAt ?? DateTime.now();
    _generatedId = review?.id ?? _generateId();
    _selectedDestinationId = review?.destinationId;
    _selectedCategory = review?.category;
    _selectedLocationIds.addAll(review?.relatedLocationIds ?? const <String>[]);

    for (final controller in [
      _titleController,
      _heroImageController,
      _authorController,
      _contentController,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _titleController,
      _heroImageController,
      _authorController,
      _contentController,
    ]) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (_isDirty) return;
    setState(() => _isDirty = true);
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Chọn ngày đăng',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      helpText: 'Chọn giờ đăng',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (!mounted) return;
    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _selectedDate.hour,
        time?.minute ?? _selectedDate.minute,
      );
      _isDirty = true;
    });
  }

  Future<void> _submit(
    List<Destination> destinations,
    List<Location> locations,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    Destination? selectedDestination;
    if (_selectedDestinationId != null) {
      for (final destination in destinations) {
        if (destination.id == _selectedDestinationId) {
          selectedDestination = destination;
          break;
        }
      }
    }

    if (_selectedLocationIds.isNotEmpty && selectedDestination == null) {
      setState(() {
        _saveError = 'Chọn điểm đến trước khi gắn địa điểm liên quan.';
      });
      return;
    }

    final invalidLocations = locations
        .where((location) => _selectedLocationIds.contains(location.id))
        .where(
          (location) =>
              _selectedDestinationId != null &&
              location.destinationId != _selectedDestinationId,
        )
        .toList();

    if (invalidLocations.isNotEmpty) {
      setState(() {
        _saveError =
            'Có địa điểm không thuộc điểm đến đã chọn: ${invalidLocations.first.name}.';
      });
      return;
    }

    final isEditing = widget.review != null;
    final review = Review(
      id: isEditing ? widget.review!.id : _generatedId,
      heroImage: _heroImageController.text.trim(),
      title: _titleController.text.trim(),
      authorId: widget.review?.authorId ?? 'admin',
      authorName: _authorController.text.trim(),
      authorAvatar: widget.review?.authorAvatar ?? '',
      fullText: _contentController.text.trim(),
      createdAt: _selectedDate,
      likeCount: widget.review?.likeCount ?? 0,
      commentCount: widget.review?.commentCount ?? 0,
      saveCount: widget.review?.saveCount ?? 0,
      relatedLocationIds: _selectedLocationIds.toList(),
      destinationId: selectedDestination?.id,
      destinationName: selectedDestination?.name,
      category: _selectedCategory,
      slug: Destination.generateId(_titleController.text.trim()),
      status: widget.review?.status ?? 'published',
    );

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final notifier = ref.read(adminReviewProvider.notifier);
      if (isEditing) {
        await notifier.updateReviewData(review);
      } else {
        await notifier.addReview(review);
      }
      ref.invalidate(adminStatsProvider);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isDirty = false;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Cập nhật bài viết thành công'
                : 'Thêm bài viết thành công',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.review != null;
    final destinations =
        ref.watch(adminDestinationLookupProvider).asData?.value ??
        const <Destination>[];
    final locations =
        ref.watch(adminLocationLookupProvider).asData?.value ??
        const <Location>[];
    final List<Category> categories =
        ref.watch(activeCategoriesProvider).asData?.value ?? const <Category>[];
    final availableLocations = _selectedDestinationId == null
        ? const <Location>[]
        : locations
              .where(
                (location) => location.destinationId == _selectedDestinationId,
              )
              .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 860),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Sửa Bài viết' : 'Thêm Bài viết',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel(
                          title: 'Thông tin chính',
                          subtitle:
                              'Tiêu đề, ảnh bìa và nội dung là phần hiển thị trực tiếp cho người dùng.',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Tiêu đề',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Vui lòng nhập tiêu đề';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.link,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ID: $_generatedId',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _heroImageController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Ảnh bìa (URL)',
                            hintText: 'Dán URL ảnh công khai',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final url = (value ?? '').trim();
                            if (url.isEmpty) {
                              return 'Vui lòng nhập URL ảnh';
                            }
                            if (!_isValidUrl(url)) {
                              return 'URL ảnh không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Firebase Storage đã được gỡ khỏi admin. Hãy dùng URL ảnh công khai từ CDN hoặc host ngoài.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_heroImageController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _heroImageController.text.trim(),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 90,
                                color: Colors.blueGrey.shade50,
                                alignment: Alignment.center,
                                child: Text(
                                  'Không tải được ảnh xem trước từ URL này.',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _authorController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Tên tác giả',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Vui lòng nhập tên tác giả';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _isSaving ? null : _pickDateTime,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Ngày đăng',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy • HH:mm',
                                  ).format(_selectedDate),
                                ),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentController,
                          enabled: !_isSaving,
                          maxLines: 10,
                          decoration: const InputDecoration(
                            labelText: 'Nội dung bài viết',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Vui lòng nhập nội dung';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const _SectionLabel(
                          title: 'Liên kết nội dung',
                          subtitle:
                              'Điểm đến và địa điểm liên quan phải khớp nhau để recommendation và admin moderation dùng lại được.',
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedDestinationId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Điểm đến',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Không chọn điểm đến'),
                            ),
                            ...destinations.map(
                              (destination) => DropdownMenuItem<String>(
                                value: destination.id,
                                child: Text(destination.name),
                              ),
                            ),
                          ],
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  final nextValue = (value ?? '').trim();
                                  setState(() {
                                    _selectedDestinationId = nextValue.isEmpty
                                        ? null
                                        : nextValue;
                                    _selectedLocationIds.removeWhere((
                                      locationId,
                                    ) {
                                      return locations
                                          .where(
                                            (location) =>
                                                location.id == locationId,
                                          )
                                          .any(
                                            (location) =>
                                                location.destinationId !=
                                                _selectedDestinationId,
                                          );
                                    });
                                    _isDirty = true;
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String?>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Không chọn danh mục'),
                            ),
                            ...categories.map(
                              (category) => DropdownMenuItem<String?>(
                                value: category.id,
                                child: Text(category.displayText),
                              ),
                            ),
                          ],
                          onChanged: _isSaving
                              ? null
                              : (value) => setState(() {
                                  _selectedCategory = value;
                                  _isDirty = true;
                                }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Địa điểm liên quan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedDestinationId == null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFCD34D),
                              ),
                            ),
                            child: const Text(
                              'Chọn điểm đến trước khi gắn địa điểm liên quan.',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else if (availableLocations.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              'Điểm đến này chưa có địa điểm để liên kết.',
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableLocations.map((location) {
                              final selected = _selectedLocationIds.contains(
                                location.id,
                              );
                              return FilterChip(
                                label: Text(location.name),
                                selected: selected,
                                onSelected: _isSaving
                                    ? null
                                    : (_) => setState(() {
                                        if (selected) {
                                          _selectedLocationIds.remove(
                                            location.id,
                                          );
                                        } else {
                                          _selectedLocationIds.add(location.id);
                                        }
                                        _isDirty = true;
                                      }),
                                selectedColor: const Color(0xFFEEF2FF),
                                checkmarkColor: const Color(0xFF4F46E5),
                              );
                            }).toList(),
                          ),
                        if (_saveError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Text(
                              _saveError!,
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isDirty && !_isSaving)
                      Text(
                        'Có thay đổi chưa lưu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (_isDirty && !_isSaving) const SizedBox(width: 12),
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _submit(destinations, locations),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(isEditing ? Icons.save_outlined : Icons.add),
                      label: Text(
                        _isSaving
                            ? 'Đang lưu...'
                            : isEditing
                            ? 'Lưu'
                            : 'Thêm',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
        ),
      ],
    );
  }
}
