import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Store token for authenticated requests
  String? _authToken;
  
  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  // Headers for API requests
  Map<String, String> _getHeaders({bool isAuth = false}) {
    final headers = {
      'Content-Type': ApiConstants.contentType,
      'Accept': ApiConstants.contentType,
    };
    
    if (!isAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Sign Up
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.signup),
        headers: _getHeaders(isAuth: true),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Sign In
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.signin),
        headers: _getHeaders(isAuth: true),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Store token if present
        if (data['token'] != null) {
          _authToken = data['token'];
        }
        
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Invalid credentials',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Sign Out
  Future<Map<String, dynamic>> signOut() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.signout),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);
      _authToken = null;
      
      return {
        'success': response.statusCode == 200,
        'data': data,
      };
    } catch (e) {
      // Even if API fails, clear local token
      _authToken = null;
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  // Verify Token (optional - for checking if token is still valid)
  Future<Map<String, dynamic>> verifyToken() async {
    if (_authToken == null) {
      return {
        'success': false,
        'message': 'No token found',
      };
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyToken),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);
      
      return {
        'success': response.statusCode == 200,
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Token verification failed',
      };
    }
  }
}