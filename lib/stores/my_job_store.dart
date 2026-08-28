// lib/stores/job_store.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/job_model.dart';

class MyJobStore extends ChangeNotifier {
  // ============================================================
  // SINGLETON PATTERN
  // ============================================================
  
  static final MyJobStore _instance = MyJobStore._internal();
  factory MyJobStore() => _instance;
  MyJobStore._internal();

  // ============================================================
  // STATE
  // ============================================================
  
  List<Job> _jobs = [];
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
  bool get isLoading => _isLoading;
  bool get isFirstLoad => _isFirstLoad;
  String? get errorMessage => _errorMessage;

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
      final result = await apiService.loadMyJobs();
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
  }