class ApiConstants {
  static const String baseUrl = 'https://zeecv.zpayd.com/api';
  
  // Auth endpoints
  static const String signup = '$baseUrl/signup';
  static const String signin = '$baseUrl/signin';
  static const String signout = '$baseUrl/signout';
  static const String verifyToken = '$baseUrl/verify-token';
  static const String forgotPassword = '$baseUrl/forgot-password';
  static const String resetPassword = '$baseUrl/reset-password';
  
  // Headers
  static const String contentType = 'application/json';
}