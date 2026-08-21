class ApiConstants {
  static const String baseUrl = 'https://zeecv.com/api';
  
  // Auth endpoints
  static const String signup = '$baseUrl/auth/register';
  static const String signupwithgoogle = '$baseUrl/google/register';
  static const String signin = '$baseUrl/auth/login';
  static const String signout = '$baseUrl/logout';
  static const String verifyToken = '$baseUrl/verify-token';
  static const String forgotPassword = '$baseUrl/forgot-password';
  static const String resetPassword = '$baseUrl/reset-password';
  static const String jobs = '$baseUrl/jobs';
  static const String myJobs = '$baseUrl/jobs';
  
  // Headers
  static const String contentType = 'application/json';
}