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
  static const String jobApplied = '$baseUrl/jobs/apply';
  static const String toggleSaveJob = '$baseUrl/toggle-save-job';
  static const String myJobs = '$baseUrl/myjobs';
  static const String deleteAccount = '$baseUrl/delete-account';
  
  // Headers
  static const String contentType = 'application/json';
}