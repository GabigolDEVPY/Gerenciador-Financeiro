import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionProvider with ChangeNotifier {
  DashboardData? _dashboard;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  DashboardData? get dashboard => _dashboard;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: token);
      _dashboard = await api.getDashboard();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactions(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: token);
      _transactions = await api.getTransactions();
      // Ordena por data (mais recente primeiro)
      _transactions.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction(String token, Transaction transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: token);
      await api.addTransaction(transaction);
      // Recarrega os dados
      await Future.wait([
        loadDashboard(token),
        loadTransactions(token),
      ]);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
