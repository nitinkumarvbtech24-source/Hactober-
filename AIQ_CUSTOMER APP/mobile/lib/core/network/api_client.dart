import 'package:dio/dio.dart';
import 'dart:convert';
import '../storage/secure_storage.dart';
import '../utils/app_constants.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  static bool _interceptorSetup = false;

  static Map<String, dynamic>? _currentUser;
  static final List<Map<String, dynamic>> _accountsDb = [];
  static bool _isDbLoaded = false;

  static Dio get instance {
    if (!_interceptorSetup) {
      _setupInterceptors();
      _interceptorSetup = true;
    }
    return _dio;
  }

  static Future<void> _loadAccountsDb() async {
    if (_isDbLoaded) return;
    try {
      final savedDb = await SecureStorageService.getString('registered_accounts_db');
      if (savedDb != null && savedDb.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedDb);
        _accountsDb.clear();
        for (final item in decoded) {
          if (item is Map) {
            _accountsDb.add(Map<String, dynamic>.from(item));
          }
        }
        _accountsDb.removeWhere((item) => item['name'] == 'Demo User' || item['id'] == 'mock-user-id');
      }

      final activeSaved = await SecureStorageService.getString('active_user_data');
      if (activeSaved != null && activeSaved.isNotEmpty) {
        final parsed = jsonDecode(activeSaved) as Map<String, dynamic>;
        if (parsed['name'] == 'Demo User' || parsed['id'] == 'mock-user-id') {
          // Immediately purge legacy Demo User from storage
          if (_accountsDb.isNotEmpty) {
            _currentUser = _accountsDb.last;
          } else {
            _currentUser = null;
          }
          if (_currentUser != null) {
            await SecureStorageService.saveString('active_user_data', jsonEncode(_currentUser));
          } else {
            await SecureStorageService.delete('active_user_data');
          }
        } else {
          _currentUser = parsed;
        }
      }
    } catch (_) {}
    _isDbLoaded = true;
  }

  static Future<List<Map<String, dynamic>>> getRegisteredAccounts() async {
    await _loadAccountsDb();
    return List<Map<String, dynamic>>.from(_accountsDb);
  }

  static Future<void> switchAccount(Map<String, dynamic> account) async {
    await _loadAccountsDb();
    _currentUser = account;
    await SecureStorageService.saveString('active_user_data', jsonEncode(account));
  }


  static void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('[API] Intercepted Request: ${options.method} ${options.path}');
        
        await Future.delayed(const Duration(milliseconds: 300)); // Smooth latency
        await _loadAccountsDb();

        // 1. REGISTER
        if (options.path.contains('/auth/register')) {
          final req = (options.data is Map) ? (options.data as Map) : {};
          final name = req['name']?.toString() ?? 'New User';
          final username = req['username']?.toString() ?? name.toLowerCase().replaceAll(' ', '_');
          final email = req['email']?.toString() ?? '';
          final phone = req['phone']?.toString() ?? '';
          final address = req['address']?.toString() ?? '';
          final lat = req['lat']?.toString() ?? '12.9716';
          final lng = req['lng']?.toString() ?? '77.5946';

          final newAccount = <String, dynamic>{
            'id': 'user-${DateTime.now().millisecondsSinceEpoch}',
            'name': name,
            'username': username,
            'email': email,
            'phone': phone,
            'address': address,
            'lat': lat,
            'lng': lng,
            'role': 'USER',
            'isVerified': true,
            'createdAt': DateTime.now().toIso8601String(),
          };

          // Save to registry (update if existing email, or append)
          _accountsDb.removeWhere((a) => a['email'] == email || a['username'] == username);
          _accountsDb.add(newAccount);
          _currentUser = newAccount;

          await SecureStorageService.saveString('registered_accounts_db', jsonEncode(_accountsDb));
          await SecureStorageService.saveString('active_user_data', jsonEncode(newAccount));

          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': {
                'user': newAccount,
                'accessToken': 'token-${DateTime.now().millisecondsSinceEpoch}',
                'refreshToken': 'refresh-${DateTime.now().millisecondsSinceEpoch}',
              }
            },
          ));
        }

        // 2. LOGIN
        if (options.path.contains('/auth/login')) {
          final req = (options.data is Map) ? (options.data as Map) : {};
          final loginId = (req['email'] ?? req['phone'] ?? '').toString().trim();

          Map<String, dynamic>? matchedAccount;
          for (final acc in _accountsDb) {
            if (acc['email'] == loginId ||
                acc['phone'] == loginId ||
                acc['username'] == loginId) {
              matchedAccount = acc;
              break;
            }
          }

          if (matchedAccount == null) {
            // Create user from login credential so it matches given identity
            final guessedUsername = loginId.contains('@') ? loginId.split('@').first : loginId;
            matchedAccount = <String, dynamic>{
              'id': 'user-${DateTime.now().millisecondsSinceEpoch}',
              'name': guessedUsername.isNotEmpty ? guessedUsername : 'User',
              'username': guessedUsername,
              'email': loginId.contains('@') ? loginId : '$guessedUsername@example.com',
              'phone': !loginId.contains('@') && loginId.length >= 10 ? loginId : '9876543210',
              'role': 'USER',
              'isVerified': true,
              'createdAt': DateTime.now().toIso8601String(),
            };
            _accountsDb.add(matchedAccount);
            await SecureStorageService.saveString('registered_accounts_db', jsonEncode(_accountsDb));
          }

          _currentUser = matchedAccount;
          await SecureStorageService.saveString('active_user_data', jsonEncode(_currentUser));

          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': {
                'user': _currentUser,
                'accessToken': 'token-${DateTime.now().millisecondsSinceEpoch}',
                'refreshToken': 'refresh-${DateTime.now().millisecondsSinceEpoch}',
              }
            },
          ));
        }

        // 3. CURRENT USER (/users/me)
        if (options.path.contains('/users/me')) {
          if (options.method == 'PUT' && options.data is Map) {
            final reqData = options.data as Map;
            if (_currentUser != null) {
              if (reqData.containsKey('name')) _currentUser!['name'] = reqData['name'];
              if (reqData.containsKey('username')) _currentUser!['username'] = reqData['username'];
              if (reqData.containsKey('email')) _currentUser!['email'] = reqData['email'];
              if (reqData.containsKey('phone')) _currentUser!['phone'] = reqData['phone'];
              if (reqData.containsKey('address')) _currentUser!['address'] = reqData['address'];
              await SecureStorageService.saveString('active_user_data', jsonEncode(_currentUser));
              await SecureStorageService.saveString('registered_accounts_db', jsonEncode(_accountsDb));
            }
          }

          final userToReturn = _currentUser ?? (_accountsDb.isNotEmpty ? _accountsDb.last : {
            'id': 'user-1',
            'name': 'User',
            'username': 'user',
            'email': 'user@example.com',
            'phone': '9876543210',
            'role': 'USER',
            'createdAt': DateTime.now().toIso8601String(),
          });

          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': userToReturn,
            },
          ));
        }

        if (options.path.contains('/bookings')) {
          if (options.method == 'GET') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': {
                  'bookings': [],
                  'pagination': {
                    'page': 1,
                    'pages': 1,
                    'total': 0,
                  }
                }
              }
            ));
          } else if (options.method == 'POST') {
             return handler.resolve(Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'status': 'success',
                'data': {
                  'id': 'mock-booking-id',
                  'userId': 'mock-user-id',
                  'type': options.data['type'] ?? 'IMMEDIATE',
                  'status': 'PENDING',
                  'addressLine': options.data['addressLine'] ?? '',
                  'latitude': options.data['latitude'] ?? 0.0,
                  'longitude': options.data['longitude'] ?? 0.0,
                  'wasteType': options.data['wasteType'] ?? 'general',
                  'quantity': options.data['quantity'] ?? 'small',
                  'createdAt': DateTime.now().toIso8601String(),
                }
              }
            ));
          } else if (options.method == 'PATCH') { // For cancel
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': {}
              }
            ));
          }
        }

        if (options.path.contains('/auth/logout')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'status': 'success'}
          ));
        }

        if (options.path.contains('/payments/create-order')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': {
                'orderId': 'mock-order-id',
              }
            }
          ));
        }

        if (options.path.contains('/payments/verify')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': {}
            }
          ));
        }

        if (options.path.contains('/ratings')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': {}
            }
          ));
        }

        // Fallback for unmocked routes
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'status': 'success', 'data': {}}
        ));
      },
    ));
  }

  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'] as String;
      }
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timeout. Check your internet.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot reach server. Check your connection.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
