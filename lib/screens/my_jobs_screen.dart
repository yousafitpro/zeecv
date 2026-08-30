import 'package:flutter/material.dart';
import 'package:zeecv/design/gradient_background.dart';
import 'package:zeecv/stores/my_job_store.dart';
import 'package:zeecv/widgets/job_card.dart';
import '../services/api_service.dart';
import '../models/job_model.dart';
import 'job_detail_screen.dart';
import 'package:provider/provider.dart';

class MyJobsScreen extends StatefulWidget {
  final VoidCallback? onEditResume;
  final VoidCallback? onBrowseJobs;

  const MyJobsScreen({
    super.key,
    this.onEditResume,
    this.onBrowseJobs,
  });

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'My Jobs'; // Default active filter

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load jobs after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    final myjobStore = context.read<MyJobStore>();
      if (mounted && !myjobStore.hasLoadedOnce) {
        context.read<MyJobStore>().loadJobs(
          {'type': _selectedFilter},
          _searchQuery,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    // Update search when user types
    context.read<MyJobStore>().loadJobs(
      {'type': _selectedFilter},
      _searchQuery,
    );
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    // Pass filter map to loadJobs
    context.read<MyJobStore>().loadJobs(
      {'type': filter},
      _searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
    children: [
      GradientBackground(),
      Consumer<MyJobStore>(
        builder: (context, myjobStore, child) {
          // Filter jobs locally based on search query
          final filteredJobs = _searchQuery.isEmpty
              ? myjobStore.jobs
              : myjobStore.jobs.where((job) {
                  final query = _searchQuery.toLowerCase().trim();
                  return job.title.toLowerCase().contains(query) ||
                      job.companyName.toLowerCase().contains(query) ||
                      job.location.toLowerCase().contains(query) ||
                      (job.tags.isNotEmpty && job.tags.toLowerCase().contains(query)) ||
                      (job.jobTypes != null && job.jobTypes!.toLowerCase().contains(query));
                }).toList();

          return Column(
            children: [
              _buildSearchBar(),
              _buildFilterPills(),
              Expanded(
                child: _buildContent(context, myjobStore, filteredJobs),
              ),
            ],
          );
        },
      )
      ]
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search jobs...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = ['My Jobs', 'Applied', 'Saved'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onFilterSelected(filter);
                }
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              pressElevation: 0,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MyJobStore jobStore, List<Job> filteredJobs) {
    // Loading state
    if (jobStore.isLoading && jobStore.isFirstLoad) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (jobStore.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                jobStore.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => jobStore.loadJobs(
                  {'type': _selectedFilter},
                  _searchQuery,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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

    // Empty state
    if (jobStore.jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Jobs Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Jobs will appear here once you\'ve built your resume with your skills and experience',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onEditResume,
                  icon: const Icon(Icons.edit_document),
                  label: const Text(
                    'Edit Resume',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onBrowseJobs,
                child: Text(
                  'Browse Jobs Instead',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No search results
    if (filteredJobs.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No jobs found for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Jobs list
    return RefreshIndicator(
      onRefresh: () => jobStore.loadJobs(
        {'type': _selectedFilter},
        _searchQuery,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          return JobCard(
            job: filteredJobs[index],
            back_url: '/home/my-jobs',
          );
        },
      ),
    );
  }
}