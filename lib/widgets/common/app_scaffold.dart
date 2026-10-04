import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.route});
}

const List<_NavItem> _navItems = [
  _NavItem(
      icon: PhosphorIconsRegular.squaresFour,
      activeIcon: PhosphorIconsFill.squaresFour,
      label: 'Home',
      route: '/dashboard'),
  _NavItem(
      icon: PhosphorIconsRegular.users,
      activeIcon: PhosphorIconsFill.users,
      label: 'Members',
      route: '/members'),
  _NavItem(
      icon: PhosphorIconsRegular.creditCard,
      activeIcon: PhosphorIconsFill.creditCard,
      label: 'Payments',
      route: '/payments'),
  _NavItem(
      icon: PhosphorIconsRegular.tag,
      activeIcon: PhosphorIconsFill.tag,
      label: 'Plans',
      route: '/plans'),
  _NavItem(
      icon: PhosphorIconsRegular.gearSix,
      activeIcon: PhosphorIconsFill.gearSix,
      label: 'Settings',
      route: '/settings'),
];

void _openTab(BuildContext context, _NavItem item) {
  if (item.route == '/members') {
    context.read<MemberProvider>().resetFilters();
  }
  context.go(item.route);
}

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width >= AppSpacing.tabletBreakpoint;
    final keyboardOpen = media.viewInsets.bottom > 0;
    final currentIndex = _currentIndex(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _SideNav(currentIndex: currentIndex),
            Container(width: 1, color: AppColors.border),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar:
          keyboardOpen ? null : _BottomNav(currentIndex: currentIndex),
    );
  }
}

class _SideNav extends StatelessWidget {
  final int currentIndex;

  const _SideNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        AppColors.primaryGlow,
                        AppColors.primaryDark
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  alignment: Alignment.center,
                  child: const Text('JG',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('JOJI GYM',
                    style: AppTextStyles.title
                        .copyWith(fontSize: 18, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final selected = index == currentIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Material(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      onTap: () => _openTab(context, item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            Icon(selected ? item.activeIcon : item.icon,
                                size: 24,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.md),
                            Text(item.label,
                                style: AppTextStyles.body.copyWith(
                                    color: selected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                onTap: () => context.read<AppAuthProvider>().logout(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.signOut,
                          size: 24, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.md),
                      Text('Log Out',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;

  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _navItems.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: itemWidth * currentIndex + itemWidth * 0.2,
                    top: 8,
                    child: Container(
                      width: itemWidth * 0.6,
                      height: 48,
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  Row(
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final selected = index == currentIndex;
                      return Expanded(
                        child: InkWell(
                          onTap: () => _openTab(context, item),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(selected ? item.activeIcon : item.icon,
                                  size: 22,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textDisabled),
                              const SizedBox(height: 3),
                              Text(item.label,
                                  style: AppTextStyles.label.copyWith(
                                      fontSize: 10.5,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textDisabled,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
