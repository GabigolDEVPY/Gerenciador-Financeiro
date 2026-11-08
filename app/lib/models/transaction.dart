class Transaction {
  final int? id;
  final double amount;
  final String title;
  final String description;
  final String category;
  final String type; // 'credit' or 'debit'
  final DateTime? createdAt;

  Transaction({
    this.id,
    required this.amount,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] as num).toDouble(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? 'debit',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : (json['date'] != null ? DateTime.tryParse(json['date']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'title': title,
      'description': description,
      'category': category,
      'type': type,
    };
  }

  bool get isIncome => type == 'credit';
  bool get isExpense => type == 'debit';
}

class DashboardData {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final List<Transaction> recentTransactions;
  final Map<String, dynamic>? extra;

  DashboardData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
    this.extra,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Tenta vários formatos comuns de resposta
    final transactionsJson = json['transactions'] ??
        json['recent_transactions'] ??
        json['data'] ??
        [];

    List<Transaction> txs = [];
    if (transactionsJson is List) {
      txs = transactionsJson
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    double balance = _toDouble(json['balance'] ??
        json['total_balance'] ??
        json['saldo'] ??
        0);
    double income = _toDouble(json['income'] ??
        json['total_income'] ??
        json['total_credit'] ??
        json['entradas'] ??
        0);
    double expense = _toDouble(json['expense'] ??
        json['total_expense'] ??
        json['total_debit'] ??
        json['saidas'] ??
        0);

    // Se não veio balance, calcula a partir das transações
    if (balance == 0 && (income > 0 || expense > 0)) {
      balance = income - expense;
    }

    return DashboardData(
      totalBalance: balance,
      totalIncome: income,
      totalExpense: expense,
      recentTransactions: txs,
      extra: json,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
