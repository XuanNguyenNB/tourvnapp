import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../destination/domain/entities/destination.dart';
import '../providers/admin_destination_provider.dart';

class DestinationFormDialog extends ConsumerStatefulWidget {
  final Destination? destination;

  const DestinationFormDialog({super.key, this.destination});

  @override
  ConsumerState<DestinationFormDialog> createState() =>
      _DestinationFormDialogState();
}

class _DestinationFormDialogState extends ConsumerState<DestinationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _heroImageController;
  late TextEditingController _descriptionController;

  /// Single source of truth for the destination ID.
  /// Once generated (for new) or taken from existing destination (for edit),
  /// this ID is used consistently for both image upload and document save.
  late String _generatedId;
  bool _isUploading = false;
  double _uploadProgress = 0;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    final d = widget.destination;
    _nameController = TextEditingController(text: d?.name ?? '');
    _heroImageController = TextEditingController(text: d?.heroImage ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _generatedId = d?.id ?? '';

    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (widget.destination == null) {
      setState(() {
        _generatedId = Destination.generateId(_nameController.text);
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _heroImageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    // Use _generatedId as the single source of truth
    if (_generatedId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên điểm đến trước khi tải ảnh'),
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
      final url = await ImageUploadService.uploadDestinationHero(
        image: image,
        destinationId: _generatedId,
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
      final isEditing = widget.destination != null;
      // Use _generatedId consistently (same ID used for image upload)
      final id = isEditing ? widget.destination!.id : _generatedId;

      final destination = Destination(
        id: id,
        name: _nameController.text.trim(),
        heroImage: _heroImageController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: widget.destination?.createdAt ?? DateTime.now(),
      );

      final notifier = ref.read(adminDestinationProvider.notifier);
      try {
        if (isEditing) {
          await notifier.updateDestinationData(destination);
        } else {
          await notifier.addDestination(destination);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Cập nhật điểm đến thành công!'
                    : 'Thêm điểm đến thành công!',
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
    final isEditing = widget.destination != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  isEditing ? 'Sửa Điểm đến' : 'Thêm Điểm đến',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Name + Auto ID
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên điểm đến',
                    hintText: 'Ví dụ: Đà Lạt',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                  autofocus: !isEditing,
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
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 16, color: Colors.grey[500]),
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
                const SizedBox(height: 20),

                // Hero image section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // URL input
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
                    // Upload button
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadImage,
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                // Upload progress bar
                if (_isUploading) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6366F1),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đang tải ảnh lên... Ảnh lớn sẽ tự động giảm xuống Full HD',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],

                // Image preview
                if (!_isUploading && _heroImageController.text.isNotEmpty) ...[
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
                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Giới thiệu về điểm đến...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 28),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: _isUploading ? null : _submit,
                      icon: Icon(
                        isEditing ? Icons.save_outlined : Icons.add,
                        size: 18,
                      ),
                      label: Text(isEditing ? 'Lưu' : 'Thêm'),
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
