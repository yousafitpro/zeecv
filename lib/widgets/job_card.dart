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
    final List<String> tagList = job.tags.isNotEmpty
        ? job.tags.split(',').map((e) => e.trim()).take(3).toList()
        : [];

    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (job.jobTypes != null && job.jobTypes!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        job.jobTypes!.split(',').first.trim(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business_center, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.companyName,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              if (job.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
              if (job.remote == 1) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.wifi, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text(
                      'Remote',
                      style: TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ],
                ),
              ],
              if (tagList.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tagList.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(job.jobCreatedAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(children: [
                    // Container(
                    //   padding: const EdgeInsets.only(left:10,right:10),
                    //   child: GestureDetector(
                    //     onTap: ()=>_toggleSaveJob(jobId:job.id ),
                    //     child: Icon(
                    //   Icons.bookmark,
                    //   color: Colors.grey[600],
                    //   size: 20,
                    // ),
                    //   ),
                    // ),
                    GestureDetector(
                      onTap: () => context.go('/job-detail/${job.slug}',extra: {
                            'back_url': this.back_url
                        }),
                      child:Text(
                    'View Details →',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    )
                    ),
                  )
                  ],),
                ],
              ),
            ],
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