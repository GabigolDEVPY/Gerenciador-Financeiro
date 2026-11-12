import 'dart:math';

import 'package:flutter/foundation.dart';
import '../models/fixed_transaction.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/local_transaction_store.dart';

class TransactionProvider with ChangeNotifier {
  final ApiService Function(String token) _apiFactory;
  final LocalTransactionStore _localStore = LocalTransactionStore();
  DashboardData? _dashboard;
  List<Transaction> _transactions = [];
  List<FixedTransaction> _fixedTransactions = [];
  List<Map<String, dynamic>> _pendingOperations = [];
  String? _username;
  bool _isLoading = false;
  bool _isLoadingFixed = false;
  bool _isSyncing = false;
  String? _error;
  String? _fixedError;
  Future<void> Function()? onSessionExpired;

  TransactionProvider({ApiService Function(String token)? apiFactory})
      : _apiFactory = apiFactory ?? _defaultApiFactory;

  static ApiService _defaultApiFactory(String token) =>
      ApiService(token: token);

  DashboardData? get dashboard => _dashboard;
  List<Transaction> get transactions => _transactions;
  List<FixedTransaction> get fixedTransactions => _fixedTransactions;
  bool get hasPendingChanges => _pendingOperations.isNotEmpty;
  int get pendingChangeCount => _pendingOperations.length;
  bool isTransactionPending(int? id) =>
      id != null &&
      _pendingOperations.any((operation) =>
          operation['id'] == id && operation['entity'] != 'fixed');
  bool isFixedTransactionPending(int? id) =>
      id != null &&
      _pendingOperations.any((operation) =>
          operation['id'] == id && operation['entity'] == 'fixed');
  bool get isLoading => _isLoading;
  bool get isLoadingFixed => _isLoadingFixed;
  String? get error => _error;
  String? get fixedError => _fixedError;

  Future<void> initializeUser(String username) async {
    if (_username == username) return;
    _username = username;
    final state = await _localStore.load(username);
    _transactions = state.transactions.toList();
    _fixedTransactions = state.fixedTransactions.toList();
    _pendingOperations = state.pendingOperations.toList();
    _sortTransactions();
    _sortFixedTransactions();
    _dashboard = _transactions.isEmpty ? null : _buildLocalDashboard();
    notifyListeners();
  }

  Future<void> _persistLocalState() async {
    final username = _username;
    if (username == null) return;
    await _localStore.save(
      username,
      transactions: _transactions,
      fixedTransactions: _fixedTransactions,
      pendingOperations: _pendingOperations,
    );
  }

  void _sortTransactions() {
    _transactions.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
  }

  void _sortFixedTransactions() {
    _fixedTransactions.sort((a, b) => a.nextDate.compareTo(b.nextDate));
  }

