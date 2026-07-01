import 'dart:convert';
// import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String baseUrl = kIsWeb
      ? 'http://localhost:8000/api'
      : (defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:8000/api' : 'http://127.0.0.1:8000/api');
  static final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

  static Future<String?> _getToken() async {
    return (await SharedPreferences.getInstance()).getString('token');
  }

  static Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    Map<String, String> headers = {'Accept': 'application/json'};
    String? token = auth ? await _getToken() : null;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<String?> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'), 
        headers: await _getHeaders(auth: false), 
        body: {'name': name, 'email': email, 'password': password}
      ).timeout(const Duration(seconds: 10));

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (_) {}

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (data != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setBool('is_admin', data['user']['is_admin'] ?? false);
          return null;
        }
        return 'Error processing data received from the server.';
      } else {
        if (data is Map) {
          if (data.containsKey('errors')) {
            var errors = data['errors'] as Map;
            return errors.values.map((e) => (e as List).join(', ')).join('\n');
          }
          if (data.containsKey('message')) {
            return data['message'];
          }
        }
        return 'Registration failed. Status code: ${res.statusCode}';
      }
    } catch (e) {
      return 'Make sure the server is running or check the server IP address. Error: $e';
    }
  }

  static Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'), 
        headers: await _getHeaders(auth: false), 
        body: {'email': email, 'password': password}
      ).timeout(const Duration(seconds: 10));

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (_) {}

      if (res.statusCode == 200) {
        if (data != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setBool('is_admin', data['user']['is_admin'] ?? false);
          return null;
        }
        return 'Error processing data received from the server.';
      } else {
        if (data is Map) {
          if (data.containsKey('errors')) {
            var errors = data['errors'] as Map;
            return errors.values.map((e) => (e as List).join(', ')).join('\n');
          }
          if (data.containsKey('message')) {
            return data['message'];
          }
        }
        return 'Login failed. Status code: ${res.statusCode}';
      }
    } catch (e) {
      return 'Make sure the server is running or check the server IP address. Error: $e';
    }
  }

  static Future<bool> logout() async {
    final res = await http.post(Uri.parse('$baseUrl/logout'), headers: await _getHeaders());
    if (res.statusCode == 200) await (await SharedPreferences.getInstance()).remove('token');
    return res.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getDashboard() async {
    final res = await http.get(Uri.parse('$baseUrl/dashboard'), headers: await _getHeaders());
    return res.statusCode == 200 ? jsonDecode(res.body) : null;
  }

  static Future<List<dynamic>> getCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories'), headers: await _getHeaders());
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<bool> addCategory(String name) async {
    final res = await http.post(Uri.parse('$baseUrl/categories'), headers: await _getHeaders(), body: {'name': name});
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> deleteCategory(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/categories/$id'), headers: await _getHeaders());
    return res.statusCode == 200 || res.statusCode == 204;
  }
  static Future<List<dynamic>> getProducts({String? search, String? sort}) async {
    String url = '$baseUrl/products?';
    if (search != null && search.isNotEmpty) url += 'search=$search&';
    if (sort != null && sort.isNotEmpty) url += 'sort=$sort';
    
    final res = await http.get(Uri.parse(url), headers: await _getHeaders());
    return res.statusCode == 200 ? (jsonDecode(res.body)['data'] ?? []) : [];
  }

  static Future<bool> _sendProductRequest(String method, String url, String title, String price, String categoryId, String priority, String description, String note, String date, List<String> imagePaths) async {
    var req = http.MultipartRequest(method, Uri.parse(url))..headers.addAll(await _getHeaders());
    req.fields.addAll({'title': title, 'price': price, 'category_id': categoryId, 'Budget_Range': priority});
    if (description.isNotEmpty) req.fields['description'] = description;
    if (note.isNotEmpty) req.fields['note'] = note;
    if (date.isNotEmpty) req.fields['date'] = date;

    for (var path in imagePaths) {
      req.files.add(await http.MultipartFile.fromPath('images[]', path));
    }
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200 && res.statusCode != 201) {
      debugPrint('Failed to save product: Status ${res.statusCode}, Body: ${res.body}');
    }
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> addProduct(String title, String price, String categoryId, String priority, String description, String note, String date, List<String> imagePaths) {
    return _sendProductRequest('POST', '$baseUrl/products', title, price, categoryId, priority, description, note, date, imagePaths);
  }

  static Future<bool> updateProduct(int id, String title, String price, String categoryId, String priority, String description, String note, String date, List<String> imagePaths) {
    return _sendProductRequest('POST', '$baseUrl/products/$id', title, price, categoryId, priority, description, note, date, imagePaths);
  }

  static Future<bool> deleteProduct(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/products/$id'), headers: await _getHeaders());
    return res.statusCode == 200 || res.statusCode == 204;
  }

  static Future<List<dynamic>> getDeletedProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/deleted-products'), headers: await _getHeaders());
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }
  static Future<Map<String, dynamic>?> getCart() async {
    final res = await http.get(Uri.parse('$baseUrl/cart'), headers: await _getHeaders());
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data != null && data['total_items'] != null) cartCountNotifier.value = int.tryParse(data['total_items'].toString()) ?? 0;
      return data;
    }
    return null;
  }

  static Future<bool> addToCart(int productId, int quantity) async {
    final res = await http.post(Uri.parse('$baseUrl/cart/add'), headers: await _getHeaders(), body: {'product_id': productId.toString(), 'quantity': quantity.toString()});
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      if (data?['cart']?['total_items'] != null) cartCountNotifier.value = int.tryParse(data['cart']['total_items'].toString()) ?? 0;
      return true;
    }
    return false;
  }

  static Future<bool> updateCartItem(int cartItemId, int quantity) async {
    final res = await http.put(Uri.parse('$baseUrl/cart/items/$cartItemId'), headers: await _getHeaders(), body: {'quantity': quantity.toString()});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data?['cart']?['total_items'] != null) cartCountNotifier.value = int.tryParse(data['cart']['total_items'].toString()) ?? 0;
      return true;
    }
    return false;
  }

  static Future<bool> removeFromCart(int cartItemId) async {
    final res = await http.delete(Uri.parse('$baseUrl/cart/items/$cartItemId'), headers: await _getHeaders());
    if (res.statusCode == 200 || res.statusCode == 204) {
      final data = jsonDecode(res.body);
      if (data?['cart']?['total_items'] != null) cartCountNotifier.value = int.tryParse(data['cart']['total_items'].toString()) ?? 0;
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/profile'), headers: await _getHeaders());
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_admin', data['is_admin'] ?? false);
      return data;
    }
    return null;
  }

  static Future<bool> updateCategory(int id, String name) async {
    final res = await http.put(Uri.parse('$baseUrl/categories/$id'), headers: await _getHeaders(), body: {'name': name});
    return res.statusCode == 200;
  }

  static Future<bool> restoreProduct(int id) async {
    final res = await http.post(Uri.parse('$baseUrl/products/$id/restore'), headers: await _getHeaders());
    return res.statusCode == 200;
  }
  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_admin') ?? false;
  }

  static Future<Map<String, dynamic>?> createOrder({
    required String address,
    required String phone,
    required String paymentMethod,
    required double totalPrice,
    required List<dynamic> items,
    required List<int> cartItemIds,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          ...(await _getHeaders()),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'address': address,
          'phone': phone,
          'payment_method': paymentMethod,
          'total_price': totalPrice,
          'items': items,
          'cart_item_ids': cartItemIds,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        debugPrint('Failed to create order: ${res.statusCode} - ${res.body}');
        throw Exception('Server Error: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: await _getHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && decoded.containsKey('data') && decoded['data'] is List) {
          return decoded['data'] as List<dynamic>;
        } else if (decoded is Map && decoded.containsKey('orders') && decoded['orders'] is List) {
          return decoded['orders'] as List<dynamic>;
        }
      } else {
        debugPrint('Failed to get orders: Status ${res.statusCode}, Body: ${res.body}');
      }
      return [];
    } catch (e) {
      debugPrint('Error getting orders: $e');
      return [];
    }
  }
}