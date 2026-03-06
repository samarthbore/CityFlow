// lib/api/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/provider.dart';

class ApiService {
  // Production Cloud URL (Render)
  static const String BASE_URL = 'https://city-queue-api.onrender.com/api'; 
  static const String SOCKET_URL = 'https://city-queue-api.onrender.com'; 
  
  // --- SOCKET.IO ---
  late IO.Socket socket;
  
  void initializeSocket() {
    socket = IO.io(SOCKET_URL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    socket.onConnect((_) => print('Socket Connected!'));
    socket.onError((data) => print('Socket Error: $data'));
  }
  
  IO.Socket getSocket() => socket;
  
  // --- API CALLS ---
  
  // 1. Get List of Providers
  Future<List<Provider>> getProviders() async {
    final url = Uri.parse('$BASE_URL/providers'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Provider.fromJson(data)).toList();
      } else {
        // Handle API-specific errors (e.g., 404, 500)
        print('API Error (getProviders): ${response.statusCode}');
        return []; 
      }
    } catch (e) {
      // Handle network errors (e.g., connection refused, DNS lookup failed)
      print('Network Error (getProviders): $e');
      return []; 
    }
  }

  // 2. Join Queue (Error handling added)
  Future<Map<String, dynamic>> joinQueue({
    required String providerId,
    required String userName,
    required String userPhone,
  }) async {
    final url = Uri.parse('$BASE_URL/queues/join');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'providerId': providerId,
          'userName': userName,
          'userPhone': userPhone,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        // Handle API-specific errors
        final errorBody = json.decode(response.body);
        throw Exception('Failed to join queue: ${errorBody['message']} (Status: ${response.statusCode})');
      }
    } catch (e) {
      // Handle network errors
      print('Network Error (joinQueue): $e');
      // Re-throw or return a structured error based on app needs
      throw Exception('Failed to connect to the server or unknown error occurred.'); 
    }
  }

  // 3. Get Queue Status for a specific Provider (Error handling added)
  Future<Map<String, dynamic>> getQueueStatus(String providerId) async {
    final url = Uri.parse('$BASE_URL/queues/$providerId/status');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Handle API-specific errors
        print('API Error (getQueueStatus): ${response.statusCode}');
        return {}; // Return empty map on non-200 status
      }
    } catch (e) {
      // Handle network errors
      print('Network Error (getQueueStatus): $e');
      return {}; // Return empty map on network failure
    }
  }

  // 3b. Cancel Queue Entry
  Future<void> cancelQueueEntry(String queueId) async {
    final url = Uri.parse('$BASE_URL/queues/cancel');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'queueId': queueId}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel queue: ${response.body}');
      }
    } catch (e) {
      print('Network Error (cancelQueueEntry): $e');
      rethrow;
    }
  }

  // 4. Staff Login
  Future<Map<String, dynamic>> loginStaff(String email, String password) async {
    final url = Uri.parse('$BASE_URL/staff/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      print('Network Error (loginStaff): $e');
      rethrow;
    }
  }

  // 5. Call Next User
  Future<Map<String, dynamic>> callNext(String token, String providerId) async {
    final url = Uri.parse('$BASE_URL/staff/callNext/$providerId');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to call next: ${response.body}');
      }
    } catch (e) {
      print('Network Error (callNext): $e');
      rethrow;
    }
  }

  // 6. Mark as Served
  Future<Map<String, dynamic>> serve(String token, String entryId) async {
    final url = Uri.parse('$BASE_URL/staff/serve/$entryId');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to serve: ${response.body}');
      }
    } catch (e) {
      print('Network Error (serve): $e');
      rethrow;
    }
  }

  // 7. Update Provider Settings
  Future<Map<String, dynamic>> updateProviderSettings({
    required String token,
    required bool isOpen,
    required int avgServiceTime,
  }) async {
    final url = Uri.parse('$BASE_URL/staff/update-settings');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'isOpen': isOpen,
          'avgServiceTime': avgServiceTime,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update settings: ${response.body}');
      }
    } catch (e) {
      print('Network Error (updateProviderSettings): $e');
      rethrow;
    }
  }
  // 8. Get User History
  Future<List<dynamic>> getHistory(String phone) async {
    final url = Uri.parse('$BASE_URL/queues/history/$phone');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('API Error (getHistory): ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Network Error (getHistory): $e');
      return [];
    }
  }

  // 9. User Login
  Future<Map<String, dynamic>> loginUser(String identifier, String password) async {
    final url = Uri.parse('$BASE_URL/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identifier': identifier, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Network Error (loginUser): $e');
      rethrow;
    }
  }

  // 10. User Signup
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String identifier,
    required String password,
  }) async {
    final url = Uri.parse('$BASE_URL/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'identifier': identifier,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Signup failed');
      }
    } catch (e) {
      print('Network Error (registerUser): $e');
      rethrow;
    }
  }

  // 11. Update Profile
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? phone,
  }) async {
    final url = Uri.parse('$BASE_URL/auth/update-profile');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Update failed');
      }
    } catch (e) {
      print('Network Error (updateProfile): $e');
      rethrow;
    }
  }
  
  // 15. Verify Password
  Future<bool> verifyPassword({
    required String token,
    required String password,
  }) async {
    final url = Uri.parse('$BASE_URL/auth/verify-password');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'password': password}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Network Error (verifyPassword): $e');
      rethrow;
    }
  }

  // 12. Change Password
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$BASE_URL/auth/change-password');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Password change failed');
      }
    } catch (e) {
      print('Network Error (changePassword): $e');
      rethrow;
    }
  }

  // 13. Add Address
  Future<List<dynamic>> addAddress({
    required String token,
    required String label,
    required String address,
    bool isDefault = false,
  }) async {
    final url = Uri.parse('$BASE_URL/auth/address');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'label': label,
          'address': address,
          'isDefault': isDefault,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to add address');
      }
    } catch (e) {
      print('Network Error (addAddress): $e');
      rethrow;
    }
  }

  // 14. Delete Address
  Future<List<dynamic>> deleteAddress({
    required String token,
    required String addressId,
  }) async {
    final url = Uri.parse('$BASE_URL/auth/address/$addressId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to delete address');
      }
    } catch (e) {
      print('Network Error (deleteAddress): $e');
      rethrow;
    }
  }

  // 15. Forgot Password - Request OTP
  static Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$BASE_URL/auth/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('Network Error (forgotPassword): $e');
      rethrow;
    }
  }

  // 16. Reset Password with OTP
  static Future<void> resetPassword(String email, String otp, String newPassword) async {
    final url = Uri.parse('$BASE_URL/auth/reset-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('Network Error (resetPassword): $e');
      rethrow;
    }
  }

  // 17. Send OTP for verification
  static Future<void> sendOTP(String email) async {
    final url = Uri.parse('$BASE_URL/auth/send-otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('Network Error (sendOTP): $e');
      rethrow;
    }
  }

  // 18. Verify OTP
  static Future<void> verifyOTP(String email, String otp) async {
    final url = Uri.parse('$BASE_URL/auth/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to verify OTP');
      }
    } catch (e) {
      print('Network Error (verifyOTP): $e');
      rethrow;
    }
  }

  // 19. Get QR Info (provider info before joining)
  Future<Map<String, dynamic>> getQRInfo(String qrCode) async {
    final url = Uri.parse('$BASE_URL/queues/qr-info/$qrCode');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Invalid QR code');
      }
    } catch (e) {
      print('Network Error (getQRInfo): $e');
      rethrow;
    }
  }

  // 20. Join Queue by QR Code
  Future<Map<String, dynamic>> joinQueueByQR({
    required String qrCode,
    required String userName,
    required String userPhone,
  }) async {
    final url = Uri.parse('$BASE_URL/queues/join-by-qr/$qrCode');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userName': userName, 'userPhone': userPhone}),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to join queue');
      }
    } catch (e) {
      print('Network Error (joinQueueByQR): $e');
      rethrow;
    }
  }

  // 21. Submit Review
  static Future<void> submitReview({
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    final url = Uri.parse('$BASE_URL/reviews');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'providerId': providerId,
          'rating': rating,
          'comment': comment ?? '',
        }),
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to submit review');
      }
    } catch (e) {
      print('Network Error (submitReview): $e');
      rethrow;
    }
  }

  // 22. Get Available Appointment Slots
  static Future<Map<String, dynamic>> getAvailableSlots(String providerId, String date) async {
    final url = Uri.parse('$BASE_URL/appointments/slots/$providerId/$date');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to get slots');
      }
    } catch (e) {
      print('Network Error (getAvailableSlots): $e');
      rethrow;
    }
  }

  // 23. Book Appointment
  static Future<void> bookAppointment({
    required String providerId,
    required String date,
    required String timeSlot,
    String? notes,
  }) async {
    final url = Uri.parse('$BASE_URL/appointments');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'providerId': providerId,
          'date': date,
          'timeSlot': timeSlot,
          'notes': notes ?? '',
        }),
      );
      if (response.statusCode != 201) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to book appointment');
      }
    } catch (e) {
      print('Network Error (bookAppointment): $e');
      rethrow;
    }
  }

  // 24. Get Analytics Dashboard Data with date range
  static Future<Map<String, dynamic>> getAnalytics(String token, String providerId, {String period = 'today', String? startDate, String? endDate}) async {
    var queryParams = '?period=$period';
    if (startDate != null) queryParams += '&startDate=$startDate';
    if (endDate != null) queryParams += '&endDate=$endDate';
    
    final url = Uri.parse('$BASE_URL/analytics/dashboard/$providerId$queryParams');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load analytics');
      }
    } catch (e) {
      print('Network Error (getAnalytics): $e');
      rethrow;
    }
  }

  // 25. Get Served Customers with search
  static Future<Map<String, dynamic>> getServedCustomers(String token, String providerId, {String period = 'today', String? startDate, String? endDate, String search = '', int page = 1}) async {
    var queryParams = '?period=$period&search=$search&page=$page';
    if (startDate != null) queryParams += '&startDate=$startDate';
    if (endDate != null) queryParams += '&endDate=$endDate';
    
    final url = Uri.parse('$BASE_URL/analytics/served/$providerId$queryParams');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load served customers');
      }
    } catch (e) {
      print('Network Error (getServedCustomers): $e');
      rethrow;
    }
  }

  // 26. Check for active queue entry by phone/email
  static Future<Map<String, dynamic>> checkActiveQueue(String identifier) async {
    final url = Uri.parse('$BASE_URL/queue/active-queue/$identifier');
    try {
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'hasActiveQueue': false, 'entry': null};
      }
    } catch (e) {
      print('Network Error (checkActiveQueue): $e');
      return {'hasActiveQueue': false, 'entry': null};
    }
  }

  // 27. Undo Call Next - Staff reverts accidental call
  static Future<Map<String, dynamic>> undoCallNext(String providerId) async {
    final url = Uri.parse('$BASE_URL/queues/undo-call');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'providerId': providerId}),
      );
      return json.decode(response.body);
    } catch (e) {
      print('Network Error (undoCallNext): $e');
      rethrow;
    }
  }

  // 28. Add Manual Customer - Staff adds offline walk-in
  static Future<Map<String, dynamic>> addManualCustomer({
    required String providerId,
    required String userName,
    String? userPhone,
  }) async {
    final url = Uri.parse('$BASE_URL/queues/add-manual');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'providerId': providerId,
          'userName': userName,
          'userPhone': userPhone,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to add customer');
      }
    } catch (e) {
      print('Network Error (addManualCustomer): $e');
      rethrow;
    }
  }

  // 29. Mark Not Present - Staff marks customer as absent
  static Future<Map<String, dynamic>> markNotPresent(String entryId) async {
    final url = Uri.parse('$BASE_URL/queues/mark-not-present');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'entryId': entryId}),
      );
      return json.decode(response.body);
    } catch (e) {
      print('Network Error (markNotPresent): $e');
      rethrow;
    }
  }
}