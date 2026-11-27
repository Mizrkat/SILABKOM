class ApiEndpoints {
  // Base Host default: Backend Cloud Vercel SILABKOM
  static const String defaultBaseUrl = 'https://silabkom-iota.vercel.app';

  // Active base URL (dapat diperbarui dinamis dari SessionManager jika ingin pindah server)
  static String currentBaseUrl = defaultBaseUrl;

  // Endpoint Paths
  static String get login => '$currentBaseUrl/api/auth/login';
  static String get register => '$currentBaseUrl/api/auth/register';
  static String get updateProfile => '$currentBaseUrl/api/auth/profile';
  static String profileById(String id) => '$currentBaseUrl/api/auth/profile/$id';
  static String get components => '$currentBaseUrl/api/components';
  static String componentById(String id) => '$currentBaseUrl/api/components/$id';
  static String restoreComponent(String id) => '$currentBaseUrl/api/components/$id/restore';
  static String get loans => '$currentBaseUrl/api/loans';
  static String loanById(String id) => '$currentBaseUrl/api/loans/$id';
  static String restoreLoan(String id) => '$currentBaseUrl/api/loans/$id/restore';
  static String updateLoanStatus(String id) => '$currentBaseUrl/api/loans/$id/status';
}
