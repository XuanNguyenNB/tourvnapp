import 'package:flutter/material.dart';

/// Search bar widget for the home screen.
///
/// Features:
/// - White background with subtle shadow
/// - Search icon and placeholder text
/// - Tappable to navigate to search flow (currently just visual)
///
/// Design from Figma node 1:5.
class HomeSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final String placeholder;

  const HomeSearchBar({
    super.key,
    this.onTap,
    this.placeholder = 'Bạn muốn đi đâu nè?',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),

            // Search icon
            const Icon(Icons.search, color: Color(0xFF64748B), size: 22),

            const SizedBox(width: 12),

            // Placeholder text
            Expanded(
              child: Text(
                placeholder,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
            ),

            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
