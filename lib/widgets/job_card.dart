import 'package:flutter/material.dart';
import 'package:zeecv/models/job_model.dart';
import 'package:zeecv/stores/job_store.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final String back_url;

  const JobCard({
    super.key,
    required this.job,
    required this.back_url,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final List<String> tagList = job.tags.isNotEmpty
        ? job.tags.split(',').map((e) => e.trim()).take(3).toList()
        : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
         borderRadius: BorderRadius.circular(12)
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(
            '/job-detail/${job.slug}',
            extra: {'back_url': back_url},
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: Color(0xFF111111),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B6B6B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (job.jobTypes != null && job.jobTypes!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor, width: 1),
                        ),
                        child: Text(
                          job.jobTypes!.split(',').first.trim().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Meta info row — flat, icon + text, no pill backgrounds
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (job.location.isNotEmpty)
                      _MetaItem(
                        icon: Icons.location_on_outlined,
                        label: job.location,
                      ),
                    if (job.remote == 1)
                      const _MetaItem(
                        icon: Icons.wifi_rounded,
                        label: 'Remote',
                        color: Color(0xFF1B8A5A),
                      ),
                    _MetaItem(
                      icon: Icons.access_time_rounded,
                      label: _formatDate(job.jobCreatedAt),
                    ),
                  ],
                ),

                if (tagList.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tagList.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        color: const Color(0xFFF4F4F4),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4A4A4A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFFEDEDED)),
                const SizedBox(height: 14),

                // Footer CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
  // Applied Badge
  if (job.isApplied == true)
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 12,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Applied',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  
  const SizedBox(width: 8),
  
  // Save Button
  GestureDetector(
    onTap: () async {
      final jobStore = Provider.of<JobStore>(context, listen: false);
      await jobStore.jobSaved(jobId: this.job.slug);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: job.isSaved == true ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: job.isSaved == true ? Colors.blue.shade300 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            job.isSaved == true ? Icons.bookmark : Icons.bookmark_border,
            size: 14,
            color: job.isSaved == true ? Colors.blue.shade700 : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            job.isSaved == true ? 'Saved' : 'Save',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: job.isSaved == true ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  ),
],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VIEW DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: primaryColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaItem({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF6B6B6B);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}