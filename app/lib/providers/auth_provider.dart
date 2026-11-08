import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _username;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  String? get username => _username;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    _username = prefs.getString(AppConstants.usernameKey);
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService();
      final result = await api.login(username, password);
      _token = result['access'] as String;
      _username = username;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _token!);
      await prefs.setString(AppConstants.usernameKey, username);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String password, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService();
      await api.register(username, password, email);
      // Após registrar, faz login automático
      return await login(username, password);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.usernameKey);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
