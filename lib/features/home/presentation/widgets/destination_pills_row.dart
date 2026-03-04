import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../destination/presentation/providers/destination_provider.dart';
import '../providers/destination_filter_provider.dart';
import 'destination_pill.dart';

/// A horizontally scrollable row of destination pills for filtering.
///
/// Story 8-7: Renders destination pills below the Search Bar on Home Screen.
/// Handles loading, empty, and error states with appropriate UI.
class DestinationPillsRow extends ConsumerWidget {
  /// Creates a DestinationPillsRow widget.
  const DestinationPillsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(allDestinationsProvider);
    final filterState = ref.watch(destinationFilterProvider);

    return destinationsAsync.when(
      data: (destinations) {
        if (destinations.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildPillsRow(context, ref, destinations, filterState);
      },
      loading: () => _buildShimmerPlaceholder(context),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPillsRow(
    BuildContext context,
    WidgetRef ref,
    List destinations,
    DestinationFilterState filterState,
  ) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: destinations.map((destination) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DestinationPill(
                destinationId: destination.id,
                destinationName: destination.name,
                isSelected: filterState.isSelected(destination.id),
                onTap: () {
                  ref
                      .read(destinationFilterProvider.notifier)
                      .toggleDestination(destination.id, destination.name);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Shimmer placeholder shown during loading.
  Widget _buildShimmerPlaceholder(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ShimmerPill(
                width: 80.0 + (index * 10), // Varying widths
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a single pill.
class _ShimmerPill extends StatefulWidget {
  final double width;

  const _ShimmerPill({required this.width});

  @override
  State<_ShimmerPill> createState() => _ShimmerPillState();
}

class _ShimmerPillState extends State<_ShimmerPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: 36,
          decoration: BoxDecoration(
            color: Color.fromRGBO(158, 158, 158, _animation.value),
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
  }
}
