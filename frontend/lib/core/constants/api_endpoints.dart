import 'dart:io';

class ApiEndpoints {
  // Base Host default: 10.0.2.2 untuk Android emulator, localhost untuk lainnya
  static String get defaultBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  // Active base URL (dapat diperbarui dinamis dari SessionManager saat testing di device fisik)
  static String currentBaseUrl = defaultBaseUrl;

  // Endpoint Paths
  static String get login => '$currentBaseUrl/api/auth/login';
  static String get components => '$currentBaseUrl/api/components';
  static String componentById(String id) => '$currentBaseUrl/api/components/$id';
  static String restoreComponent(String id) => '$currentBaseUrl/api/components/$id/restore';
  static String get loans => '$currentBaseUrl/api/loans';
  static String loanById(String id) => '$currentBaseUrl/api/loans/$id';
  static String restoreLoan(String id) => '$currentBaseUrl/api/loans/$id/restore';
  static String updateLoanStatus(String id) => '$currentBaseUrl/api/loans/$id/status';
}
