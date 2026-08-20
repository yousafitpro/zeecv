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
        baseUrl: ApiConstants.baseUrl, // Assuming you have a baseUrl in constants
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.contentType,
        },
      ),
    );
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
          // Optional: You can still add a fail-safe (not recommended for strict production)
          // client.badCertificateCallback = (cert, host, port) => false; 
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
    // Add to default headers for all future requests
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
  }

  // Helper to handle Dio errors consistently
  Map<String, dynamic> _handleError(dynamic e) {
    String message = "An unexpected error occurred";
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError && e.error.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        message = "SSL Certificate Error: Please ensure the app is up to date.";
      } else {
        message = e.response?.data['message'] ?? e.response?.data['error'] ?? e.message;
      }
    }
    return {'success': false, 'message': message};
  }

  // --- API Methods ---

  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Dio automatically encodes Map to JSON
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
      if (data['token'] != null) {
        
      }

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