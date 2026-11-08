import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/transaction.dart';

class ApiService {
  final String? token;

  ApiService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 || response.statusCode == 201) {
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
      final msg = body['detail'] ??
          body['message'] ??
          body['error'] ??
          'Erro ao fazer login (${response.statusCode})';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String password, String email) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.registerEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body is Map<String, dynamic>
          ? body
          : (body is Map ? Map<String, dynamic>.from(body) : {'success': true});
    } else {
      final msg =
          body['detail'] ?? body['message'] ?? body['error'] ?? body.toString();
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }

  Future<DashboardData> getDashboard() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.dashboardEndpoint}'),
      headers: _headers,
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes));

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
      throw Exception(body['detail'] ??
          'Erro ao carregar dashboard (${response.statusCode})');
    }
  }

  Future<List<Transaction>> getTransactions() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.transactionsEndpoint}'),
      headers: _headers,
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      List list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list = body['results'] ?? body['transactions'] ?? body['data'] ?? [];
      } else {
        list = [];
      }
      return list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(body['detail'] ??
          'Erro ao carregar transações (${response.statusCode})');
    }
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    final response = await http.post(
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.addTransactionEndpoint}'),
      headers: _headers,
      body: jsonEncode(transaction.toJson()),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body is Map<String, dynamic>) {
        return Transaction.fromJson(body);
      }
      return transaction;
    } else {
      final msg = body['detail'] ??
          body['message'] ??
          body['error'] ??
          'Erro ao adicionar transação (${response.statusCode})';
      throw Exception(msg is List ? msg.join(', ') : msg.toString());
    }
  }
}