  DashboardData _buildLocalDashboard() {
    final now = DateTime.now();
    final monthTransactions = _transactions.where((transaction) {
      final date = transaction.createdAt?.toLocal();
      return date == null || (date.year == now.year && date.month == now.month);
    });
    var income = 0.0;
    var expense = 0.0;
    var creditCount = 0;
    var debitCount = 0;
    final categoryTotals = <String, double>{};
    for (final transaction in monthTransactions) {
      if (transaction.isIncome) {
        income += transaction.amount;
        creditCount++;
      } else {
        expense += transaction.amount;
        debitCount++;
      }
      final key = '${transaction.type}:${transaction.category}';
      categoryTotals.update(
        key,
        (total) => total + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final categories = categoryTotals.entries.map((entry) {
      final split = entry.key.split(':');
      final total = entry.value;
      final typeTotal = split.first == 'credit' ? income : expense;
      return {
        'type': split.first,
        'category': split.skip(1).join(':'),
        'total': total,
        'percentage': typeTotal > 0 ? total / typeTotal * 100 : 0,
      };
    }).toList();
    return DashboardData(
      totalBalance: income - expense,
      totalIncome: income,
      totalExpense: expense,
      savingsRate: income > 0 ? ((income - expense) / income) * 100 : 0,
      creditCount: creditCount,
      debitCount: debitCount,
      recentTransactions: _transactions.take(5).toList(),
      categories: categories,
    );
  }

  Future<void> _handleError(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await onSessionExpired?.call();
    }
  }

  Map<String, dynamic> _localData(Transaction transaction) => {
        ...transaction.toJson(),
        'id': transaction.id,
        'created_at': transaction.createdAt?.toIso8601String(),
      };

  Transaction? _findLocalTransaction(int id) {
    for (final transaction in _transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  FixedTransaction? _findLocalFixedTransaction(int id) {
    for (final transaction in _fixedTransactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  Future<bool> syncPending(String token) async {
    if (_isSyncing || _pendingOperations.isEmpty) return false;
    _isSyncing = true;
    final api = _apiFactory(token);
    try {
      while (_pendingOperations.isNotEmpty) {
        final operation = _pendingOperations.first;
        final id = (operation['id'] as num).toInt();
        final isFixed = operation['entity'] == 'fixed';
        switch (operation['type']) {
          case 'fixed_create':
            final local = _findLocalFixedTransaction(id);
            if (local == null) {
              _pendingOperations.removeAt(0);
              await _persistLocalState();
              continue;
            }
            final remote = await api.saveFixedTransaction(local);
            _fixedTransactions.removeWhere((item) => item.id == id);
            _fixedTransactions.add(
              remote.copyWith(clientId: remote.clientId ?? local.clientId),
            );
            break;
          case 'fixed_update':
            final local = _findLocalFixedTransaction(id);
            if (local != null) {
              final remote =
                  await api.saveFixedTransaction(local, update: true);
              _fixedTransactions.removeWhere((item) => item.id == id);
              _fixedTransactions.add(remote);
            }
            break;
          case 'fixed_active':
            final local = _findLocalFixedTransaction(id);
            if (local != null) {
              final remote = await api.setFixedTransactionActive(
                local,
                local.isActive,
              );
              _fixedTransactions.removeWhere((item) => item.id == id);
              _fixedTransactions.add(remote);
            }
            break;
          case 'fixed_delete':
            await api.deleteFixedTransaction(id);
            break;
          case 'create':
            final local = _findLocalTransaction(id);
            if (local == null) {
              _pendingOperations.removeAt(0);
              await _persistLocalState();
              continue;
            }
            final remote = await api.addTransaction(local);
            final saved = remote.copyWith(
              clientId: remote.clientId ?? local.clientId,
              createdAt: remote.createdAt ?? local.createdAt,
            );
            _transactions.removeWhere((item) => item.id == id);
            _transactions.add(saved);
            break;
          case 'update':
            final local = _findLocalTransaction(id);
            if (local != null) await api.updateTransaction(local);
            break;
          case 'delete':
            await api.deleteTransaction(id);
            break;
          default:
            _pendingOperations.removeAt(0);
            await _persistLocalState();
            continue;
        }
        _pendingOperations.removeAt(0);
        if (isFixed) _sortFixedTransactions();
        await _persistLocalState();
      }
      _sortTransactions();
      _dashboard = _buildLocalDashboard();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      await _handleError(e);
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> loadDashboard(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: token);
      final remoteDashboard = await api.getDashboard();
      _dashboard = hasPendingChanges ? _buildLocalDashboard() : remoteDashboard;
    } catch (e) {
      await _handleError(e);
      _error = e.toString().replaceFirst('Exception: ', '');
      if (_transactions.isNotEmpty) _dashboard = _buildLocalDashboard();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactions(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await syncPending(token);
      final api = ApiService(token: token);
      final remoteTransactions = await api.getTransactions();
      final merged = <int, Transaction>{
        for (final transaction in remoteTransactions)
          if (transaction.id != null) transaction.id!: transaction,
      };
      for (final operation in _pendingOperations) {
        final id = (operation['id'] as num).toInt();
        if (operation['type'] == 'delete') {
          merged.remove(id);
        } else {
          final local = _findLocalTransaction(id);
          if (local != null) merged[id] = local;
        }
      }
      _transactions = merged.values.toList();
      _sortTransactions();
      if (hasPendingChanges || _dashboard == null) {
        _dashboard = _buildLocalDashboard();
      }
      await _persistLocalState();
    } catch (e) {
      await _handleError(e);
      _error = e.toString().replaceFirst('Exception: ', '');
      if (_transactions.isNotEmpty) _dashboard = _buildLocalDashboard();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction(String token, Transaction transaction) async {
    _isLoading = true;
    _error = null;
    final localId = -DateTime.now().microsecondsSinceEpoch;
    final local = transaction.copyWith(
      id: localId,
      clientId: transaction.clientId ?? _newClientId(),
      createdAt: transaction.createdAt ?? DateTime.now(),
    );
    _transactions.insert(0, local);
    _pendingOperations.add({
      'type': 'create',
      'id': localId,
      'data': _localData(local),
    });
    _dashboard = _buildLocalDashboard();
    await _persistLocalState();
    _isLoading = false;
    notifyListeners();
    await syncPending(token);
    return true;
  }

  String _newClientId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x100000000)}';

  Future<bool> updateTransaction(String token, Transaction transaction) async {
    final id = transaction.id;
    if (id == null) return false;
    final index = _transactions.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    _transactions[index] = transaction;
    final createIndex = _pendingOperations.indexWhere(
      (operation) => operation['type'] == 'create' && operation['id'] == id,
    );
    final updateIndex = _pendingOperations.indexWhere(
      (operation) => operation['type'] == 'update' && operation['id'] == id,
    );
    if (createIndex >= 0) {
      _pendingOperations[createIndex]['data'] = _localData(transaction);
    } else if (updateIndex >= 0) {
      _pendingOperations[updateIndex]['data'] = _localData(transaction);
    } else {
      _pendingOperations.add({'type': 'update', 'id': id});
    }
    _dashboard = _buildLocalDashboard();
    await _persistLocalState();
    notifyListeners();
    await syncPending(token);
    return true;
  }

  Future<bool> deleteTransaction(String token, int id) async {
    if (_findLocalTransaction(id) == null) return false;
    _transactions.removeWhere((item) => item.id == id);
    final wasPendingCreate = _pendingOperations.any(
      (operation) => operation['type'] == 'create' && operation['id'] == id,
    );
    _pendingOperations.removeWhere((operation) => operation['id'] == id);
    if (!wasPendingCreate) _pendingOperations.add({'type': 'delete', 'id': id});
    _dashboard = _buildLocalDashboard();
    await _persistLocalState();
    notifyListeners();
    await syncPending(token);
    return true;
  }

  Future<void> loadFixedTransactions(String token) async {
    _isLoadingFixed = true;
    _fixedError = null;
    notifyListeners();

    try {
      await syncPending(token);
      final remote = await ApiService(token: token).getFixedTransactions();
      final merged = <int, FixedTransaction>{
        for (final transaction in remote)
          if (transaction.id != null) transaction.id!: transaction,
      };
      for (final operation in _pendingOperations.where(
        (operation) => operation['entity'] == 'fixed',
      )) {
        final id = (operation['id'] as num).toInt();
        if (operation['type'] == 'fixed_delete') {
          merged.remove(id);
        } else {
          final local = _findLocalFixedTransaction(id);
          if (local != null) merged[id] = local;
        }
      }
      _fixedTransactions = merged.values.toList();
      _sortFixedTransactions();
      await _persistLocalState();
    } catch (e) {
      await _handleError(e);
      _fixedError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingFixed = false;
      notifyListeners();
    }
  }

  Future<bool> saveFixedTransaction(
    String token,
    FixedTransaction transaction, {
    required bool update,
  }) async {
    _fixedError = null;
    final id = update ? transaction.id : -DateTime.now().microsecondsSinceEpoch;
    if (id == null) return false;
    final local = transaction.copyWith(
      id: id,
      clientId: transaction.clientId ?? (update ? null : _newClientId()),
    );
    final index = _fixedTransactions.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _fixedTransactions[index] = local;
    } else {
      _fixedTransactions.add(local);
    }
    final createIndex = _pendingOperations.indexWhere((operation) =>
        operation['entity'] == 'fixed' &&
        operation['type'] == 'fixed_create' &&
        operation['id'] == id);
    final updateIndex = _pendingOperations.indexWhere((operation) =>
        operation['entity'] == 'fixed' &&
        operation['type'] == 'fixed_update' &&
        operation['id'] == id);
    final operation = {
      'entity': 'fixed',
      'type': update ? 'fixed_update' : 'fixed_create',
      'id': id,
    };
    if (createIndex < 0) {
      if (updateIndex >= 0) {
        _pendingOperations[updateIndex] = operation;
      } else {
        _pendingOperations.add(operation);
      }
    }
    _sortFixedTransactions();
    await _persistLocalState();
    notifyListeners();
    await syncPending(token);
    return true;
  }

  Future<bool> setFixedTransactionActive(
    String token,
    FixedTransaction transaction,
    bool isActive,
  ) async {
    final id = transaction.id;
    if (id == null) return false;
    final index = _fixedTransactions.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    final local = _fixedTransactions[index].copyWith(isActive: isActive);
    _fixedTransactions[index] = local;
    final createIndex = _pendingOperations.indexWhere((operation) =>
        operation['entity'] == 'fixed' &&
        operation['type'] == 'fixed_create' &&
        operation['id'] == id);
    final updateIndex = _pendingOperations.indexWhere((operation) =>
        operation['entity'] == 'fixed' &&
        operation['id'] == id &&
        operation['type'] != 'fixed_delete');
    if (createIndex < 0 && updateIndex < 0) {
      _pendingOperations.add({
        'entity': 'fixed',
        'type': 'fixed_active',
        'id': id,
      });
    }
    await _persistLocalState();
    notifyListeners();
    await syncPending(token);
    return true;
  }

  Future<bool> deleteFixedTransaction(String token, int id) async {
    if (_findLocalFixedTransaction(id) == null) return false;
    _fixedTransactions.removeWhere((item) => item.id == id);
    final wasPendingCreate = _pendingOperations.any((operation) =>
        operation['entity'] == 'fixed' &&
        operation['type'] == 'fixed_create' &&
        operation['id'] == id);
    _pendingOperations.removeWhere(
        (operation) => operation['entity'] == 'fixed' && operation['id'] == id);
    if (!wasPendingCreate) {
      _pendingOperations.add({
        'entity': 'fixed',
        'type': 'fixed_delete',
        'id': id,
      });
    }
    await _persistLocalState();
    notifyListeners();
    await syncPending(token);
    return true;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
