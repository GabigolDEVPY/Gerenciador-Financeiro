import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/fixed_transaction.dart';
import '../models/transaction.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'Exception: $message';
}

class ApiService {
  static const _requestTimeout = Duration(seconds: 8);
  final String? token;

  ApiService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_requestTimeout);

    final body = _decodeResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body is! Map) {
        throw const FormatException('Resposta de login inválida.');
      }
      // Suporta vários formatos de resposta JWT
      final access = body['access'] ??
          body['access_token'] ??
          body['token'] ??
          body['data']?['access'];
      if (access == null) {
        throw Exception('Token não encontrado na resposta: $body');
      }
      return {'access': access, 'raw': body};
    } else {
      throw ApiException(
        response.statusCode,
        _errorMessage(body, 'Erro ao fazer login', response.statusCode),
      );
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String password, String email) async {
    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.registerEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
            'email': email,
          }),
        )
        .timeout(_requestTimeout);

    final body = _decodeResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body is Map<String, dynamic>
          ? body
          : (body is Map ? Map<String, dynamic>.from(body) : {'success': true});
    } else {
      throw ApiException(
        response.statusCode,
        _errorMessage(body, 'Erro ao criar conta', response.statusCode),
      );
    }
  }

  Future<DashboardData> getDashboard() async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.dashboardEndpoint}'),
          headers: _headers,
        )
        .timeout(_requestTimeout);

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      if (body is Map<String, dynamic>) {
        return DashboardData.fromJson(body);
      }
      // Se vier só uma lista, trata como transações
      if (body is List) {
        final txs = body
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList();
        double income = 0, expense = 0;
        for (var t in txs) {
          if (t.isIncome) {
            income += t.amount;
          } else {
            expense += t.amount;
          }
        }
        return DashboardData(
          totalBalance: income - expense,
          totalIncome: income,
          totalExpense: expense,
          savingsRate: income > 0 ? ((income - expense) / income) * 100 : 0,
          creditCount: txs.where((t) => t.isIncome).length,
          debitCount: txs.where((t) => t.isExpense).length,
          recentTransactions: txs,
        );
      }
      throw Exception('Formato de resposta inesperado');
    } else {
      throw ApiException(
        response.statusCode,
        _errorMessage(body, 'Erro ao carregar dashboard', response.statusCode),
      );
    }
  }

  Future<List<Transaction>> getTransactions() async {
    Uri? uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.transactionsEndpoint}',
    ).replace(queryParameters: {'page_size': '1000'});
    final transactions = <Transaction>[];

    while (uri != null) {
      final response =
          await http.get(uri, headers: _headers).timeout(_requestTimeout);
      final body = _decodeResponse(response);
      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode,
          _errorMessage(
              body, 'Erro ao carregar transações', response.statusCode),
        );
      }

      if (body is List) {
        transactions.addAll(body.map(_transactionFromJson));
        break;
      }
      if (body is! Map) break;

      final results =
          body['results'] ?? body['transactions'] ?? body['data'] ?? [];
      if (results is List) {
        transactions.addAll(results.map(_transactionFromJson));
      }
      final next = body['next'];
      uri = next is String && next.isNotEmpty ? Uri.parse(next) : null;
    }

    return transactions;
  }

  Future<List<FixedTransaction>> getFixedTransactions() async {
    final response = await http
        .get(
          Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.fixedTransactionsEndpoint}'),
          headers: _headers,
        )
        .timeout(_requestTimeout);
    final body = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        _errorMessage(
            body, 'Erro ao carregar lançamentos fixos', response.statusCode),
      );
    }

    final results = body is List
        ? body
        : body is Map
            ? body['results']
            : null;
    if (results is! List) return [];
    return results.map(_fixedTransactionFromJson).toList();
  }

  Future<FixedTransaction> saveFixedTransaction(
    FixedTransaction transaction, {
    bool update = false,
  }) async {
    final url = update
        ? '${AppConstants.baseUrl}${AppConstants.fixedTransactionsEndpoint}${transaction.id}/'
        : '${AppConstants.baseUrl}${AppConstants.fixedTransactionsEndpoint}create/';
    final response = update
        ? await http
            .put(Uri.parse(url),
                headers: _headers, body: jsonEncode(transaction.toJson()))
            .timeout(_requestTimeout)
        : await http
            .post(Uri.parse(url),
                headers: _headers, body: jsonEncode(transaction.toJson()))
            .timeout(_requestTimeout);
    final body = _decodeResponse(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fixedTransactionFromJson(body as Map);
    }
    throw ApiException(
      response.statusCode,
      _errorMessage(
          body, 'Erro ao salvar lançamento fixo', response.statusCode),
    );
  }

  Future<FixedTransaction> setFixedTransactionActive(
    FixedTransaction transaction,
    bool isActive,
  ) async {
    final response = await http
        .patch(
          Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.fixedTransactionsEndpoint}${transaction.id}/'),
          headers: _headers,
          body: jsonEncode({'is_active': isActive}),
        )
        .timeout(_requestTimeout);
    final body = _decodeResponse(response);
    if (response.statusCode == 200) {
      return _fixedTransactionFromJson(body as Map);
    }
    throw ApiException(
      response.statusCode,
      _errorMessage(
          body, 'Erro ao atualizar lançamento fixo', response.statusCode),
    );
  }

  Future<void> deleteFixedTransaction(int id) async {
    final response = await http
        .delete(
          Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.fixedTransactionsEndpoint}$id/'),
          headers: _headers,
        )
        .timeout(_requestTimeout);
    if (response.statusCode == 204 || response.statusCode == 200) {
      return;
    }
    final body = response.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException(
      response.statusCode,
      _errorMessage(
          body, 'Erro ao excluir lançamento fixo', response.statusCode),
    );
  }

  Transaction _transactionFromJson(dynamic value) =>
      Transaction.fromJson(Map<String, dynamic>.from(value as Map));

  FixedTransaction _fixedTransactionFromJson(dynamic value) =>
      FixedTransaction.fromJson(Map<String, dynamic>.from(value as Map));

  dynamic _decodeResponse(http.Response response) {
    final text = utf8.decode(response.bodyBytes).trim();
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      final isHtml = (response.headers['content-type'] ?? '')
              .toLowerCase()
              .contains('text/html') ||
          text.startsWith('<');
      throw ApiException(
        response.statusCode,
        isHtml
            ? 'A API retornou uma página HTML em vez de JSON (HTTP ${response.statusCode}). Verifique a rota e o servidor.'
            : 'A API retornou uma resposta inválida (HTTP ${response.statusCode}).',
      );
    }
  }

  String _errorMessage(dynamic body, String fallback, int statusCode) {
    if (body is Map) {
      final message = body['detail'] ?? body['message'] ?? body['error'];
      if (message != null) {
        return message is List ? message.join(' ') : message.toString();
      }
      final errors = body.entries
          .map((entry) {
            final value = entry.value is List
                ? (entry.value as List).join(' ')
                : entry.value.toString();
            return '${entry.key}: $value';
          })
          .where((entry) => entry.isNotEmpty)
          .join(' | ');
      if (errors.isNotEmpty) return errors;
    }
    if (body is String && body.isNotEmpty) return body;
    return '$fallback ($statusCode)';
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    final response = await http
        .post(
          Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.addTransactionEndpoint}'),
          headers: _headers,
          body: jsonEncode(transaction.toJson()),
        )
        .timeout(_requestTimeout);

    final body = _decodeResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body is Map<String, dynamic>) {
        return Transaction.fromJson(body);
      }
      return transaction;
    } else {
      throw ApiException(
        response.statusCode,
        _errorMessage(body, 'Erro ao adicionar transação', response.statusCode),
      );
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final id = transaction.id;
    if (id == null) throw ArgumentError('Transação sem identificador.');
    final response = await http
        .patch(
          Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.transactionsEndpoint}$id/'),
          headers: _headers,
          body: jsonEncode(transaction.toJson()),
        )
        .timeout(_requestTimeout);
    final body = _decodeResponse(response);
    if (response.statusCode == 200) {
      return _transactionFromJson(body);
    }
    throw ApiException(
      response.statusCode,
      _errorMessage(body, 'Erro ao atualizar transação', response.statusCode),
    );
  }

  Future<void> deleteTransaction(int id) async {
    final response = await http
        .delete(
          Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.transactionsEndpoint}$id/'),
          headers: _headers,
        )
        .timeout(_requestTimeout);
    if (response.statusCode == 204 || response.statusCode == 200) return;
    final body = response.body.isEmpty ? null : _decodeResponse(response);
    throw ApiException(
      response.statusCode,
      _errorMessage(body, 'Erro ao excluir transação', response.statusCode),
    );
  }
}
