import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zeecv/design/gradient_background.dart';
import 'package:provider/provider.dart';
import 'package:zeecv/models/dashboard_model.dart';
import '../stores/job_store.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobStore = context.read<JobStore>();
      jobStore.loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobStore>(
      builder: (context, jobStore, child) {
        final dashboard = jobStore.dashboard;
        final isLoading = jobStore.isLoading ?? false;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              const GradientBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loading State
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (dashboard == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No data available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            _buildHeader(dashboard),
                            const SizedBox(height: 10),
                            _buildDashboardContent(dashboard),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Dashboard dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Expanded(
              child:Text(
              '${dashboard.userFullName}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            )
             ),
            const Spacer(),
            // IconButton(
            //   onPressed: () {
            //     // Handle notification tap
            //   },
            //   icon: Icon(Icons.notifications_outlined, color: Colors.grey.shade600),
            // ),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                dashboard.userNameTwo,  // Now this works with lowercase 'u'
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Welcome back',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(Dashboard dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'My Jobs',
                value: dashboard.myjobsCount.toString(),
                icon: 'assets/svgs/find_jobs.svg',
                color: Colors.blue,
                onTap: () {
                  context.go('/home/my-jobs',extra: {
                    'type':'My Jobs'
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Applications',
                value: dashboard.appliedCount.toString(),
                icon: 'assets/svgs/applications.svg',
                color: Colors.green,
                onTap: () {
                  context.go('/home/my-jobs',extra: {
                    'type':'Applied'
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Interviews',
                value: dashboard.interviewsCount.toString(),
                icon: 'assets/svgs/interviews.svg',
                color: Colors.orange,
                onTap: () {
                  context.go('/home/my-jobs');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Saved Jobs',
                value: dashboard.savedCount.toString(),
                icon: 'assets/svgs/save.svg',
                color: Colors.purple,
                onTap: () {
                  context.go('/home/my-jobs',extra: {
                    'type':'Saved'
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Quick Actions
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildToolItem('assets/svgs/edit_profile.svg', 'Edit Profile', () {
              context.go('/in-app/edit-resume',extra: {
                'back_url':'/dashboard'
              });
            }),
            _buildToolItem('assets/svgs/find_jobs.svg', 'Find Jobs', () {
              context.go('/home/find-jobs');
            }),
            _buildToolItem('assets/svgs/applications.svg', 'Apply', () {
             context.go('/home/my-jobs',extra: {
                    'type':'Applied'
                  });
            }),
            _buildToolItem('assets/svgs/save.svg', 'Saved', () {
              context.go('/home/my-jobs',extra: {
                    'type':'Saved'
                  });
            })
          ],
        ),
        const SizedBox(height: 10),

        // Recent Activity
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (dashboard.recentActivities.isNotEmpty)
          ...dashboard.recentActivities.map((activity) =>
            _buildActivityItem(
              title: activity.title,
              subtitle: '${activity.activityLabel} • ${activity.formattedDate}',
              icon: _getIconForActivity(activity.type),
              color: _getColorForActivity(activity.type),
              onTap: () {
                print('Tapped: ${activity.title}');
                context.go('/home/my-jobs');
              },
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No recent activities',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

Widget _buildStatCard({
  required String title,
  required String value,
  required String icon,
  required Color color,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  icon,
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(
                    color,
                    BlendMode.srcIn,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildToolItem(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SvgPicture.asset(
              icon,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Colors.grey.shade700,
                BlendMode.srcIn,
              ),
          ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  IconData _getIconForActivity(String type) {
    switch (type) {
      case 'apply':
        return Icons.work_outlined;
      case 'save':
        return Icons.bookmark;
      default:
        return Icons.circle_notifications;
    }
  }

  Color _getColorForActivity(String type) {
    switch (type) {
      case 'apply':
        return Colors.blue;
      case 'save':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}