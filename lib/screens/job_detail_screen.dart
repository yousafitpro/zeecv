import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/job_model.dart';

class JobDetailScreen extends StatefulWidget {
  final String slug;

  const JobDetailScreen({
    super.key,
    required this.slug,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Job? _job;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.getJobDetails(widget.slug);

      if (result['success']) {
        final data = result['data'];
        final jobData = data['job'];
        if (jobData != null) {
          setState(() {
            _job = Job.fromJson(jobData);
          });
        } else {
          setState(() {
            _errorMessage = 'Job not found';
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load job details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        elevation: 0,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading job',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJobDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_job == null) {
      return const Center(
        child: Text('Job not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Name
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _job!.companyName,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            _job!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Location & Remote
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_job!.location.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _job!.location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_job!.remote == 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Remote',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_job!.jobTypes != null && _job!.jobTypes!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _job!.jobTypes!.split(',').first.trim(),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Posted Date
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Posted: ${_formatDate(_job!.jobCreatedAt)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply Button
          if (_job!.url.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(_job!.url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Apply Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Tags Section
          if (_job!.tags.isNotEmpty) ...[
            const Text(
              'Skills & Tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _job!.tags.split(',').map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag.trim(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Description Section
          const Text(
            'Job Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_job!.description.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Html(
                data: _job!.description,
                style: {
                  'body': Style(
                    fontSize: FontSize(14),
                    color: Colors.grey[800],
                    lineHeight: LineHeight(1.6),
                  ),
                  'h3': Style(
                    fontSize: FontSize(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    margin: Margins.only(bottom: 8, top: 16),
                  ),
                  'ul': Style(
                    padding: HtmlPaddings.all(8),
                  ),
                  'li': Style(
                    fontSize: FontSize(14),
                    color: Colors.grey[800],
                    margin: Margins.only(bottom: 4),
                  ),
                  'div': Style(
                    fontSize: FontSize(14),
                    color: Colors.grey[800],
                  ),
                  'p': Style(
                    fontSize: FontSize(14),
                    color: Colors.grey[800],
                  ),
                  'b': Style(
                    fontWeight: FontWeight.bold,
                  ),
                  'strong': Style(
                    fontWeight: FontWeight.bold,
                  ),
                },
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
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

  String _getDomainName(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final parts = host.split('.');
      if (parts.length >= 2) {
        return parts[parts.length - 2].toUpperCase();
      }
      return host;
    } catch (e) {
      return 'Website';
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}