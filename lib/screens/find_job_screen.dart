import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/job_model.dart';
import 'job_detail_screen.dart';
import 'package:go_router/go_router.dart';

class FindJobScreen extends StatefulWidget {
  const FindJobScreen({super.key});

  @override
  State<FindJobScreen> createState() => _FindJobScreenState();
}

class _FindJobScreenState extends State<FindJobScreen>
    with AutomaticKeepAliveClientMixin {
  List<Job> _jobs = [];

  bool _isLoading = true;
  bool _isFirstLoad = true;

  String? _errorMessage;
  String? _currentSearchQuery;

  // Filter states
  bool _isRemote = false;
  bool _isPermanent = false;
  bool _isContract = false;
  bool _isPartTime = false;
  bool _isFullTime = false;
  bool _isInternship = false;
  bool _thisWeek = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD JOBS
  // ============================================================

  Future<void> _loadJobs({String? searchQuery}) async {
    setState(() {
      _isLoading = true;
      _isFirstLoad = true;
      _errorMessage = null;
      _currentSearchQuery = searchQuery;
    });

    try {
      final apiService = ApiService();

      final result = await apiService.loadJobs(
        search: searchQuery,
      );

      if (!mounted) return;

      if (result['success']) {
        final data = result['data'];

        final List<dynamic> jobList = data['list'] ?? [];

        setState(() {
          _jobs = jobList
              .map((json) => Job.fromJson(json))
              .toList();

          _isFirstLoad = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load jobs: $e';
        _isFirstLoad = false;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearch() {
    final query = _searchController.text.trim();

    _loadJobs(
      searchQuery: query.isNotEmpty ? query : null,
    );
  }

  void _clearSearch() {
    _searchController.clear();

    _loadJobs(
      searchQuery: null,
    );
  }

  // ============================================================
  // FILTER MODAL
  // ============================================================

  void _showFilterModal() {
    // Temporary values.
    // These only become permanent when Apply Filters is pressed.
    bool tempRemote = _isRemote;
    bool tempPermanent = _isPermanent;
    bool tempContract = _isContract;
    bool tempPartTime = _isPartTime;
    bool tempFullTime = _isFullTime;
    bool tempInternship = _isInternship;
    bool tempThisWeek = _thisWeek;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ====================================================
                      // HANDLE BAR
                      // ====================================================

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

                      // ====================================================
                      // HEADER
                      // ====================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ====================================================
                      // FILTER CONTENT
                      // ====================================================

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // ==================================================
                            // JOB TYPE
                            // ==================================================

                            _buildFilterSection(
                              title: 'Job Type',
                              children: [
                                _buildFilterCheckbox(
                                  label: 'Permanent',
                                  value: tempPermanent,
                                  onChanged: (value) {
                                    setModalState(() {
                                      tempPermanent = value ?? false;
                                    });
                                  },
                                ),

                                _buildFilterCheckbox(
                                  label: 'Contract',
                                  value: tempContract,
                                  onChanged: (value) {
                                    setModalState(() {
                                      tempContract = value ?? false;
                                    });
                                  },
                                ),

                                _buildFilterCheckbox(
                                  label: 'Part Time',
                                  value: tempPartTime,
                                  onChanged: (value) {
                                    setModalState(() {
                                      tempPartTime = value ?? false;
                                    });
                                  },
                                ),

                                _buildFilterCheckbox(
                                  label: 'Full Time',
                                  value: tempFullTime,
                                  onChanged: (value) {
                                    setModalState(() {
                                      tempFullTime = value ?? false;
                                    });
                                  },
                                ),

                                _buildFilterCheckbox(
                                  label: 'Internship',
                                  value: tempInternship,
                                  onChanged: (value) {
                                    setModalState(() {
                                      tempInternship = value ?? false;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const Divider(),

                            // ==================================================
                            // OTHER FILTERS
                            // ==================================================

                            _buildFilterSection(
                              title: 'Others',
                              children: [
                                _buildFilterCheckbox(
                                  label: 'Remote',
                                  value: tempRemote,
                                  onChanged: (value) {
                                    setModalState(() {
                                      tempRemote = value ?? false;
                                    });
                                  },
                                ),

                                _buildFilterCheckbox(
                                  label: 'Posted This Week',
                                  value: tempThisWeek,
                                  onChanged: (value) {
                                    setModalState(() {
                                      tempThisWeek = value ?? false;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ==================================================
                            // BUTTONS
                            // ==================================================

                            Row(
                              children: [
                                // CANCEL
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // APPLY
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Commit temporary values
                                      setState(() {
                                        _isRemote = tempRemote;
                                        _isPermanent =
                                            tempPermanent;
                                        _isContract =
                                            tempContract;
                                        _isPartTime =
                                            tempPartTime;
                                        _isFullTime =
                                            tempFullTime;
                                        _isInternship =
                                            tempInternship;
                                        _thisWeek =
                                            tempThisWeek;
                                      });

                                      Navigator.pop(context);

                                      _applyFilters();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context)
                                              .primaryColor,
                                      foregroundColor:
                                          Colors.white,
                                      padding:
                                          const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    child:
                                        const Text('Apply Filters'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FILTER SECTION
  // ============================================================

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

  // ============================================================
  // FILTER CHECKBOX
  // ============================================================

  Widget _buildFilterCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  // ============================================================
  // APPLY FILTERS
  // ============================================================

  void _applyFilters() {
    final Map<String, dynamic> filters = {};

    if (_isRemote) {
      filters['is_remote'] = 1;
    }

    if (_isPermanent) {
      filters['is_permanent'] = 1;
    }

    if (_isContract) {
      filters['is_contract'] = 1;
    }

    if (_isPartTime) {
      filters['is_part_time'] = 1;
    }

    if (_isFullTime) {
      filters['is_full_time'] = 1;
    }

    if (_isInternship) {
      filters['is_internship'] = 1;
    }

    if (_thisWeek) {
      filters['this_week'] = 1;
    }

    _loadJobsWithFilters(filters);
  }

  // ============================================================
  // LOAD FILTERED JOBS
  // ============================================================

  Future<void> _loadJobsWithFilters(
    Map<String, dynamic> filters,
  ) async {
    setState(() {
      _isLoading = true;
      _isFirstLoad = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();

      final result = await apiService.loadJobs(
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        filters: filters,
      );

      if (!mounted) return;

      if (result['success']) {
        final data = result['data'];

        final List<dynamic> jobList = data['list'] ?? [];

        setState(() {
          _jobs = jobList
              .map((json) => Job.fromJson(json))
              .toList();

          _isFirstLoad = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load jobs: $e';
        _isFirstLoad = false;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // RESET FILTERS
  // ============================================================

  void _resetFilters() {
    setState(() {
      _isRemote = false;
      _isPermanent = false;
      _isContract = false;
      _isPartTime = false;
      _isFullTime = false;
      _isInternship = false;
      _thisWeek = false;
    });

    _applyFilters();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Column(
        children: [
          // ==========================================================
          // SEARCH BAR
          // ==========================================================

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search jobs by title, company...',
                      prefixIcon: const Icon(
                        Icons.search,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        vertical: 0,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                  ),
                                  onPressed:
                                      _clearSearch,
                                )
                              : null,
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),

                const SizedBox(width: 8),

                // FILTER BUTTON
                OutlinedButton(
                  onPressed: _showFilterModal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    minimumSize:
                        const Size(50, 50),
                    padding:
                        const EdgeInsets.all(0),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.filter_list,
                        size: 25,
                      ),

                      if (_isRemote ||
                          _isPermanent ||
                          _isContract ||
                          _isPartTime ||
                          _isFullTime ||
                          _isInternship ||
                          _thisWeek)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration:
                                const BoxDecoration(
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
          ),

          // ==========================================================
          // CONTENT
          // ==========================================================

          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_isLoading && _isFirstLoad) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.grey[400],
              ),

              const SizedBox(height: 16),

              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () => _loadJobs(
                  searchQuery:
                      _currentSearchQuery,
                ),
                icon: const Icon(
                  Icons.refresh,
                ),
                label:
                    const Text('Try Again'),
                style:
                    ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),

            const SizedBox(height: 16),

            Text(
              'No jobs found',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _currentSearchQuery !=
                          null &&
                      _currentSearchQuery!
                          .isNotEmpty
                  ? 'No results found for "${_currentSearchQuery}"'
                  : 'Try adjusting your search',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign:
                  TextAlign.center,
            ),

            if (_currentSearchQuery !=
                    null &&
                _currentSearchQuery!
                    .isNotEmpty) ...[
              const SizedBox(height: 16),

              TextButton(
                onPressed:
                    _clearSearch,
                child:
                    const Text(
                  'Clear Search',
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadJobs(
        searchQuery:
            _currentSearchQuery,
      ),
      child: ListView.builder(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        itemCount:
            _jobs.length,
        itemBuilder:
            (context, index) {
          return _buildJobCard(
            _jobs[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // JOB CARD
  // ============================================================

  Widget _buildJobCard(Job job) {
    final List<String> tagList =
        job.tags.isNotEmpty
            ? job.tags
                .split(',')
                .map(
                  (e) => e.trim(),
                )
                .take(3)
                .toList()
            : [];

    return GestureDetector(
      onTap: () {
        context.go(
          '/job-detail/${job.slug}',
        );
      },
      child: Card(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
        elevation: 2,
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ========================================================
              // TITLE
              // ========================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  ),

                  if (job.jobTypes !=
                          null &&
                      job.jobTypes!
                          .isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Theme.of(
                          context,
                        )
                            .primaryColor
                            .withOpacity(
                              0.1,
                            ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          4,
                        ),
                      ),
                      child: Text(
                        job.jobTypes!
                            .split(',')
                            .first
                            .trim(),
                        style:
                            TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).primaryColor,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // ========================================================
              // COMPANY
              // ========================================================

              Row(
                children: [
                  const Icon(
                    Icons
                        .business_center,
                    size: 16,
                    color:
                        Colors.grey,
                  ),

                  const SizedBox(
                    width: 4,
                  ),

                  Expanded(
                    child: Text(
                      job.companyName,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              // ========================================================
              // LOCATION
              // ========================================================

              if (job.location
                  .isNotEmpty) ...[
                const SizedBox(
                    height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color:
                          Colors.grey,
                    ),

                    const SizedBox(
                        width: 4),

                    Expanded(
                      child: Text(
                        job.location,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          color:
                              Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ========================================================
              // REMOTE
              // ========================================================

              if (job.remote == 1) ...[
                const SizedBox(
                    height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.wifi,
                      size: 16,
                      color:
                          Colors.green,
                    ),

                    const SizedBox(
                        width: 4),

                    const Text(
                      'Remote',
                      style:
                          TextStyle(
                        fontSize: 14,
                        color:
                            Colors.green,
                      ),
                    ),
                  ],
                ),
              ],

              // ========================================================
              // TAGS
              // ========================================================

              if (tagList.isNotEmpty) ...[
                const SizedBox(
                    height: 8),

                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      tagList.map(
                    (tag) {
                      return Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey[
                                  200],
                          borderRadius:
                              BorderRadius
                                  .circular(
                            4,
                          ),
                        ),
                        child: Text(
                          tag,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color:
                                Colors.grey,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // ========================================================
              // DATE / DETAILS
              // ========================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Text(
                    _formatDate(
                      job.jobCreatedAt,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey,
                    ),
                  ),

                  Text(
                    'View Details →',
                    style:
                        TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).primaryColor,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    String dateString,
  ) {
    try {
      final date =
          DateTime.parse(dateString);

      final now =
          DateTime.now();

      final difference =
          now.difference(date);

      if (difference.inDays > 30) {
        final months =
            (difference.inDays / 30)
                .floor();

        return '$months month${months > 1 ? 's' : ''} ago';
      } else if (difference.inDays >
          7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays >
          0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours >
          0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes >
          0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }
}