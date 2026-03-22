import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tour_vn/core/theme/app_colors.dart';
import 'package:tour_vn/core/theme/app_radius.dart';
import 'package:tour_vn/core/theme/app_spacing.dart';
import 'package:tour_vn/core/theme/app_typography.dart';

/// Edit Profile Screen - allows user to update display name
///
/// Features:
/// - Display current avatar with initial
/// - Editable display name field
/// - Read-only email display
/// - Save button to update Firebase profile
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _nameController.addListener(() {
      final changed = _nameController.text != (user?.displayName ?? '');
      if (changed != _hasChanges) setState(() => _hasChanges = changed);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
      // Reload to reflect changes
      await FirebaseAuth.instance.currentUser?.reload();
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã cập nhật hồ sơ'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final initial = user?.displayName?.isNotEmpty == true
        ? user!.displayName![0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: (_hasChanges && !_isSaving) ? _saveProfile : null,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Lưu',
                    style: AppTypography.labelMD.copyWith(
                      color: _hasChanges
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Avatar
            const SizedBox(height: AppSpacing.lg),
            CircleAvatar(
              radius: 56,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      initial,
                      style: AppTypography.headingXL.copyWith(
                        color: AppColors.primary,
                        fontSize: 40,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Display Name field
            _buildTextField(
              label: 'Tên hiển thị',
              controller: _nameController,
              icon: Icons.person_outline,
              enabled: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Email (read-only)
            _buildTextField(
              label: 'Email',
              controller: TextEditingController(text: user?.email ?? 'Không có'),
              icon: Icons.email_outlined,
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.md),

            // UID (read-only, for reference)
            _buildTextField(
              label: 'Mã người dùng',
              controller: TextEditingController(
                text: user?.uid.substring(0, 12) ?? '',
              ),
              icon: Icons.fingerprint,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: AppTypography.bodyMD,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySM.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: enabled
            ? AppColors.surface
            : AppColors.border.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
