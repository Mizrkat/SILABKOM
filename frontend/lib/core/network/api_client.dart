import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  static const Duration timeoutDuration = Duration(seconds: 12);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // GET Request
  static Future<dynamic> get(String url, {Map<String, String>? queryParams}) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers).timeout(timeoutDuration);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis (Timeout 12 detik). Pastikan HP dan Laptop terhubung ke Wi-Fi yang sama, serta atur IP Server sesuai IP Laptop Anda.');
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Pastikan backend aktif dan atur IP Server ke IP Laptop Anda (misal: http://192.168.1.2:3000).');
    } on http.ClientException {
      throw ApiException('Koneksi gagal. Cek pengaturan jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kendala: ${e.toString()}');
    }
  }

  // POST Request
  static Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis (Timeout 12 detik). Pastikan HP dan Laptop berada di jaringan Wi-Fi yang sama, dan atur IP Server ke IP Laptop (misal: http://192.168.1.2:3000).');
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Pastikan backend di laptop sudah berjalan dan atur IP Server ke IP Laptop Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kendala saat mengirim data: ${e.toString()}');
    }
  }

  // PUT Request
  static Future<dynamic> put(String url, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis (Timeout 12 detik). Cek koneksi Wi-Fi dan IP Server.');
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kendala saat memperbarui data: ${e.toString()}');
    }
  }

  // PATCH Request
  static Future<dynamic> patch(String url, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .patch(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis (Timeout 12 detik). Cek koneksi Wi-Fi dan IP Server.');
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kendala saat memperbarui status: ${e.toString()}');
    }
  }

  // DELETE Request
  static Future<dynamic> delete(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.delete(uri, headers: _headers).timeout(timeoutDuration);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis (Timeout 12 detik). Cek koneksi Wi-Fi dan IP Server.');
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kendala saat menghapus data: ${e.toString()}');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Permintaan gagal dengan status ${response.statusCode}';
    throw ApiException(message, response.statusCode);
  }
}
