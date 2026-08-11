import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');
      
      if (token != null && userData != null) {
        try {
          final Map<String, dynamic> userMap = 
              Map<String, dynamic>.from(jsonDecode(userData));
          _user = UserModel.fromJson(userMap);
          _apiService.setAuthToken(token);
        } catch (e) {
          await _clearStorage();
        }
      }
    } catch (e) {}

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.signUp(
        name: name,
        email: email,
        password: password,
      );

      if (result['success']) {
        final data = result['data'];
        
        if (data['token'] != null) {
          final user = UserModel.fromJson(data);
          _user = user;
          
          if (user.token != null) {
            _apiService.setAuthToken(user.token!);
            await _saveToStorage(user.token!, user);
          }
          
          _setLoading(false);
          notifyListeners();
          return true;
        }
        
        _setLoading(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Signup failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // REMOVED openZeecvAndCloseApp - Now handled in HomeScreen with WebView

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.signIn(
        email: email,
        password: password,
      );

      if (result['success']) {
        final data = result['data'];
        
        final user = UserModel.fromJson(data);
        _user = user;
        
        if (user.token != null) {
          _apiService.setAuthToken(user.token!);
          await _saveToStorage(user.token!, user);
        }
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Invalid credentials');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _apiService.signOut();
      await _clearStorage();
      _user = null;
      notifyListeners();
    } catch (e) {
      await _clearStorage();
      _user = null;
      notifyListeners();
    }
    
    _setLoading(false);
  }

  Future<void> _saveToStorage(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    _apiService.clearAuthToken();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}