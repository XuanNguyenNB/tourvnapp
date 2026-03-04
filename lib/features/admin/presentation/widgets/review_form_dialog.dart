import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../review/domain/entities/review.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../providers/admin_review_provider.dart';
import '../providers/admin_category_provider.dart';
import '../providers/admin_destination_provider.dart';
import '../providers/admin_location_provider.dart';
import '../../../../core/services/image_upload_service.dart';

class ReviewFormDialog extends ConsumerStatefulWidget {
  final Review? review;

  const ReviewFormDialog({super.key, this.review});

  @override
  ConsumerState<ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends ConsumerState<ReviewFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _heroImageController;
  late TextEditingController _authorNameController;
  late TextEditingController _fullTextController;
  late TextEditingController _destinationIdController;
  late TextEditingController _destinationNameController;

  // Added for Locations
  final List<String> _selectedLocationIds = [];
  final TextEditingController _locationInputController =
      TextEditingController();

  String _generatedId = '';
  String? _selectedCategory;
  late DateTime _selectedDate;

  bool _isUploading = false;
  double _uploadProgress = 0;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    final r = widget.review;
    _titleController = TextEditingController(text: r?.title ?? '');
    _heroImageController = TextEditingController(text: r?.heroImage ?? '');
    _authorNameController = TextEditingController(
      text: r?.authorName ?? 'Admin',
    );
    _fullTextController = TextEditingController(text: r?.fullText ?? '');
    _destinationIdController = TextEditingController(
      text: r?.destinationId ?? '',
    );
    _destinationNameController = TextEditingController(
      text: r?.destinationName ?? '',
    );
    _selectedCategory = r?.category;
    _selectedDate = r?.createdAt ?? DateTime.now();
    // Use Firestore autoId for new reviews; keep existing ID for edits
    _generatedId =
        r?.id ?? FirebaseFirestore.instance.collection('reviews').doc().id;

    if (r?.relatedLocationIds != null) {
      _selectedLocationIds.addAll(r!.relatedLocationIds);
    }

    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    // ID is now Firestore autoId — no longer regenerated from title.
    // Slug can be derived from title for SEO if needed.
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _heroImageController.dispose();
    _authorNameController.dispose();
    _fullTextController.dispose();
    _destinationIdController.dispose();
    _destinationNameController.dispose();
    _locationInputController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    // Use _generatedId as single source of truth
    final revId = _generatedId;

