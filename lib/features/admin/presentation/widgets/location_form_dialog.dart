import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../destination/domain/entities/location.dart';
import '../providers/admin_location_provider.dart';
import '../providers/admin_destination_provider.dart';
import '../providers/admin_category_provider.dart';

class LocationFormDialog extends ConsumerStatefulWidget {
  final Location? location;

  const LocationFormDialog({super.key, this.location});

  @override
  ConsumerState<LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends ConsumerState<LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _destinationIdController;
  late TextEditingController _imageController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _tagsController;
  late TextEditingController _priceRangeController;
  late TextEditingController _ratingController;
  String _selectedCategory = 'food';

  @override
  void initState() {
    super.initState();
    final loc = widget.location;
    _idController = TextEditingController(
      text:
          loc?.id ??
          FirebaseFirestore.instance.collection('locations').doc().id,
    );
    _nameController = TextEditingController(text: loc?.name ?? '');
    _destinationIdController = TextEditingController(
      text: loc?.destinationId ?? '',
    );
    _imageController = TextEditingController(text: loc?.image ?? '');
    _descriptionController = TextEditingController(
      text: loc?.description ?? '',
    );
    _addressController = TextEditingController(text: loc?.address ?? '');
    _latitudeController = TextEditingController(
      text: loc?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: loc?.longitude?.toString() ?? '',
    );
    _tagsController = TextEditingController(text: loc?.tags.join(', ') ?? '');
    _priceRangeController = TextEditingController(text: loc?.priceRange ?? '');
    _ratingController = TextEditingController(
      text: loc?.rating?.toString() ?? '',
    );
    _selectedCategory = loc?.category ?? 'food';
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _destinationIdController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _tagsController.dispose();
    _priceRangeController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  String? _validateLatitude(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final lat = double.tryParse(value);
    if (lat == null) return 'Vĩ độ phải là số';
    if (lat < -90 || lat > 90) return 'Vĩ độ phải từ -90 đến 90';
    return null;
  }

  String? _validateLongitude(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final lng = double.tryParse(value);
    if (lng == null) return 'Kinh độ phải là số';
    if (lng < -180 || lng > 180) return 'Kinh độ phải từ -180 đến 180';
    return null;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final newLoc = Location(
        id: _idController.text.trim(),
        destinationId: _destinationIdController.text.trim(),
        name: _nameController.text.trim(),
        image: _imageController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        latitude: double.tryParse(_latitudeController.text),
        longitude: double.tryParse(_longitudeController.text),
        tags: tags,
        priceRange: _priceRangeController.text.trim().isNotEmpty
            ? _priceRangeController.text.trim()
            : null,
        rating: double.tryParse(_ratingController.text),
        viewCount: widget.location?.viewCount ?? 0,
        saveCount: widget.location?.saveCount ?? 0,
      );

      final notifier = ref.read(adminLocationProvider.notifier);
      try {
        if (widget.location == null) {
          await notifier.addLocation(newLoc);
        } else {
          await notifier.updateLocationData(newLoc);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.location == null
                    ? 'Thêm địa điểm thành công!'
                    : 'Cập nhật địa điểm thành công!',
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
    final isEditing = widget.location != null;

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
                isEditing ? 'Sửa Địa điểm' : 'Thêm Địa điểm',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _idController,
                              decoration: const InputDecoration(
                                labelText: 'ID (tự động)',
                                border: OutlineInputBorder(),
                              ),
                              enabled:
                                  false, // Always read-only: auto-generated or from existing
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final destinationsState = ref.watch(
                                  adminDestinationProvider,
                                );

                                if (destinationsState.isInitialLoading) {
                                  return const LinearProgressIndicator();
                                }

                                final destinations = destinationsState.items;

                                String initialText =
                                    _destinationIdController.text;
                                if (initialText.isNotEmpty) {
                                  final match = destinations
                                      .where((d) => d.id == initialText)
                                      .firstOrNull;
                                  if (match != null) {
                                    initialText = match.name;
                                  }
                                }

                                return Autocomplete<String>(
                                  initialValue: TextEditingValue(
                                    text: initialText,
                                  ),
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return destinations.map((d) => d.name);
                                    }
                                    final query = textEditingValue.text
                                        .toLowerCase();
                                    return destinations
                                        .where(
                                          (d) =>
                                              d.id.contains(query) ||
                                              d.name.toLowerCase().contains(
                                                query,
                                              ),
                                        )
                                        .map((d) => d.name);
                                  },
                                  onSelected: (selection) {
                                    final match = destinations
                                        .where((d) => d.name == selection)
                                        .firstOrNull;
                                    if (match != null) {
                                      _destinationIdController.text = match.id;
                                    }
                                  },
                                  fieldViewBuilder:
                                      (
                                        context,
                                        controller,
                                        focusNode,
                                        onSubmitted,
                                      ) {
                                        return TextFormField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                            labelText: 'Điểm đến',
                                            hintText: 'Nhập để tìm...',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.search),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty)
                                              return 'Bắt buộc chọn điểm đến';
                                            return null;
                                          },
                                          onFieldSubmitted: (_) =>
                                              onSubmitted(),
                                          onChanged: (v) {
                                            // Find matching destination by name
                                            final match = destinations
                                                .where(
                                                  (d) =>
                                                      d.name.toLowerCase() ==
                                                      v.trim().toLowerCase(),
                                                )
                                                .firstOrNull;
                                            _destinationIdController.text =
                                                match?.id ?? v.trim();
                                          },
                                        );
                                      },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imageController,
                              decoration: const InputDecoration(
                                labelText: 'Ảnh (URL)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final categoriesAsync = ref.watch(
                                  activeCategoriesProvider,
                                );
                                return categoriesAsync.when(
                                  data: (categories) =>
                                      DropdownButtonFormField<String>(
                                        value: _selectedCategory,
                                        decoration: const InputDecoration(
                                          labelText: 'Danh mục',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: categories
                                            .map(
                                              (cat) => DropdownMenuItem(
                                                value: cat.id,
                                                child: Text(cat.displayText),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) => setState(
                                          () => _selectedCategory = v!,
                                        ),
                                      ),
                                  loading: () => const SizedBox(
                                    height: 56,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  error: (_, __) =>
                                      DropdownButtonFormField<String>(
                                        value: _selectedCategory,
                                        decoration: const InputDecoration(
                                          labelText: 'Danh mục',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: const [
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
                                          () => _selectedCategory = v!,
                                        ),
                                      ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // GPS Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.blue.shade50,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📍 Tọa độ GPS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _latitudeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Vĩ độ (-90 đến 90)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                    validator: _validateLatitude,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _longitudeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Kinh độ (-180 đến 180)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
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
                              decoration: const InputDecoration(
                                labelText: 'Mức giá (ví dụ: \$\$)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _ratingController,
                              decoration: const InputDecoration(
                                labelText: 'Đánh giá (0-5)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return null; // optional
                                final rating = double.tryParse(v);
                                if (rating == null) return 'Phải là số';
                                if (rating < 0 || rating > 5)
                                  return 'Phải từ 0.0 đến 5.0';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Thẻ (cách nhau bởi dấu phẩy)',
                          border: OutlineInputBorder(),
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
