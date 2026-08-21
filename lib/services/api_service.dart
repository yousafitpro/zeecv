import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // Required for IOHttpClientAdapter
import 'package:flutter/services.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  // Singleton setup
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  String? _authToken;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.contentType,
        },
      ),
    );

    // ============================================================
    // ADD INTERCEPTOR TO AUTO-ADD AUTH TOKEN
    // ============================================================
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Automatically add token to all requests if available
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  // ============================================================
  // LOAD JOBS
  // ============================================================
  
  /// Load jobs with optional search query
  /// 
  /// Example payload:
  /// {
  ///   "search": "flutter"
  /// }
  Future<Map<String, dynamic>> loadJobs({
    String? search,
  }) async {
    try {
      final payload = <String, dynamic>{};
      
      if (search != null && search.isNotEmpty) {
        payload['search'] = search;
      }
      
      final response = await _dio.post(
        ApiConstants.jobs,
        data: payload,
      );

      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================
  // GET JOB DETAILS
  // ============================================================
  
  /// Get job details by slug
  Future<Map<String, dynamic>> getJobDetails(String slug) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.jobs}/$slug',
      );

      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return _handleError(e);
    }
  }

  /// IMPORTANT: Call this in your main.dart or before first API call
  /// to initialize the SSL certificate fix.
  Future<void> init() async {
    try {
      // 1. Load the SSL.com Root CA 2022 from assets
      final sslCert = await rootBundle.load('assets/certs/root_ca.pem');
      
      // 2. Configure SecurityContext to trust this certificate
      SecurityContext context = SecurityContext(withTrustedRoots: true);
      context.setTrustedCertificatesBytes(sslCert.buffer.asUint8List());

      // 3. Apply the custom HttpClient to Dio
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient(context: context);
          return client;
        },
      );
      print("Network: SSL Certificate initialized successfully.");
    } catch (e) {
      print("Network: Failed to initialize SSL certificate: $e");
    }
  }

  void setAuthToken(String token) {
    _authToken = token;
    // The interceptor will automatically add this to all requests
    // No need to manually set headers here anymore
  }

  void clearAuthToken() {
    _authToken = null;
    // The interceptor will stop adding the token
  }

  // Helper to handle Dio errors consistently
  Map<String, dynamic> _handleError(dynamic e) {
    String message = "An unexpected error occurred";
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError && 
          e.error.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        message = "SSL Certificate Error: Please ensure the app is up to date.";
      } else {
        message = e.response?.data['message'] ?? 
                  e.response?.data['error'] ?? 
                  e.message;
      }
    }
    return {'success': false, 'message': message};
  }

  // --- API Methods ---

  Future<Map<String, dynamic>> signUpWithGoogle({
    required String name,
    required String email,
    required String idtoken,
    required String accesstoken,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.signupwithgoogle,
        data: {
          'name': name,
          'email': email,
          'idtoken': idtoken,
          'accesstoken': accesstoken
        },
      );
      final data = response.data;
      if (data['token'] != null) {
        setAuthToken(data['token']);
      }
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.signup,
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.signin,
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      if (data['token'] != null) {
        setAuthToken(data['token']);
      }

      return {
        'success': true,
        'data': data,
      };
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {
          'email': email
        },
      );

      final data = response.data;

      return {
        'success': true,
        'data': data,
      };
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> signOut() async {
    try {
      final response = await _dio.post(ApiConstants.signout);
      clearAuthToken();
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      clearAuthToken();
      return {
        'success': true, 
        'message': 'Logged out locally',
      };
    }
  }

  Future<Map<String, dynamic>> verifyToken() async {
    if (_authToken == null) return {'success': false, 'message': 'No token found'};

    try {
      final response = await _dio.post(ApiConstants.verifyToken);
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return _handleError(e);
    }
  }
}