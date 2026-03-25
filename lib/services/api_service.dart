import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/db_product.dart';
import '../models/customer_profile.dart';

class ApiService {
  // Backend URL - Change to your server IP if needed
  static const String baseUrl = 'http://localhost:3000/api';
  
  static String? _token;
  static String? _currentEmail;
  static String? _currentRole;

  static bool get isAdmin => _currentRole == 'admin';

  // ============ Authentication ============

  static Future<bool> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentEmail = email;
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('SignUp error: $e');
      return false;
    }
  }

  static Future<bool> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] ?? false) {
          _token = data['token'];
          _currentEmail = email;
          _currentRole = (data['user']?['role']?.toString() ?? 'user');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('SignIn error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Content-Type': 'application/json'},
      );
      _token = null;
      _currentEmail = null;
    } catch (e) {
      print('SignOut error: $e');
    }
  }

  static bool get isLoggedIn => _token != null && _currentEmail != null;
  static String? get currentEmail => _currentEmail;
  static String? get token => _token;

  // ============ Products ============

  static Future<List<DbProduct>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] ?? false) {
          final List<dynamic> productsJson = data['data'] ?? [];
          return productsJson
              .map((p) => DbProduct.fromMap(Map<String, dynamic>.from(p)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Get products error: $e');
      return [];
    }
  }

  static Future<DbProduct?> getProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] ?? false) {
          return DbProduct.fromMap(Map<String, dynamic>.from(data['data']));
        }
      }
      return null;
    } catch (e) {
      print('Get product by ID error: $e');
      return null;
    }
  }

  // ============ Profile ============

  static Future<CustomerProfile?> getUserProfile(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$email'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] ?? false) {
          return CustomerProfile.fromMap(
            Map<String, dynamic>.from(data['data']),
          );
        }
      }
      return null;
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }

  static Future<void> updateUserProfileData({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    if (_currentEmail == null) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$_currentEmail'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          if (fullName != null) 'fullName': fullName,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        }),
      );

      if (response.statusCode != 200) {
        print('Update profile error: ${response.statusCode}');
      }
    } catch (e) {
      print('Update profile error: $e');
    }
  }

  // ============ Orders ============

  static Future<void> createOrder(
    List<Map<String, dynamic>> items,
    double totalPrice,
    int totalKhr,
  ) async {
    if (_currentEmail == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'email': _currentEmail,
          'items': items,
          'totalPrice': totalPrice,
          'totalKhr': totalKhr,
          'status': 'pending',
        }),
      );

      if (response.statusCode != 200) {
        print('Create order error: ${response.statusCode}');
      }
    } catch (e) {
      print('Create order error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    if (_currentEmail == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$_currentEmail'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] ?? false) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Get orders error: $e');
      return [];
    }
  }

  static Map<String, String> _authHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ============ Admin routes ============
  static Future<List<Map<String, dynamic>>> adminGetUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] ?? false) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
    } catch (e) {
      print('Admin get users error: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> adminGetProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/products'),
        headers: _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] ?? false) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
    } catch (e) {
      print('Admin get products error: $e');
    }
    return [];
  }

  static Future<bool> adminCreateProduct({
    required String name,
    String? description,
    required double price,
    required int khr,
    String? image,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/products'),
        headers: _authHeaders(),
        body: jsonEncode({
          'name': name,
          'description': description ?? '',
          'price': price,
          'khr': khr,
          'image': image ?? '',
        }),
      );
      return response.statusCode == 200 && (jsonDecode(response.body)['success'] ?? false);
    } catch (e) {
      print('Admin create product error: $e');
      return false;
    }
  }

  static Future<bool> adminUpdateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? khr,
    String? image,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/products/$id'),
        headers: _authHeaders(),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (khr != null) 'khr': khr,
          if (image != null) 'image': image,
        }),
      );
      return response.statusCode == 200 && (jsonDecode(response.body)['success'] ?? false);
    } catch (e) {
      print('Admin update product error: $e');
      return false;
    }
  }

  static Future<bool> adminDeleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/products/$id'),
        headers: _authHeaders(),
      );
      return response.statusCode == 200 && (jsonDecode(response.body)['success'] ?? false);
    } catch (e) {
      print('Admin delete product error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> adminGetOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/orders'),
        headers: _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] ?? false) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
    } catch (e) {
      print('Admin get orders error: $e');
    }
    return [];
  }
}


