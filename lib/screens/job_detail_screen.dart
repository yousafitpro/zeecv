import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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

  // InAppWebView state
  bool _showInAppBrowser = false;
  String? _inAppBrowserUrl;
  InAppWebViewController? _webViewController;
  double _progress = 0;

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

  // ============================================================
  // OPEN URL IN IN-APP BROWSER (ALL URLs)
  // ============================================================

  Future<void> _openInAppBrowser(String url) async {
    try {
      setState(() {
        _showInAppBrowser = true;
        _inAppBrowserUrl = url;
        _progress = 0;
      });
    } catch (e) {
      _showError('Error: $e');
    }
  }

  // ============================================================
  // CLOSE IN-APP BROWSER
  // ============================================================

  void _closeInAppBrowser() {
    setState(() {
      _showInAppBrowser = false;
      _inAppBrowserUrl = null;
      _webViewController = null;
      _progress = 0;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // IN-APP BROWSER (WEBVIEW)
    // ==========================================================

    if (_showInAppBrowser && _inAppBrowserUrl != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _job?.title ?? 'Loading...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closeInAppBrowser,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _webViewController?.reload();
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                if (_inAppBrowserUrl != null) {
                  final uri = Uri.parse(_inAppBrowserUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                }
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(_inAppBrowserUrl!),
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onLoadStart: (controller, url) {
            setState(() {
              _inAppBrowserUrl = url?.toString();
            });
          },
          onLoadError: (controller, url, code, message) {
            _showError('Failed to load page: $message');
          },
        ),
      );
    }

    // ==========================================================
    // NORMAL DETAIL VIEW
    // ==========================================================

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

    final bool isInternal = _job!.type != null && 
        _job!.type!.toLowerCase() == 'internal';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Name with Type Badge
          Row(
            children: [
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
              const SizedBox(width: 8)
            ],
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

          // Apply Now Button - ALWAYS opens in in-app browser
          if (_job!.url.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openInAppBrowser(_job!.url),
                icon: const Icon(Icons.open_in_browser),
                label: const Text(
                  'Apply Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
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
          const SizedBox(height: 24),

          // Source Link - Opens in in-app browser
          if (_job!.url.isNotEmpty)
            InkWell(
              onTap: () => _openInAppBrowser(_job!.url),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View on ${_getDomainName(_job!.url)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_browser,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
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
}