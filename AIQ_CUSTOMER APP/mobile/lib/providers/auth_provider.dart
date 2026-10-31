import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_service.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  UserModel? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  Future<void> loadUser() async {
    _isInitializing = true;
    notifyListeners();

    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null) {
        _isAuthenticated = false;
        _isInitializing = false;
        notifyListeners();
        return;
      }

      final response = await ApiClient.instance.get('/users/me');
      _user = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
      _isAuthenticated = true;
      await SocketService.connect();
    } catch (_) {
      await SecureStorageService.clearTokens();
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> login({String? email, String? phone, required String password}) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post('/auth/login', data: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
      });

      final data = response.data['data'] as Map<String, dynamic>;
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await SecureStorageService.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );

      _isAuthenticated = true;
      await SocketService.connect();
    } catch (e) {
      _error = ApiClient.getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String address,
    required String lat,
    required String lng,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post('/auth/register', data: {
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'address': address,
        'lat': lat,
        'lng': lng,
      });

      final data = response.data['data'] as Map<String, dynamic>;
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await SecureStorageService.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );

      _isAuthenticated = true;
      await SocketService.connect();
    } catch (e) {
      _error = ApiClient.getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken != null) {
        await ApiClient.instance
            .post('/auth/logout', data: {'refreshToken': refreshToken})
            .catchError((_) {});
      }
    } finally {
      await SecureStorageService.clearTokens();
      SocketService.disconnect();
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.put('/users/me', data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      });

      _user = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      _error = ApiClient.getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
