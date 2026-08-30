// lib/stores/job_store.dart

import 'package:flutter/material.dart';
import 'package:zeecv/models/dashboard_model.dart';
import 'package:zeecv/stores/my_job_store.dart';
import '../services/api_service.dart';
import '../models/job_model.dart';

class JobStore extends ChangeNotifier {
  // ============================================================
  // SINGLETON PATTERN
  // ============================================================
  
  static final JobStore _instance = JobStore._internal();
  factory JobStore() => _instance;
  JobStore._internal();

  // ============================================================
  // STATE
  // ============================================================
  
  List<Job> _jobs = [];
  Dashboard? _dashboard;
  bool _isLoading = false;
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

  // ============================================================
  // GETTERS
  // ============================================================
  
  List<Job> get jobs => _jobs;
  Dashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  bool get isFirstLoad => _isFirstLoad;
  String? get errorMessage => _errorMessage;
  String? get currentSearchQuery => _currentSearchQuery;
  
  bool get isRemote => _isRemote;
  bool get isPermanent => _isPermanent;
  bool get isContract => _isContract;
  bool get isPartTime => _isPartTime;
  bool get isFullTime => _isFullTime;
  bool get isInternship => _isInternship;
  bool get thisWeek => _thisWeek;
  
  bool get hasActiveFilters => _isRemote || _isPermanent || _isContract || 
                               _isPartTime || _isFullTime || _isInternship || _thisWeek;
  
  bool get hasLoadedOnce => _jobs.isNotEmpty || !_isFirstLoad;

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> loadJobs({String? searchQuery}) async {
    _isLoading = true;
    _isFirstLoad = true;
    _errorMessage = null;
    _currentSearchQuery = searchQuery;
    notifyListeners();

    try {
      final apiService = ApiService();
      final result = await apiService.loadJobs(
        search: searchQuery,
      );

      if (result['success']) {
        final data = result['data'];
        final List<dynamic> jobList = data['list'] ?? [];
        
        _jobs = jobList.map((json) => Job.fromJson(json)).toList();
        _isFirstLoad = false;
        _errorMessage = null;
      } else {
        _errorMessage = result['message'];
        _isFirstLoad = false;
        _jobs = [];
      }
    } catch (e) {
      _errorMessage = 'Failed to load jobs: $e';
      _isFirstLoad = false;
      _jobs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> loadDashboard() async {
    try {
      final apiService = ApiService();
      final result = await apiService.loadDashboard();

      if (result['success']) {
        final data = result['data'];
       final Map<String, dynamic> dashboardData = data['data'] ?? {};
        
        _dashboard = Dashboard.fromJson(dashboardData);
        notifyListeners();
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
    } finally {
    }
  }
  Future<void> applied({required String jobId}) async {

    try {
        _jobs = _jobs.map((job) {
          if (job.slug == jobId) {
            return job.toggleApplied(); // Using helper method
          }
          return job;
        }).toList();
         notifyListeners(); // Add this to update UI
        MyJobStore().applied(jobId: jobId);
      final apiService = ApiService();
      final result = await apiService.jobApplied(job_id: jobId);

      if (result['success']) {
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = 'Failed to load jobs: $e';
    } finally {
    }
  }
  Future<void> jobSaved({required String jobId}) async {

    try {

        _jobs = _jobs.map((job) {
          if (job.slug == jobId) {
            return job.toggleSaved(); // Using helper method
          }
          return job;
        }).toList();
         notifyListeners(); // Add this to update UI
        MyJobStore().jobSaved(jobId: jobId);
      final apiService = ApiService();
      final result = await apiService.jobSave(job_id: jobId);

      if (result['success']) {
  
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = 'Failed to load jobs: $e';
    } finally {
    }
  }
  Future<void> toggleSaveJob({int? jobID}) async {
     
    try {
      final apiService = ApiService();
      final result = await apiService.toggleSaveJob(
        jobID: jobID,
      );

      if (result['success']) {
        final data = result['data'];
        _errorMessage = null;
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = 'Failed to load jobs: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadJobsWithFilters(Map<String, dynamic> filters) async {
    _isLoading = true;
    _isFirstLoad = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final result = await apiService.loadJobs(
        search: _currentSearchQuery?.isNotEmpty == true ? _currentSearchQuery : null,
        filters: filters,
      );

      if (result['success']) {
        final data = result['data'];
        final List<dynamic> jobList = data['list'] ?? [];
        
        _jobs = jobList.map((json) => Job.fromJson(json)).toList();
        _isFirstLoad = false;
        _errorMessage = null;
      } else {
        _errorMessage = result['message'];
        _isFirstLoad = false;
        _jobs = [];
      }
    } catch (e) {
      _errorMessage = 'Failed to load jobs: $e';
      _isFirstLoad = false;
      _jobs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _currentSearchQuery = query.isNotEmpty ? query : null;
    notifyListeners();
  }

  void clearSearch() {
    _currentSearchQuery = null;
    notifyListeners();
  }

  void setFilters({
    bool? isRemote,
    bool? isPermanent,
    bool? isContract,
    bool? isPartTime,
    bool? isFullTime,
    bool? isInternship,
    bool? thisWeek,
  }) {
    _isRemote = isRemote ?? _isRemote;
    _isPermanent = isPermanent ?? _isPermanent;
    _isContract = isContract ?? _isContract;
    _isPartTime = isPartTime ?? _isPartTime;
    _isFullTime = isFullTime ?? _isFullTime;
    _isInternship = isInternship ?? _isInternship;
    _thisWeek = thisWeek ?? _thisWeek;
    notifyListeners();
  }

  void resetFilters() {
    _isRemote = false;
    _isPermanent = false;
    _isContract = false;
    _isPartTime = false;
    _isFullTime = false;
    _isInternship = false;
    _thisWeek = false;
    notifyListeners();
  }

  void resetAll() {
    _jobs = [];
    _isLoading = false;
    _isFirstLoad = true;
    _errorMessage = null;
    _currentSearchQuery = null;
    resetFilters();
    notifyListeners();
  }

  // Get filter map for API
  Map<String, dynamic> getFilterMap() {
    final Map<String, dynamic> filters = {};
    
    if (_isRemote) filters['is_remote'] = 1;
    if (_isPermanent) filters['is_permanent'] = 1;
    if (_isContract) filters['is_contract'] = 1;
    if (_isPartTime) filters['is_part_time'] = 1;
    if (_isFullTime) filters['is_full_time'] = 1;
    if (_isInternship) filters['is_internship'] = 1;
    if (_thisWeek) filters['this_week'] = 1;
    
    return filters;
  }

  // Apply current filters
  Future<void> applyFilters() async {
    final filters = getFilterMap();
    if (filters.isNotEmpty) {
      await loadJobsWithFilters(filters);
    } else {
      await loadJobs(searchQuery: _currentSearchQuery);
    }
  }

  // Refresh data
  Future<void> refresh() async {
    if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
      await loadJobs(searchQuery: _currentSearchQuery);
    } else if (getFilterMap().isNotEmpty) {
      await loadJobsWithFilters(getFilterMap());
    } else {
      await loadJobs();
    }
  }

bool isApplied(String slug) {
  return _jobs.any((job) => job.slug == slug && (job.isApplied ?? false));
}

}