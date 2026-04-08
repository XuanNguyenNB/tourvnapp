import 'package:flutter/material.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCopy(title: title, subtitle: subtitle),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(spacing: 12, runSpacing: 12, children: actions),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HeaderCopy(title: title, subtitle: subtitle),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 16),
              Wrap(spacing: 12, runSpacing: 12, children: actions),
            ],
          ],
        );
      },
    );
  }
}

class _HeaderCopy extends StatelessWidget {
  const _HeaderCopy({required this.title, required this.subtitle});

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
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
        ),
      ],
    );
  }
}
