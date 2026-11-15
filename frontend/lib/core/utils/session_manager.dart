import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';

class SessionManager {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserNim = 'user_nim_nip';
  static const String _keyUserRole = 'user_role';
  static const String _keyCustomApiUrl = 'custom_api_url';

  // Simpan data login pengguna
  static Future<void> saveUserSession({
    required String id,
    required String name,
    required String nimNip,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserNim, nimNip);
    await prefs.setString(_keyUserRole, role);
  }

  // Cek apakah sudah ada sesi aktif
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<String?> getUserNim() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserNim);
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? 'student';
  }

  static Future<bool> isAssistant() async {
    final role = await getUserRole();
    return role == 'assistant';
  }

  static Future<bool> isStudent() async {
    final role = await getUserRole();
    return role == 'student';
  }

  // Kelola Custom API Base URL (mempermudah pengujian di Android fisik melalui IP LAN)
  static Future<void> saveCustomApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomApiUrl, url.trim());
    ApiEndpoints.currentBaseUrl = url.trim();
  }

  static Future<String> getCustomApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_keyCustomApiUrl);
    if (custom != null && custom.isNotEmpty) {
      ApiEndpoints.currentBaseUrl = custom;
      return custom;
    }
    return ApiEndpoints.defaultBaseUrl;
  }

  // Inisialisasi API URL saat start up aplikasi
  static Future<void> initApiUrl() async {
    final url = await getCustomApiUrl();
    ApiEndpoints.currentBaseUrl = url;
  }

  // Logout & hapus sesi
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserNim);
    await prefs.remove(_keyUserRole);
  }
}
