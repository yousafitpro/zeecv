// lib/screens/find_job_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../stores/job_store.dart';
import '../models/job_model.dart';

class FindJobScreen extends StatefulWidget {
  const FindJobScreen({super.key});

  @override
  State<FindJobScreen> createState() => _FindJobScreenState();
}

class _FindJobScreenState extends State<FindJobScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobStore = context.read<JobStore>();
      if (!jobStore.hasLoadedOnce) {
        jobStore.loadJobs();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged(String value) {
    _debounceTimer?.cancel();
    
    final jobStore = context.read<JobStore>();
    jobStore.setSearchQuery(value);
    
    if (value.trim().isEmpty) {
      jobStore.loadJobs(searchQuery: null);
      return;
    }
    
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      final store = context.read<JobStore>();
      store.loadJobs(
        searchQuery: value.trim().isNotEmpty ? value.trim() : null,
      );
    });
  }

  void _onSearch() {
    _debounceTimer?.cancel();
    final jobStore = context.read<JobStore>();
    final query = _searchController.text.trim();
    jobStore.loadJobs(
      searchQuery: query.isNotEmpty ? query : null,
    );
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    final jobStore = context.read<JobStore>();
    jobStore.clearSearch();
    jobStore.loadJobs(searchQuery: null);
  }

  // ============================================================
  // FIXED FILTER MODAL
  // ============================================================
  
  void _showFilterModal() {
    final jobStore = context.read<JobStore>();
    
    // Get current filter values
    bool tempRemote = jobStore.isRemote;
    bool tempPermanent = jobStore.isPermanent;
    bool tempContract = jobStore.isContract;
    bool tempPartTime = jobStore.isPartTime;
    bool tempFullTime = jobStore.isFullTime;
    bool tempInternship = jobStore.isInternship;
    bool tempThisWeek = jobStore.thisWeek;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempRemote = false;
                                tempPermanent = false;
                                tempContract = false;
                                tempPartTime = false;
                                tempFullTime = false;
                                tempInternship = false;
                                tempThisWeek = false;
                              });
                            },
                            child: const Text('Reset All'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Update store with new filter values
                              final store = context.read<JobStore>();
                              store.setFilters(
                                isRemote: tempRemote,
                                isPermanent: tempPermanent,
                                isContract: tempContract,
                                isPartTime: tempPartTime,
                                isFullTime: tempFullTime,
                                isInternship: tempInternship,
                                thisWeek: tempThisWeek,
                              );
                              Navigator.pop(context);
                              store.applyFilters();
                            },
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter content - using Expanded with SingleChildScrollView
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildFilterSection(
                            title: 'Job Type',
                            children: [
                              _buildFilterCheckbox(
                                label: 'Permanent',
                                value: tempPermanent,
                                onChanged: (value) {
                                  setModalState(() => tempPermanent = value ?? false);
                                },
                              ),
                              _buildFilterCheckbox(
                                label: 'Contract',
                                value: tempContract,
                                onChanged: (value) {
                                  setModalState(() => tempContract = value ?? false);
                                },
                              ),
                              _buildFilterCheckbox(
                                label: 'Part Time',
                                value: tempPartTime,
                                onChanged: (value) {
                                  setModalState(() => tempPartTime = value ?? false);
                                },
                              ),
                              _buildFilterCheckbox(
                                label: 'Full Time',
                                value: tempFullTime,
                                onChanged: (value) {
                                  setModalState(() => tempFullTime = value ?? false);
                                },
                              ),
                              _buildFilterCheckbox(
                                label: 'Internship',
                                value: tempInternship,
                                onChanged: (value) {
                                  setModalState(() => tempInternship = value ?? false);
                                },
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildFilterSection(
                            title: 'Others',
                            children: [
                              _buildFilterCheckbox(
                                label: 'Remote',
                                value: tempRemote,
                                onChanged: (value) {
                                  setModalState(() => tempRemote = value ?? false);
                                },
                              ),
                              _buildFilterCheckbox(
                                label: 'Posted This Week',
                                value: tempThisWeek,
                                onChanged: (value) {
                                  setModalState(() => tempThisWeek = value ?? false);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Consumer<JobStore>(
        builder: (context, jobStore, child) {
          return Column(
            children: [
              _buildSearchBar(context, jobStore),
              Expanded(
                child: _buildContent(context, jobStore),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, JobStore jobStore) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs by title, company...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: _onSearchTextChanged,
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _showFilterModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(50, 50),
              padding: const EdgeInsets.all(0),
            ),
            child: Stack(
              children: [
                const Icon(Icons.filter_list, size: 25),
                if (jobStore.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, JobStore jobStore) {
    if (jobStore.isLoading && jobStore.isFirstLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobStore.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                jobStore.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => jobStore.loadJobs(
                  searchQuery: jobStore.currentSearchQuery,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (jobStore.jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No jobs found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              jobStore.currentSearchQuery != null &&
                      jobStore.currentSearchQuery!.isNotEmpty
                  ? 'No results found for "${jobStore.currentSearchQuery}"'
                  : 'Try adjusting your search',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (jobStore.currentSearchQuery != null &&
                jobStore.currentSearchQuery!.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _clearSearch,
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => jobStore.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: jobStore.jobs.length,
        itemBuilder: (context, index) {
          return _buildJobCard(context, jobStore.jobs[index]);
        },
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Job job) {
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
                      onTap: () => context.go('/job-detail/${job.slug}'),
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
// Inside your StatefulWidget or using Provider/GetX
void _toggleSaveJob({required int jobId}) async {
  final jobStore = context.read<JobStore>();
  try {
    
    // Call your API service
    final response = await jobStore.toggleSaveJob(jobID: jobId);
    
  } catch (e) {
    // Handle exception
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
  }
}
}