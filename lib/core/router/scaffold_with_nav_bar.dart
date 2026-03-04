import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

/// Scaffold with floating glassmorphic bottom navigation bar.
///
/// Gen Z redesign: Replaces standard BottomNavigationBar with a
/// floating pill-shaped bar featuring glassmorphism blur effect,
/// gradient active indicator, and micro-animations.
///
/// Features:
/// - Floating pill shape with 28px border radius
/// - Glassmorphism: BackdropFilter blur + semi-transparent white
/// - Gradient active indicator (Electric Purple → Hot Pink)
/// - Outlined → filled icon transition on active
/// - Subtle scale animation on tap
/// - Content scrolls behind the nav bar (transparent overlap)
class ScaffoldWithNavBar extends StatelessWidget {
  /// The navigation shell that manages the current UI branch
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content fills entire screen (behind nav bar)
          navigationShell,

          // Floating glassmorphic navigation bar
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: _FloatingNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                HapticFeedback.lightImpact();
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The floating glassmorphic navigation bar widget.
///
/// Renders a pill-shaped container with backdrop blur, containing
/// 3 nav items with animated transitions.
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItemData(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Khám phá',
    ),
    _NavItemData(
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
      label: 'Trips',
    ),
    _NavItemData(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Cá nhân',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.navShadow,
            blurRadius: 20,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.navGlass,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_items.length, (index) {
                return _NavItem(
                  data: _items[index],
                  isActive: currentIndex == index,
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for navigation item configuration.
class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A single navigation item with animated active state.
///
/// Active state: gradient background pill + filled icon + label
/// Inactive state: outlined icon only, no label
class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive ? AppGradients.primaryGradient : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isActive ? data.activeIcon : data.icon,
                key: ValueKey(isActive),
                size: 24,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            // Animated label (only visible when active)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        data.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
