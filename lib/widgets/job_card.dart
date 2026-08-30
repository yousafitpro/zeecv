import 'package:flutter/material.dart';
import 'package:zeecv/models/job_model.dart';
import 'package:zeecv/stores/job_store.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class JobCard extends StatefulWidget {
  final Job job;
  final String back_url;

  const JobCard({
    super.key,
    required this.job,
    required this.back_url,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  // Local state for UI updates
  late bool _isApplied;
  late bool _isSaved;
  bool _isSaving = false;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _isApplied = widget.job.isApplied ?? false;
    _isSaved = widget.job.isSaved ?? false;
  }

  @override
  void didUpdateWidget(JobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if job changes
    if (oldWidget.job.id != widget.job.id) {
      _isApplied = widget.job.isApplied ?? false;
      _isSaved = widget.job.isSaved ?? false;
    }
  }

  // ============================================================
  // HANDLE SAVE
  // ============================================================
  
  Future<void> _handleSave() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final jobStore = Provider.of<JobStore>(context, listen: false);
      await jobStore.jobSaved(jobId: widget.job.slug);
      
      // Update local state
      setState(() {
        _isSaved = !_isSaved;
        _isSaving = false;
      });

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSaved ? '✅ Job saved!' : '📌 Job removed',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _isSaved ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // HANDLE APPLY
  // ============================================================
  
  Future<void> _handleApply() async {
    if (_isApplying) return;
    
    setState(() {
      _isApplying = true;
    });

    try {
      final jobStore = Provider.of<JobStore>(context, listen: false);
      await jobStore.applied(jobId: widget.job.slug);
      
      // Update local state
      setState(() {
        _isApplied = true;
        _isApplying = false;
      });

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Application submitted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isApplying = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final List<String> tagList = widget.job.tags.isNotEmpty
        ? widget.job.tags.split(',').map((e) => e.trim()).take(3).toList()
        : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => context.push(
  '/job-detail/${widget.job.slug}',
  extra: {'back_url': widget.back_url},
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
                            widget.job.title,
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
                            widget.job.companyName,
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
                    if (widget.job.jobTypes != null && widget.job.jobTypes!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor, width: 1),
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: Text(
                          widget.job.jobTypes!.split(',').first.trim().toUpperCase(),
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

                // Meta info row
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (widget.job.location.isNotEmpty)
                      _MetaItem(
                        icon: Icons.location_on_outlined,
                        label: widget.job.location,
                      ),
                    if (widget.job.remote == 1)
                      const _MetaItem(
                        icon: Icons.wifi_rounded,
                        label: 'Remote',
                        color: Color(0xFF1B8A5A),
                      ),
                    _MetaItem(
                      icon: Icons.access_time_rounded,
                      label: _formatDate(widget.job.jobCreatedAt),
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
                        decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5), // Fixed: removed 'all' and used circular()
                        border: Border.all(
                          color: Colors.grey.shade300, // Add border if needed
                          width: 1,
                        ),
                      ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        
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
                        if (_isApplied)
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
                          onTap: _isSaving ? null : _handleSave,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isSaved ? Colors.blue.shade50 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isSaved ? Colors.blue.shade300 : Colors.grey.shade300,
                                width: 0.5,
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                                        size: 14,
                                        color: _isSaved ? Colors.blue.shade700 : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isSaved ? 'Saved' : 'Save',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _isSaved ? Colors.blue.shade700 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    
                    // View Details
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
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: primaryColor,
                        ),
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