    if (revId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tiêu đề trước khi tải ảnh'),
        ),
      );
      return;
    }

    final image = await ImageUploadService.pickImage();
    if (image == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final url = await ImageUploadService.uploadReviewHero(
        image: image,
        reviewId: revId,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      if (mounted) {
        setState(() {
          _heroImageController.text = url;
          _previewBytes = image.bytes;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.review != null;
      // Use _generatedId consistently (same ID used for image upload)
      final id = isEditing ? widget.review!.id : _generatedId;

      final newReview = Review(
        id: id,
        title: _titleController.text.trim(),
        heroImage: _heroImageController.text.trim(),
        authorId: 'admin',
        authorName: _authorNameController.text.trim(),
        authorAvatar: '', // Removed from UI
        fullText: _fullTextController.text.trim(),
        createdAt: _selectedDate,
        likeCount: widget.review?.likeCount ?? 0,
        commentCount: widget.review?.commentCount ?? 0,
        saveCount: widget.review?.saveCount ?? 0,
        relatedLocationIds: _selectedLocationIds,
        destinationId: _destinationIdController.text.trim().isNotEmpty
            ? _destinationIdController.text.trim()
            : null,
        destinationName: _destinationNameController.text.trim().isNotEmpty
            ? _destinationNameController.text.trim()
            : null,
        category: _selectedCategory,
        slug: Destination.generateId(_titleController.text.trim()),
      );

      final notifier = ref.read(adminReviewProvider.notifier);
      try {
        if (!isEditing) {
          await notifier.addReview(newReview);
        } else {
          await notifier.updateReviewData(newReview);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                !isEditing
                    ? 'Thêm bài viết thành công!'
                    : 'Cập nhật bài viết thành công!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.review != null;

    // Watch providers for autocomplete options
    final destinationsAsync = ref.watch(adminDestinationProvider);
    final locationsAsync = ref.watch(adminLocationProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Sửa Bài viết' : 'Thêm Bài viết',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // TITLE + CATEGORY
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tiêu đề',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? 'Vui lòng nhập tiêu đề'
                                      : null,
                                ),
                                if (_generatedId.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.link,
                                          size: 16,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ID: ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        Text(
                                          _generatedId,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Consumer(
                              builder: (context, ref, _) {
                                final categoriesAsync = ref.watch(
                                  activeCategoriesProvider,
                                );
                                return categoriesAsync.when(
                                  data: (categories) =>
                                      DropdownButtonFormField<String?>(
                                        isExpanded: true,
                                        value: _selectedCategory,
                                        decoration: const InputDecoration(
                                          labelText: 'Danh mục',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Không'),
                                          ),
                                          ...categories.map(
                                            (cat) => DropdownMenuItem<String?>(
                                              value: cat.id,
                                              child: Text(cat.displayText),
                                            ),
                                          ),
                                        ],
                                        onChanged: (v) => setState(
                                          () => _selectedCategory = v,
                                        ),
                                      ),
                                  loading: () => const SizedBox(
                                    height: 56,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  error: (_, __) =>
                                      DropdownButtonFormField<String?>(
                                        isExpanded: true,
                                        value: _selectedCategory,
                                        decoration: const InputDecoration(
                                          labelText: 'Danh mục',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: const [
                                          DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Không'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'food',
                                            child: Text('🍜 Ăn uống'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'places',
                                            child: Text('📸 Điểm đến'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'stay',
                                            child: Text('🏨 Lưu trú'),
                                          ),
                                        ],
                                        onChanged: (v) => setState(
                                          () => _selectedCategory = v,
                                        ),
                                      ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // HERO IMAGE
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heroImageController,
                              decoration: InputDecoration(
                                labelText: 'Ảnh bìa (URL)',
                                hintText: 'Nhập URL hoặc tải ảnh lên',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.image_outlined),
                                suffixIcon: _heroImageController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _heroImageController.clear();
                                            _previewBytes = null;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Vui lòng nhập URL hoặc tải ảnh'
                                  : null,
                              onChanged: (_) => setState(() {
                                _previewBytes = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : _pickAndUploadImage,
                              icon: _isUploading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: _uploadProgress > 0
                                            ? _uploadProgress
                                            : null,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.upload_outlined, size: 18),
                              label: Text(
                                _isUploading
                                    ? '${(_uploadProgress * 100).toInt()}%'
                                    : 'Tải lên',
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Image preview
                      if (!_isUploading &&
                          _heroImageController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _previewBytes != null
                              ? Image.memory(
                                  _previewBytes!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _heroImageController.text,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 80,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Đã tải lên thành công\n(Hoặc khởi động lại trình duyệt nếu không thấy ảnh)',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // AUTHOR
                      TextFormField(
                        controller: _authorNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên tác giả',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 16),

                      // PUBLISH DATE
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            helpText: 'Chọn ngày đăng tải',
                            cancelText: 'Hủy',
                            confirmText: 'Chọn',
                          );
                          if (pickedDate != null && mounted) {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                _selectedDate,
                              ),
                              helpText: 'Chọn giờ đăng tải',
                              cancelText: 'Hủy',
                              confirmText: 'Chọn',
                            );
                            setState(() {
                              _selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime?.hour ?? _selectedDate.hour,
                                pickedTime?.minute ?? _selectedDate.minute,
                              );
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày đăng tải',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy – HH:mm',
                                ).format(_selectedDate),
                                style: const TextStyle(fontSize: 15),
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

                      // CONTENT
                      TextFormField(
                        controller: _fullTextController,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung bài viết (Hỗ trợ Markdown)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 10,
                        validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 16),

                      // DESTINATION AND LOCATION
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gắn thẻ (tùy chọn)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            // DESTINATION PICKER
                            if (destinationsAsync.isInitialLoading)
                              const LinearProgressIndicator()
                            else
                              Autocomplete<Destination>(
                                displayStringForOption: (d) => d.name,
                                optionsBuilder: (textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<Destination>.empty();
                                  }
                                  return destinationsAsync.items.where(
                                    (d) => d.name.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase(),
                                    ),
                                  );
                                },
                                onSelected: (d) {
                                  _destinationIdController.text = d.id;
                                  _destinationNameController.text = d.name;
                                },
                                fieldViewBuilder:
                                    (
                                      context,
                                      controller,
                                      focusNode,
                                      onEditingComplete,
                                    ) {
                                      // Sync with existing value
                                      if (controller.text.isEmpty &&
                                          _destinationNameController
                                              .text
                                              .isNotEmpty) {
                                        controller.text =
                                            _destinationNameController.text;
                                      }

                                      return TextFormField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Điểm đến (Tên, Tỉnh/Thành)',
                                          hintText:
                                              'Nhập để tìm hoặc gõ trực tiếp',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.map_outlined),
                                        ),
                                        onChanged: (val) {
                                          _destinationNameController.text = val;
                                          _destinationIdController.text =
                                              Destination.generateId(val);
                                        },
                                      );
                                    },
                              ),
                            const SizedBox(height: 16),

                            // LOCATION PICKER (Multiple)
                            if (locationsAsync.isInitialLoading)
                              const LinearProgressIndicator()
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Autocomplete<Location>(
                                    displayStringForOption: (l) => l.name,
                                    optionsBuilder: (textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<Location>.empty();
                                      }
                                      return locationsAsync.items.where(
                                        (l) => l.name.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        ),
                                      );
                                    },
                                    onSelected: (l) {
                                      if (!_selectedLocationIds.contains(
                                        l.id,
                                      )) {
                                        setState(() {
                                          _selectedLocationIds.add(l.id);
                                        });
                                      }
                                      _locationInputController.clear();
                                    },
                                    fieldViewBuilder:
                                        (
                                          context,
                                          controller,
                                          focusNode,
                                          onEditingComplete,
                                        ) {
                                          // We share the controller
                                          return TextFormField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            decoration: InputDecoration(
                                              labelText: 'Địa điểm cụ thể',
                                              hintText:
                                                  'Nhập để tìm hoặc gõ ID trực tiếp rồi Enter',
                                              border:
                                                  const OutlineInputBorder(),
                                              prefixIcon: const Icon(
                                                Icons.place_outlined,
                                              ),
                                              suffixIcon: IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  final val = controller.text
                                                      .trim();
                                                  if (val.isNotEmpty) {
                                                    // Use raw text as location ID
                                                    // (don't slugify - it may not match real IDs)
                                                    final id = val
                                                        .toLowerCase();
                                                    if (!_selectedLocationIds
                                                        .contains(id)) {
                                                      setState(() {
                                                        _selectedLocationIds
                                                            .add(id);
                                                      });
                                                    }
                                                    controller.clear();
                                                  }
                                                },
                                              ),
                                            ),
                                            onFieldSubmitted: (val) {
                                              if (val.trim().isNotEmpty) {
                                                // Use raw text as location ID
                                                final id = val
                                                    .trim()
                                                    .toLowerCase();
                                                if (!_selectedLocationIds
                                                    .contains(id)) {
                                                  setState(() {
                                                    _selectedLocationIds.add(
                                                      id,
                                                    );
                                                  });
                                                }
                                                controller.clear();
                                                focusNode.requestFocus();
                                              }
                                            },
                                          );
                                        },
                                  ),
                                  if (_selectedLocationIds.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: _selectedLocationIds.map((
                                        locId,
                                      ) {
                                        final locName =
                                            locationsAsync.items.any(
                                              (l) => l.id == locId,
                                            )
                                            ? locationsAsync.items
                                                  .firstWhere(
                                                    (l) => l.id == locId,
                                                  )
                                                  .name
                                            : locId;

                                        return Chip(
                                          label: Text(
                                            locName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          deleteIcon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedLocationIds.remove(
                                                locId,
                                              );
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(isEditing ? 'Lưu' : 'Thêm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
