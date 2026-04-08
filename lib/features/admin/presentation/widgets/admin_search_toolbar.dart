import 'package:flutter/material.dart';

class AdminSearchToolbar extends StatelessWidget {
  const AdminSearchToolbar({
    super.key,
    required this.searchValue,
    required this.onSearchChanged,
    this.searchHint = 'Tìm kiếm...',
    this.primaryAction,
  });

  final String searchValue;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;
  final Widget? primaryAction;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: searchValue);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final searchField = SizedBox(
          width: compact ? double.infinity : 280,
          height: 44,
          child: TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
              suffixIcon: searchValue.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              if (primaryAction != null) ...[
                const SizedBox(height: 12),
                primaryAction!,
              ],
            ],
          );
        }

        return Row(
          children: [
            searchField,
            if (primaryAction != null) ...[
              const SizedBox(width: 12),
              primaryAction!,
            ],
          ],
        );
      },
    );
  }
}
