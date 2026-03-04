import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../home/domain/utils/destination_emoji_helper.dart';
import '../providers/trip_creation_provider.dart';

class DestinationSelectionGrid extends ConsumerStatefulWidget {
  const DestinationSelectionGrid({super.key});

  @override
  ConsumerState<DestinationSelectionGrid> createState() =>
      _DestinationSelectionGridState();
}

class _DestinationSelectionGridState
    extends ConsumerState<DestinationSelectionGrid> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Normalize Vietnamese text for diacritic-insensitive search.
  String _normalize(String input) {
    const diacritics =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễđìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹ';
    const replacements =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeediiiiiooooooooooooooooouuuuuuuuuuuyyyyy';

    var result = input.toLowerCase().trim();
    for (var i = 0; i < diacritics.length; i++) {
      result = result.replaceAll(diacritics[i], replacements[i]);
    }
    return result;
  }

  List<Destination> _filterDestinations(List<Destination> destinations) {
    if (_searchQuery.isEmpty) return destinations;
    final normalizedQuery = _normalize(_searchQuery);
    return destinations.where((d) {
      return _normalize(d.name).contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(allDestinationsProvider);
    final selectedId = ref.watch(
      tripCreationProvider.select((state) => state.selectedDestinationId),
    );

    return destinationsAsync.when(
      data: (destinations) {
        if (destinations.isEmpty) {
          return const Center(child: Text('Không có điểm đến nào.'));
        }

        final filtered = _filterDestinations(destinations);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔍 Search bar
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm điểm đến...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),

              // Destination pills
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Không tìm thấy "$_searchQuery"',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filtered.map((destination) {
                      final isSelected = selectedId == destination.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _DestinationPill(
                          destination: destination,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final notifier = ref.read(
                              tripCreationProvider.notifier,
                            );
                            if (isSelected) {
                              notifier.deselectDestination();
                            } else {
                              notifier.selectDestination(
                                destination.id,
                                destination.name,
                              );
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => Center(child: Text('Lỗi: $error')),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
          6,
          (_) => const ShimmerPlaceholder(
            width: 110,
            height: 38,
            borderRadius: 20,
          ),
        ),
      ),
    );
  }
}

/// Small pill chip for destination selection.
class _DestinationPill extends StatelessWidget {
  final Destination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _DestinationPill({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = DestinationEmojiHelper.getEmoji(destination.id);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              destination.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}
