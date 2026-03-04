import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Filter type for a suggestion chip.
enum SuggestionFilterType {
  /// Filter reviews by category (food, cafe, places, stay).
  category,

  /// Filter reviews by mood tag.
  mood,

  /// Sort by GPS proximity ("Gần tôi").
  nearMe,

  /// No filter — just a search query / aspirational.
  none,
}

/// Data model for a suggestion chip.
class SuggestionData {
  final String label;
  final String emoji;
  final String searchQuery;
  final SuggestionFilterType filterType;
  final String? filterValue;

  const SuggestionData({
    required this.label,
    required this.emoji,
    required this.searchQuery,
    this.filterType = SuggestionFilterType.none,
    this.filterValue,
  });

  String get displayText => '$emoji $label';
}

/// A horizontally scrollable row of suggestion chips with selected state.
class SuggestionChipsRow extends StatefulWidget {
  /// Callback when a suggestion chip is tapped (query, filterType, filterValue).
  final void Function(SuggestionData? suggestion) onSuggestionTap;

  const SuggestionChipsRow({super.key, required this.onSuggestionTap});

  /// Curated list of suggestion chips.
  static const List<SuggestionData> suggestions = [
    SuggestionData(
      label: 'Gợi ý cho bạn',
      emoji: '✨',
      searchQuery: 'Gợi ý cho bạn',
      filterType: SuggestionFilterType.none,
    ),
    SuggestionData(
      label: 'Gần tôi',
      emoji: '📍',
      searchQuery: 'Gần tôi',
      filterType: SuggestionFilterType.nearMe,
    ),
    SuggestionData(
      label: 'Check-in',
      emoji: '📸',
      searchQuery: 'Check-in',
      filterType: SuggestionFilterType.category,
      filterValue: 'places',
    ),
    SuggestionData(
      label: 'Ăn uống',
      emoji: '🍜',
      searchQuery: 'Ăn uống',
      filterType: SuggestionFilterType.category,
      filterValue: 'food',
    ),
    SuggestionData(
      label: 'Cafe',
      emoji: '☕',
      searchQuery: 'Cafe',
      filterType: SuggestionFilterType.category,
      filterValue: 'cafe',
    ),
    SuggestionData(
      label: 'Thiên nhiên',
      emoji: '🌿',
      searchQuery: 'Thiên nhiên',
      filterType: SuggestionFilterType.mood,
      filterValue: 'peaceful',
    ),
    SuggestionData(
      label: 'Lưu trú',
      emoji: '🏨',
      searchQuery: 'Lưu trú',
      filterType: SuggestionFilterType.category,
      filterValue: 'stay',
    ),
    SuggestionData(
      label: 'Về đêm',
      emoji: '🌙',
      searchQuery: 'Về đêm',
      filterType: SuggestionFilterType.mood,
      filterValue: 'adventure',
    ),
    SuggestionData(
      label: 'Gia đình',
      emoji: '👨‍👩‍👧‍👦',
      searchQuery: 'Gia đình',
      filterType: SuggestionFilterType.mood,
      filterValue: 'family',
    ),
  ];

  // Color constants
  static const _selectedBackground = Color(0xFF8B5CF6);
  static const _unselectedBackground = Colors.white;
  static const _borderColor = Color(0xFFE2E8F0);
  static const _selectedTextColor = Colors.white;
  static const _unselectedTextColor = Color(0xFF64748B);

  @override
  State<SuggestionChipsRow> createState() => _SuggestionChipsRowState();
}

class _SuggestionChipsRowState extends State<SuggestionChipsRow> {
  int? _selectedIndex;

  void _onChipTap(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = null;
        widget.onSuggestionTap(null); // Clear filter
      } else {
        _selectedIndex = index;
        widget.onSuggestionTap(SuggestionChipsRow.suggestions[index]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(SuggestionChipsRow.suggestions.length, (i) {
            final suggestion = SuggestionChipsRow.suggestions[i];
            final isSelected = _selectedIndex == i;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onChipTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SuggestionChipsRow._selectedBackground
                        : SuggestionChipsRow._unselectedBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: SuggestionChipsRow._borderColor,
                            width: 1,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: SuggestionChipsRow._selectedBackground
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    suggestion.displayText,
                    style: TextStyle(
                      color: isSelected
                          ? SuggestionChipsRow._selectedTextColor
                          : SuggestionChipsRow._unselectedTextColor,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
