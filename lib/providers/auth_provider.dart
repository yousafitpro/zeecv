import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/app_strings.dart';
import '../app/router.dart';
class AuthProvider extends ChangeNotifier {
  
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(serverClientId:'779291687230-2tp0skgtpq7p800h6f9clmd2odg87p9r.apps.googleusercontent.com',scopes: ['email', 'profile']);
  final List<String> infoLogs = [];
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
     _apiService.onUnauthorized = _handleUnauthorized;
    _init();
  }
void _addLog(String type, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final log = '[$timestamp] $type: $message';
    
    // Add to array
    infoLogs.add(log);
    
    // Keep max 200 logs to avoid memory issues
    if (infoLogs.length > 200) {
      infoLogs.removeAt(0);
    }
    
    // Print to console
    print(log);
    
    // Notify listeners so the LogsScreen updates in real-time
    notifyListeners();
  }
  // ============================================================
  // INIT
  // ============================================================
Future<void> _handleUnauthorized() async {
  print('🔴 AuthProvider: Unauthorized - Logging out');

  await logout();

  AppRouter.router.go('/login');
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

  // ============================================================
  // SETTERS
  // ============================================================

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

  // ============================================================
  // STORAGE
  // ============================================================

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
  Future<void> clearStorageNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    _apiService.clearAuthToken();
  }
  // ============================================================
  // SIGN UP
  // ============================================================

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

  // ============================================================
  // SIGN IN
  // ============================================================

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

  // ============================================================
  // SIGN IN WITH GOOGLE
  // ============================================================

Future<bool> signInWithGoogle() async {
    _addLog('INFO', 'Google Sign-In started');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _addLog('INFO', 'Attempting Google sign-in');
      _addLog('INFO', 'Client ID being used: ${_googleSignIn.serverClientId}');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _addLog('ERROR', 'User canceled sign-in');
        _error = 'Google Sign-In was cancelled by the user.';
        _isLoading = false;
        notifyListeners();
        return false; 
      }

      _addLog('INFO', 'User signed in: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      _addLog('INFO', 'Got authentication tokens');

      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        _addLog('ERROR', 'ID Token is NULL or empty!');
        _error = 'Google authentication failed: ID Token is missing.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _addLog('INFO', 'ID Token received: ${googleAuth.idToken!.substring(0, 20)}...');
      _addLog('INFO', 'Access Token received: ${googleAuth.accessToken}');

      try {
        _addLog('INFO', 'Sending credentials to backend API');
        
        final result = await _apiService.signUpWithGoogle(
          name: googleUser.displayName ?? googleUser.email.split('@').first ?? 'User',
          email: googleUser.email ?? '',
          idtoken: googleAuth.idToken ?? '',
          accesstoken: googleAuth.accessToken ?? '',
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
          }
          
          _addLog('SUCCESS', 'Google Sign-In successful!');
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = result['message'] ?? 'Backend signup failed';
          _addLog('ERROR', 'Backend error: $_error');
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        _error = 'API Error during backend call: $e';
        _addLog('ERROR', 'API Error: $e');
        _isLoading = false;
        notifyListeners();
        return false;
      }

    } catch (e) {
  _addLog('ERROR', 'PlatformException caught!');

  if (e is PlatformException) {
    // 1. Extract the basic error info
    final String code = e.code;
    final String message = e.message ?? 'No message';
    
    // 2. Extract the detailed inner exception
    final String details = e.details?.toString() ?? 'No details';
    
    // 3. Build a comprehensive error string
    _error = 'Google Sign-In Error: Code: $code | Message: $message | Details: $details. '
             'Check if SHA-1 and Client ID "${_googleSignIn.serverClientId}" are correctly added to Firebase.';
    
    // 4. Log everything separately
    _addLog('ERROR', 'PlatformException Code: $code');
    _addLog('ERROR', 'PlatformException Message: $message');
    _addLog('ERROR', 'PlatformException Details: $details');
    _addLog('ERROR', 'Client ID being used: ${_googleSignIn.serverClientId}');
    
    // 5. Print the full error object (NO stackTrace property here!)
    print('🔴 Full PlatformException: $e');
    
  } else {
    _error = 'Google Sign-In Error: $e';
    _addLog('ERROR', 'Full Error: $_error');
  }
  
  _isLoading = false;
  notifyListeners();
  return false;
}
  }
  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<bool> forgotPassword({
    required String email
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.forgotPassword(
        email: email,
      );

      if (result['success']) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to send reset email');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

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
  Future<void> logout() async {
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

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _apiService.deleteAccount();

      if (result['success']) {
        // Clear user data
        await _clearStorage();
        _user = null;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to delete account');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // VERIFY TOKEN
  // ============================================================

  Future<bool> verifyToken() async {
    if (_user?.token == null) return false;

    try {
      final result = await _apiService.verifyToken();

      if (result['success']) {
        final data = result['data'];
        final userData = data['user'] ?? data;
        _user = UserModel.fromJson(userData);
        notifyListeners();
        return true;
      } else {
        await _clearStorage();
        _user = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      await _clearStorage();
      _user = null;
      notifyListeners();
      return false;
    }
  }
}