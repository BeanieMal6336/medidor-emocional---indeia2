import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ScaffoldWithNav extends ConsumerStatefulWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends ConsumerState<ScaffoldWithNav> {
  static const _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', path: '/dashboard'),
    _NavItem(icon: Icons.auto_graph_rounded, label: 'Mapa', path: '/emotional-map'),
    _NavItem(icon: Icons.add_circle_rounded, label: '', path: '/mood-tracker', isCentral: true),
    _NavItem(icon: Icons.explore_rounded, label: 'Missões', path: '/missions'),
    _NavItem(icon: Icons.psychology_rounded, label: 'Mindo', path: '/ai-companion'),
  ];

  int get _selectedIndex => _indexForLocation(_currentLocation);

  String get _currentLocation {
    final router = GoRouter.of(context);
    return router.routerDelegate.currentConfiguration.fullPath;
  }

  int _indexForLocation(String location) {
    for (int i = 0; i < _navItems.length; i++) {
      if (_navItems[i].path == location) return i;
    }
    return 0;
  }

  void _onNavTap(int index) {
    // Mood tracker abre como overlay (push), não substitui o shell
    if (_navItems[index].isCentral) {
      context.push(_navItems[index].path);
      return;
    }
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: widget.child,
      bottomNavigationBar: _BottomNav(
        items: _navItems,
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  final bool isCentral;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    this.isCentral = false,
  });
}

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.bgMedium,
        border: const Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = selectedIndex == i && !item.isCentral;
              if (item.isCentral) {
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.shadowPrimary,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ).animate(onPlay: (c) => c.repeat(period: 3.seconds))
                    .shimmer(delay: 2.seconds, duration: 1.seconds),
                );
              }
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
