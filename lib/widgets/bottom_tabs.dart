import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class BottomTabs extends StatelessWidget {
  final int selectedIndex;
  const BottomTabs({
    Key? key,
    required this.selectedIndex,
  }) : super(key: key);

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/home/find-jobs');
        break;
      case 2:
        context.go('/in-app/edit-resume');
        break;
      case 3:
        context.go('/home/my-jobs'); // placeholder, replace with your route
        break;
      case 4:
        context.go('/home/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70, // bar content height; SafeArea adds the inset below
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Background bar
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home_filled,
                        label: 'Home',
                        isSelected: selectedIndex == 0,
                        onTap: () => _onTap(context, 0),
                      ),
                      _NavItem(
                        icon: Icons.search,
                        label: 'Find Jobs',
                        isSelected: selectedIndex == 1,
                        onTap: () => _onTap(context, 1),
                      ),
                      const SizedBox(width: 64), // space for center button
                      _NavItem(
                        icon: Icons.work_outline,
                        label: 'My Jobs',
                        isSelected: selectedIndex == 3,
                        onTap: () => _onTap(context, 3),
                      ),
                      _NavItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        isSelected: selectedIndex == 4,
                        onTap: () => _onTap(context, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating center button
              Positioned(
                top: 5,
                child: GestureDetector(
                  onTap: () => _onTap(context, 2),
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : Colors.grey;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}