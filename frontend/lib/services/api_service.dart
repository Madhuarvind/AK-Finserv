import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  // Replace with your machine's IP (e.g., 192.168.1.5) if testing on a physical device
  static const String _serverAddress = '192.168.4.138'; 

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api/auth';
    }
    // Check non-web platforms
    if (Platform.isWindows) {
      return 'http://127.0.0.1:5000/api/auth';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/auth';
    }
    return 'http://$_serverAddress:5000/api/auth';
  }
  final _storage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String?> _getDeviceId() async {
    if (kIsWeb) return 'web_device';
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
    } catch (e) {
      return 'unknown_device';
    }
    return 'desktop_device';
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'jwt_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> saveUserData(String name, String role) async {
    await _storage.write(key: 'user_name', value: name);
    await _storage.write(key: 'user_role', value: role);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: 'user_name');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_role');
  }

  // Silent Login / Refresh Logic
  Future<bool> ensureAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    
    // Check if token is expired (simulated here, but real app would check JWT payload)
    // For now, we attempt to refresh if any error occurs in other calls
    return true;
  }

  Future<Map<String, dynamic>> sendOtp(String mobileNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_number': mobileNumber}),
      ).timeout(const Duration(seconds: 10));
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'Error: $e'}; 
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String mobileNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_number': mobileNumber, 'otp': otp}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed', 'details': e.toString()};
    }
  }

  Future<Map<String, dynamic>> setPin(String name, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/set-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'pin': pin}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed', 'details': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loginPin(String name, String pin) async {
    final deviceId = await _getDeviceId();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name, 
          'pin': pin,
          'device_id': deviceId
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed', 'details': e.toString()};
    }
  }

  Future<Map<String, dynamic>> registerWorker(
    String name, 
    String mobile, 
    String pin, 
    String token, {
    String? area,
    String? address,
    String? idProof,
    String? role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register-worker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'mobile_number': mobile, 
          'pin': pin,
          'area': area,
          'address': address,
          'id_proof': idProof,
          'role': role ?? 'field_agent',
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed', 'details': e.toString()};
    }
  }

  Future<Map<String, dynamic>> registerFace(int userId, List<double> embedding, String? deviceId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register-face'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'embedding': embedding,
          'device_id': deviceId
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed', 'details': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetDevice(int userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed', 'details': e.toString()};
    }
  }

  Future<List<dynamic>> getUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('API Error: $e');
      return []; 
    }
  }

  Future<Map<String, dynamic>> getUserDetail(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> data, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> patchUserStatus(int userId, Map<String, dynamic> statusData, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(statusData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> clearBiometrics(int userId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/biometrics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> resetUserPin(int userId, String newPin, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/reset-pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'new_pin': newPin}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> deleteUser(int userId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> getUserBiometrics(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/biometrics-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed', 'has_biometric': false};
    }
  }

  Future<Map<String, dynamic>> getUserLoginStats(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/login-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed', 'total_logins': 0, 'failed_logins': 0};
    }
  }

  Future<Map<String, dynamic>> adminLogin(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username, 
          'password': password
        }),
      );
      print('AdminLogin Response: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed'}; 
    }
  }

  Future<Map<String, dynamic>> adminVerify(String mobileNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_number': mobileNumber, 'otp': otp}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed'}; 
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed'}; 
    }
  }

  Future<Map<String, dynamic>> verifyFaceLogin(
    String name, 
    List<double> embedding
  ) async {
    final deviceId = await _getDeviceId();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-face-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'embedding': embedding,
          'device_id': deviceId
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      return {'msg': 'connection_failed', 'details': e.toString()};
    }
  }

  Future<List<dynamic>> getAuditLogs(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/audit-logs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Audit Logs API Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getMyProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  Future<List<dynamic>> getMyTeam(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-team'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getPerformanceStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats/performance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  // Collection & Customer Management
  Future<List<dynamic>> getCustomers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/collection/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/collection/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  Future<List<dynamic>> getCustomerLoans(int customerId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/collection/loans/$customerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submitCollection({
    required int loanId,
    required double amount,
    required String paymentMode,
    double? latitude,
    double? longitude,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/collection/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'loan_id': loanId,
          'amount': amount,
          'payment_mode': paymentMode,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 10));
      print('SubmitCollection Response: ${response.statusCode}');
      print('SubmitCollection Body: ${response.body}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        return {'msg': 'Server Error: ${response.statusCode}', 'body': response.body};
      }
      return jsonDecode(response.body);
    } catch (e) {
      print('SubmitCollection Error: $e');
      return {'msg': 'connection_failed: $e'};
    }
  }

  Future<List<dynamic>> getPendingCollections(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/collection/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> updateCollectionStatus(int collectionId, String status, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/collection/$collectionId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> getFinancialStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/collection/stats/financials'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  // Line Management
  Future<Map<String, dynamic>> createLine(Map<String, dynamic> data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/line/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  Future<List<dynamic>> getAllLines(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/line/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> assignLineAgent(int lineId, int agentId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/line/$lineId/assign-agent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'agent_id': agentId}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> toggleLineLock(int lineId, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/line/$lineId/lock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  Future<List<dynamic>> getLineCustomers(int lineId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/line/$lineId/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addCustomerToLine(int lineId, int customerId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/line/$lineId/add-customer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'customer_id': customerId}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> reorderLineCustomers(int lineId, List<int> order, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/line/$lineId/reorder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'order': order}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }
  // --- Customer Sync ---
  Future<Map<String, dynamic>?> syncCustomers(List<Map<String, dynamic>> customers, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/customer/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'customers': customers}),
      ).timeout(const Duration(seconds: 30));

      print('Sync Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Sync error: $e');
      return null;
    }
  }
  // --- Customer Management (Admin/Online) ---
  Future<Map<String, dynamic>> getAllCustomers({int page = 1, String search = '', String token = ''}) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/customer/list?page=$page&search=$search'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'customers': [], 'total': 0};
    } catch (e) {
      print('GetAllCustomers error: $e');
      return {'customers': [], 'total': 0};
    }
  }

  Future<Map<String, dynamic>?> getCustomerDetail(int id, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/customer/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('GetCustomerDetail error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createCustomerOnline(Map<String, dynamic> customerData, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/customer/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(customerData),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      print('Create customer online error: $e');
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> updateCustomer(int id, Map<String, dynamic> data, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/customer/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  // --- Loan Management ---
  Future<Map<String, dynamic>> createLoan(Map<String, dynamic> data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/loan/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  // Phase 3A: Production Customer Management
  Future<Map<String, dynamic>> updateCustomerStatus(int id, String status, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/customer/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> toggleCustomerLock(int id, bool lock, String token) async {
    try {
      final endpoint = lock ? 'lock' : 'unlock';
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/customer/$id/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'msg': 'connection_failed'};
    }
  }

  Future<Map<String, dynamic>> checkDuplicateCustomer(String name, String mobile, String area, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl.replaceFirst('/auth', '')}/customer/check-duplicate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'mobile_number': mobile,
          'area': area,
        }),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'duplicates_found': false, 'count': 0, 'duplicates': []};
    }
  }
}
