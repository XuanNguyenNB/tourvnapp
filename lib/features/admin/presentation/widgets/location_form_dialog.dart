import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/category.dart';
import '../../../destination/domain/entities/location.dart';
import '../providers/admin_category_provider.dart';
import '../providers/admin_location_provider.dart';
import '../providers/admin_reference_data_provider.dart';
import '../providers/admin_stats_provider.dart';

class LocationFormDialog extends ConsumerStatefulWidget {
  const LocationFormDialog({super.key, this.location});

  final Location? location;

  @override
  ConsumerState<LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends ConsumerState<LocationFormDialog> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _imageController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _tagsController;
  late final TextEditingController _priceRangeController;
  late final TextEditingController _ratingController;

  String? _selectedDestinationId;
  String _selectedCategory = 'food';
  bool _isSaving = false;
  bool _isDirty = false;
  String? _saveError;

  String _generateId() => _uuid.v4().replaceAll('-', '').substring(0, 20);

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _idController = TextEditingController(text: location?.id ?? _generateId());
    _nameController = TextEditingController(text: location?.name ?? '');
    _imageController = TextEditingController(text: location?.image ?? '');
    _descriptionController = TextEditingController(
      text: location?.description ?? '',
    );
    _addressController = TextEditingController(text: location?.address ?? '');
    _latitudeController = TextEditingController(
      text: location?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: location?.longitude?.toString() ?? '',
    );
    _tagsController = TextEditingController(
      text: location?.tags.join(', ') ?? '',
    );
    _priceRangeController = TextEditingController(
      text: location?.priceRange ?? '',
    );
    _ratingController = TextEditingController(
      text: location?.rating?.toString() ?? '',
    );
    _selectedDestinationId = location?.destinationId;
    _selectedCategory = location?.category ?? 'food';

    for (final controller in [
      _nameController,
      _imageController,
      _descriptionController,
      _addressController,
      _latitudeController,
      _longitudeController,
      _tagsController,
      _priceRangeController,
      _ratingController,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _imageController,
      _descriptionController,
      _addressController,
      _latitudeController,
      _longitudeController,
      _tagsController,
      _priceRangeController,
      _ratingController,
    ]) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    _idController.dispose();
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

  String? _validateLatitude(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final latitude = double.tryParse(value!.trim());
    if (latitude == null) return 'Vĩ độ phải là số';
    if (latitude < -90 || latitude > 90) {
      return 'Vĩ độ phải từ -90 đến 90';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final longitude = double.tryParse(value!.trim());
    if (longitude == null) return 'Kinh độ phải là số';
    if (longitude < -180 || longitude > 180) {
      return 'Kinh độ phải từ -180 đến 180';
    }
    return null;
  }

  Future<void> _submit() async {
    final hasLatitude = _latitudeController.text.trim().isNotEmpty;
    final hasLongitude = _longitudeController.text.trim().isNotEmpty;
    if (hasLatitude != hasLongitude) {
      setState(() {
        _saveError = 'Vui lòng nhập đầy đủ cả vĩ độ và kinh độ.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDestinationId == null || _selectedDestinationId!.isEmpty) {
      setState(() {
        _saveError = 'Vui lòng chọn điểm đến hợp lệ.';
      });
      return;
    }

    final destinations =
        ref.read(adminDestinationLookupProvider).asData?.value ??
        const <Destination>[];
    final selectedDestination = destinations.firstWhere(
      (destination) => destination.id == _selectedDestinationId,
    );

    final location = Location(
      id: _idController.text.trim(),
      destinationId: _selectedDestinationId!,
      destinationName: selectedDestination.name,
      name: _nameController.text.trim(),
      image: _imageController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      latitude: double.tryParse(_latitudeController.text.trim()),
      longitude: double.tryParse(_longitudeController.text.trim()),
      tags: _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList(),
      priceRange: _priceRangeController.text.trim().isEmpty
          ? null
          : _priceRangeController.text.trim(),
      rating: double.tryParse(_ratingController.text.trim()),
      viewCount: widget.location?.viewCount ?? 0,
      saveCount: widget.location?.saveCount ?? 0,
      status: widget.location?.status ?? 'published',
      estimatedDurationMin: widget.location?.estimatedDurationMin,
      searchKeywords: widget.location?.searchKeywords ?? const [],
    );

    final notifier = ref.read(adminLocationProvider.notifier);
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      if (widget.location == null) {
        await notifier.addLocation(location);
      } else {
        await notifier.updateLocationData(location);
      }
      ref.invalidate(adminLocationLookupProvider);
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
            widget.location == null
                ? 'Thêm địa điểm thành công'
                : 'Cập nhật địa điểm thành công',
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
    final isEditing = widget.location != null;
    final destinations =
        ref.watch(adminDestinationLookupProvider).asData?.value ??
        const <Destination>[];
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final categories =
        categoriesAsync.asData?.value ?? Category.defaultCategories;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Sửa Địa điểm' : 'Thêm Địa điểm',
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
                              'Chọn đúng điểm đến cha trước khi nhập địa điểm con.',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _idController,
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: 'ID',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedDestinationId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Điểm đến',
                                  border: OutlineInputBorder(),
                                ),
                                items: destinations
                                    .map(
                                      (destination) => DropdownMenuItem(
                                        value: destination.id,
                                        child: Text(destination.name),
                                      ),
                                    )
                                    .toList(),
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Bắt buộc chọn điểm đến';
                                  }
                                  return null;
                                },
                                onChanged: _isSaving
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedDestinationId = value;
                                          _isDirty = true;
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Tên',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Vui lòng nhập tên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _imageController,
                                enabled: !_isSaving,
                                decoration: const InputDecoration(
                                  labelText: 'Ảnh (URL)',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final url = (value ?? '').trim();
                                  if (url.isEmpty) return 'Bắt buộc';
                                  if (!_isValidUrl(url)) {
                                    return 'URL ảnh không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Danh mục',
                                  border: OutlineInputBorder(),
                                ),
                                items: categories
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(category.displayText),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isSaving
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _selectedCategory = value;
                                          _isDirty = true;
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_isSaving,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Mô tả',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _SectionLabel(
                          title: 'Nâng cao',
                          subtitle:
                              'GPS, rating và tags phải đúng định dạng để recommendation và planner dùng lại được.',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tọa độ GPS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _latitudeController,
                                      enabled: !_isSaving,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                            signed: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Vĩ độ (-90 đến 90)',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: _validateLatitude,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _longitudeController,
                                      enabled: !_isSaving,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                            signed: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Kinh độ (-180 đến 180)',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: _validateLongitude,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceRangeController,
                                enabled: !_isSaving,
                                decoration: const InputDecoration(
                                  labelText: 'Mức giá',
                                  hintText: 'Ví dụ: \$\$',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _ratingController,
                                enabled: !_isSaving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Đánh giá (0-5)',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) return null;
                                  final rating = double.tryParse(value!.trim());
                                  if (rating == null) return 'Phải là số';
                                  if (rating < 0 || rating > 5) {
                                    return 'Phải từ 0 đến 5';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tagsController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Thẻ',
                            hintText: 'Cách nhau bởi dấu phẩy',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_saveError != null) ...[
                          const SizedBox(height: 12),
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
                const SizedBox(height: 20),
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
                      onPressed: _isSaving ? null : _submit,
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
