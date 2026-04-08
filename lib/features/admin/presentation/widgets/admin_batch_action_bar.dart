import 'package:flutter/material.dart';

class AdminBatchActionBar extends StatelessWidget {
  const AdminBatchActionBar({
    super.key,
    required this.selectionLabel,
    required this.actions,
    this.onClearSelection,
  });

  final String selectionLabel;
  final List<Widget> actions;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 20),
      Text(
        selectionLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Color(0xFF4338CA),
        ),
      ),
      if (onClearSelection != null)
        OutlinedButton(
          onPressed: onClearSelection,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[700],
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: const Text('Bỏ chọn'),
        ),
      ...actions,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktopRow = constraints.maxWidth >= 720;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: desktopRow ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: desktopRow
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        if (index > 0) const SizedBox(width: 8),
                        items[index],
                      ],
                    ],
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: items,
                ),
        );
      },
    );
  }
}
