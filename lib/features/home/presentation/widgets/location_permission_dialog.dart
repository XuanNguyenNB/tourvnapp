import 'package:flutter/material.dart';

/// Dialog for handling location permission denied state.
///
/// Shows:
/// - Icon and message explaining why location is needed
/// - "Mở cài đặt" button to open app settings
/// - "Để sau" button to dismiss
///
/// Story 8-0.5: GPS-Based Distance Calculation
class LocationPermissionDialog extends StatelessWidget {
  /// Callback when user wants to open settings
  final VoidCallback onOpenSettings;

  /// Callback when user dismisses
  final VoidCallback? onDismiss;

  const LocationPermissionDialog({
    super.key,
    required this.onOpenSettings,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_off_outlined,
              color: Color(0xFF92400E),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Bật vị trí',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: const Text(
        'Cho phép truy cập vị trí để xem khoảng cách đến các địa điểm và tìm những nơi gần bạn nhất.',
        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text(
            'Để sau',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onOpenSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text(
            'Mở cài đặt',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Show the permission dialog.
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onOpenSettings,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => LocationPermissionDialog(
        onOpenSettings: onOpenSettings,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// Banner widget for showing location permission status.
///
/// Compact version for inline display.
class LocationPermissionBanner extends StatelessWidget {
  /// Callback when user taps to enable
  final VoidCallback onEnable;

  /// Whether to show close button
  final bool showClose;

  /// Callback when closed
  final VoidCallback? onClose;

  const LocationPermissionBanner({
    super.key,
    required this.onEnable,
    this.showClose = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_outlined,
            color: Color(0xFF92400E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bật vị trí để xem khoảng cách',
              style: TextStyle(
                color: const Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onEnable,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Bật',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showClose)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Color(0xFF92400E), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
