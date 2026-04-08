import 'package:flutter/material.dart';

class AdminSidebarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;

  AdminSidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class AdminCustomSidebar extends StatefulWidget {
  const AdminCustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdminSidebarItem> destinations;
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;

  @override
  State<AdminCustomSidebar> createState() => _AdminCustomSidebarState();
}

class _AdminCustomSidebarState extends State<AdminCustomSidebar> {
  int? _hoveredIndex;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = _collapsed ? 92.0 : 268.0;
    final resolvedName = widget.userName?.trim().isNotEmpty == true
        ? widget.userName!.trim()
        : 'Quản trị viên';
    final resolvedEmail = widget.userEmail?.trim().isNotEmpty == true
        ? widget.userEmail!.trim()
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(_collapsed ? 18 : 24, 28, 18, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.travel_explore,
                    color: Color(0xFF6366F1),
                  ),
                ),
                if (!_collapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TourVN Admin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'CMS nội bộ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  tooltip: _collapsed ? 'Mở rộng menu' : 'Thu gọn menu',
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                  icon: Icon(
                    _collapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: _collapsed ? 14 : 16),
              itemCount: widget.destinations.length,
              itemBuilder: (context, index) {
                final item = widget.destinations[index];
                final isSelected = widget.selectedIndex == index;
                final isHovered = _hoveredIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => widget.onDestinationSelected(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: _collapsed ? 0 : 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEEF2FF)
                              : isHovered
                              ? Colors.grey.withValues(alpha: 0.05)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: const Color(0xFFC7D2FE))
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: _collapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  color: isSelected
                                      ? const Color(0xFF4F46E5)
                                      : isHovered
                                      ? Colors.grey[800]
                                      : Colors.grey[500],
                                  size: 22,
                                ),
                                if (item.badgeCount > 0)
                                  Positioned(
                                    right: -10,
                                    top: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item.badgeCount > 99
                                            ? '99+'
                                            : item.badgeCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (!_collapsed) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF4338CA)
                                        : isHovered
                                        ? Colors.grey[800]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _collapsed ? 16 : 20,
              16,
              _collapsed ? 16 : 20,
              20,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: _collapsed ? 10 : 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _collapsed
                  ? CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFEDE9FE),
                      backgroundImage: widget.userAvatarUrl?.isNotEmpty == true
                          ? NetworkImage(widget.userAvatarUrl!)
                          : null,
                      child: widget.userAvatarUrl?.isNotEmpty == true
                          ? null
                          : Text(
                              resolvedName.characters.first.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFEDE9FE),
                          backgroundImage:
                              widget.userAvatarUrl?.isNotEmpty == true
                              ? NetworkImage(widget.userAvatarUrl!)
                              : null,
                          child: widget.userAvatarUrl?.isNotEmpty == true
                              ? null
                              : Text(
                                  resolvedName.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6D28D9),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resolvedName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                resolvedEmail ?? 'Quản trị hệ thống',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
