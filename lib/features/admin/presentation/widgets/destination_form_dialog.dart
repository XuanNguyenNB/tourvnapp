import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../destination/domain/entities/destination.dart';
import '../providers/admin_destination_provider.dart';
import '../providers/admin_reference_data_provider.dart';
import '../providers/admin_stats_provider.dart';

class DestinationFormDialog extends ConsumerStatefulWidget {
  const DestinationFormDialog({super.key, this.destination});

  final Destination? destination;

  @override
  ConsumerState<DestinationFormDialog> createState() =>
      _DestinationFormDialogState();
}

class _DestinationFormDialogState extends ConsumerState<DestinationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _heroImageController;
  late final TextEditingController _descriptionController;

  late String _generatedId;
  bool _isSaving = false;
  bool _isDirty = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final destination = widget.destination;
    _nameController = TextEditingController(text: destination?.name ?? '');
    _heroImageController = TextEditingController(
      text: destination?.heroImage ?? '',
    );
    _descriptionController = TextEditingController(
      text: destination?.description ?? '',
    );
    _generatedId = destination?.id ?? '';

    _nameController.addListener(_handleNameChanged);
    _nameController.addListener(_markDirty);
    _heroImageController.addListener(_markDirty);
    _descriptionController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.removeListener(_markDirty);
    _heroImageController.removeListener(_markDirty);
    _descriptionController.removeListener(_markDirty);
    _nameController.dispose();
    _heroImageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (widget.destination != null) return;
    setState(() {
      _generatedId = Destination.generateId(_nameController.text.trim());
    });
  }

  void _markDirty() {
    if (_isDirty) return;
    setState(() => _isDirty = true);
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.destination != null;
    final destination = Destination(
      id: isEditing ? widget.destination!.id : _generatedId,
      name: _nameController.text.trim(),
      heroImage: _heroImageController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: widget.destination?.createdAt ?? DateTime.now(),
      status: widget.destination?.status ?? 'published',
      postCount: widget.destination?.postCount ?? 0,
      engagementCount: widget.destination?.engagementCount ?? 0,
      locationCount: widget.destination?.locationCount ?? 0,
      countryCode: widget.destination?.countryCode ?? 'VN',
    );

    final notifier = ref.read(adminDestinationProvider.notifier);

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      if (isEditing) {
        await notifier.updateDestinationData(destination);
      } else {
        await notifier.addDestination(destination);
      }

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isDirty = false;
      });
      ref.invalidate(adminDestinationLookupProvider);
      ref.invalidate(adminStatsProvider);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Cập nhật điểm đến thành công'
                : 'Thêm điểm đến thành công',
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
    final isEditing = widget.destination != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Sửa Điểm đến' : 'Thêm Điểm đến',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(
                    title: 'Thông tin chính',
                    subtitle: 'Tên, ảnh bìa và mô tả hiển thị cho người dùng.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('destination_name_field'),
                    controller: _nameController,
                    enabled: !_isSaving,
                    autofocus: !isEditing,
                    decoration: const InputDecoration(
                      label: Text('TÃªn Ä‘iá»ƒm Ä‘áº¿n'),
                      hintText: 'VÃ­ dá»¥: ÄÃ  Láº¡t',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Vui lòng nhập tên';
                      }
                      if (_generatedId.isEmpty) {
                        return 'Tên chưa đủ để tạo ID hợp lệ';
                      }
                      return null;
                    },
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
                        borderRadius: BorderRadius.circular(10),
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
                          Expanded(
                            child: Text(
                              _generatedId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('destination_hero_url_field'),
                    controller: _heroImageController,
                    enabled: !_isSaving,
                    decoration: InputDecoration(
                      label: const Text('áº¢nh bÃ¬a (URL)'),
                      hintText: 'Dán URL ảnh công khai',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.image_outlined),
                      suffixIcon: _heroImageController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      setState(() {
                                        _heroImageController.clear();
                                        _isDirty = true;
                                      });
                                    },
                            )
                          : null,
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
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (_heroImageController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _heroImageController.text,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 96,
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
                  const SizedBox(height: 20),
                  const _SectionLabel(
                    title: 'Nâng cao',
                    subtitle:
                        'Mô tả nên rõ ràng, tránh để rỗng khi import hoặc tạo draft AI.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('destination_description_field'),
                    controller: _descriptionController,
                    enabled: !_isSaving,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      label: Text('MÃ´ táº£'),
                      hintText: 'Giới thiệu về điểm đến...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
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
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        _saveError!,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
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
                        child: const Text('Há»§y'),
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
                            : Icon(
                                isEditing ? Icons.save_outlined : Icons.add,
                                size: 18,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Äang lÆ°u...'
                              : isEditing
                              ? 'LÆ°u'
                              : 'ThÃªm',
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
