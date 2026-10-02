// lib/screens/find_job_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zeecv/design/gradient_background.dart';
import 'package:zeecv/widgets/job_card.dart';
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
    
    // Location state variables
    String? tempLocation = jobStore.selectedLocation; 
    String locationSearchQuery = '';

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
            
            // 1. Get all locations and filter based on search
            final locations = jobStore.locations ?? []; 
            final filteredLocations = locations
                .where((loc) => loc.toLowerCase().contains(locationSearchQuery.toLowerCase()))
                .toList();

            // 2. NEW LOGIC: Ensure the selected location is always at the front
            List<String> displayLocations = List.from(filteredLocations);
            
            // If not searching, and a location is selected, move it to the top
            if (locationSearchQuery.isEmpty && tempLocation != null && tempLocation!.isNotEmpty) {
              // Remove it from its original position
              displayLocations.remove(tempLocation);
              // Insert it at the very beginning
              displayLocations.insert(0, tempLocation!);
            }

            // 3. Limit to 4 locations if the user isn't actively searching
            if (locationSearchQuery.isEmpty) {
              displayLocations = displayLocations.take(4).toList();
            }

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
                                tempLocation = null; 
                              });
                            },
                            child: const Text('Reset All'),
                          ),
                          TextButton(
                            onPressed: () {
                              final store = context.read<JobStore>();
                              store.setFilters(
                                isRemote: tempRemote,
                                isPermanent: tempPermanent,
                                isContract: tempContract,
                                isPartTime: tempPartTime,
                                isFullTime: tempFullTime,
                                isInternship: tempInternship,
                                thisWeek: tempThisWeek,
                                location: tempLocation, 
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

                  // Filter content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // --- Location Section ---
                          _buildFilterSection(
                            title: 'Location',
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search location...',
                                  prefixIcon: const Icon(Icons.search),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (value) {
                                  setModalState(() {
                                    locationSearchQuery = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              if (filteredLocations.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('No locations found', style: TextStyle(color: Colors.grey)),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        ChoiceChip(
                                          label: const Text('Any Location'),
                                          selected: tempLocation == null || tempLocation!.isEmpty,
                                          onSelected: (selected) {
                                            if (selected) {
                                              setModalState(() => tempLocation = null);
                                            }
                                          },
                                        ),
                                        // Use displayLocations here 
                                        ...displayLocations.map((loc) {
                                          return ChoiceChip(
                                            label: Text(loc),
                                            selected: tempLocation == loc,
                                            onSelected: (selected) {
                                              setModalState(() {
                                                tempLocation = selected ? loc : null;
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                    
                                    // Helpful hint text if there are more locations hidden
                                    if (locationSearchQuery.isEmpty && filteredLocations.length > 4)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: Text(
                                          'Showing 4 of ${filteredLocations.length} locations. Type above to search for more.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                          const Divider(),

                          // --- Job Type Section ---
                          _buildFilterSection(
                            title: 'Job Type',
                            children: [
                              _buildFilterCheckbox(
                                label: 'Permanent',
                                value: tempPermanent,
                                onChanged: (value) => setModalState(() => tempPermanent = value ?? false),
                              ),
                              _buildFilterCheckbox(
                                label: 'Contract',
                                value: tempContract,
                                onChanged: (value) => setModalState(() => tempContract = value ?? false),
                              ),
                              _buildFilterCheckbox(
                                label: 'Part Time',
                                value: tempPartTime,
                                onChanged: (value) => setModalState(() => tempPartTime = value ?? false),
                              ),
                              _buildFilterCheckbox(
                                label: 'Full Time',
                                value: tempFullTime,
                                onChanged: (value) => setModalState(() => tempFullTime = value ?? false),
                              ),
                              _buildFilterCheckbox(
                                label: 'Internship',
                                value: tempInternship,
                                onChanged: (value) => setModalState(() => tempInternship = value ?? false),
                              ),
                            ],
                          ),
                          const Divider(),
                          
                          // --- Others Section ---
                          _buildFilterSection(
                            title: 'Others',
                            children: [
                              _buildFilterCheckbox(
                                label: 'Remote',
                                value: tempRemote,
                                onChanged: (value) => setModalState(() => tempRemote = value ?? false),
                              ),
                              _buildFilterCheckbox(
                                label: 'Posted This Week',
                                value: tempThisWeek,
                                onChanged: (value) => setModalState(() => tempThisWeek = value ?? false),
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
      body: Stack(
    children: [
      GradientBackground(),
      Consumer<JobStore>(
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
      )
      ]
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, JobStore jobStore) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 0.0,
        left: 16.0,
        right: 16.0,
      ),
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
              side: BorderSide(
              color: Theme.of(context).primaryColor, // Change outline color here
              width: 2, // Optional: change border width
            ),
            ),
            child: Stack(
              children: [
                 SvgPicture.asset(
                    'assets/svgs/filter.svg',
                    width: 25,
                    height: 25,
                    colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColor,
                    BlendMode.srcIn,
                  )
                  ),
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
          padding: const EdgeInsets.all(20.0),
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
          return JobCard(job: jobStore.jobs[index],back_url:'/home/find-jobs');
        },
      ),
    );
  }




}