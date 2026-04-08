import 'package:flutter/material.dart';

class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({
    super.key,
    required this.children,
    this.hasActiveFilters = false,
    this.onClearFilters,
  });

  final List<Widget> children;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty && !hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final clearAction = hasActiveFilters && onClearFilters != null
        ? TextButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Xóa bộ lọc', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          )
        : null;

    final primaryActions = <Widget>[
      Icon(Icons.filter_list, size: 18, color: Colors.grey[500]),
      ...children,
    ];

    final wrapActions = [
      ...primaryActions,
      if (clearAction != null) clearAction,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktopRow = constraints.maxWidth >= 720;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: desktopRow ? 14 : 16,
            vertical: desktopRow ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: desktopRow
              ? Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (
                              var index = 0;
                              index < primaryActions.length;
                              index++
                            ) ...[
                              if (index > 0) const SizedBox(width: 8),
                              primaryActions[index],
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (clearAction != null) ...[
                      const SizedBox(width: 8),
                      clearAction,
                    ],
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: wrapActions,
                ),
        );
      },
    );
  }
}
