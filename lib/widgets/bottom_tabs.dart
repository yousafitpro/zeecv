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

  @override
  Widget build(BuildContext context){
    return  BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: this.selectedIndex,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/home/find-jobs');
                    break;
                  case 1:
                    context.go('/home/my-jobs');
                    break;
                  case 2:
                    context.go('/in-app/edit-resume');
                    break;
                  case 3:
                    context.go('/home/profile');
                    break;
                }
              },
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Find Job',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work),
                  label: 'My Jobs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description),
                  label: 'Edit Resume',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            );
  }
}