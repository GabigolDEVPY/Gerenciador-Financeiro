class Transaction {
  final int? id;
  final String? clientId;
  final double amount;
  final String title;
  final String description;
  final String category;
  final String type; // 'credit' or 'debit'
  final DateTime? createdAt;

  Transaction({
    this.id,
    this.clientId,
    required this.amount,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    this.createdAt,
  });

  Transaction copyWith({
    int? id,
    String? clientId,
    double? amount,
    String? title,
    String? description,
    String? category,
    String? type,
    DateTime? createdAt,
  }) =>
      Transaction(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        amount: amount ?? this.amount,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
      );

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final rawCreated = json['created'] ??
        json['created_at'] ??
        json['date'] ??
        json['datetime'];

    return Transaction(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      clientId: json['client_id']?.toString(),
      amount: _toDouble(json['amount']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      type: (json['type'] ?? 'debit').toString(),
      createdAt:
          rawCreated == null ? null : DateTime.tryParse(rawCreated.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (clientId != null) 'client_id': clientId,
      'amount': amount,
      'title': title,
      'description': description,
      'category': category,
      'type': type,
    };
  }

  bool get isIncome => type == 'credit';
  bool get isExpense => type == 'debit';

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    if (value is num) return value.toDouble();
    return 0;
  }
}

class DashboardData {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double savingsRate;
  final int creditCount;
  final int debitCount;
  final List<Transaction> recentTransactions;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? extra;

  DashboardData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.savingsRate,
    required this.creditCount,
    required this.debitCount,
    required this.recentTransactions,
    this.categories = const [],
    this.extra,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final transactionsJson = json['last_transactions'] ??
        json['transactions'] ??
        json['recent_transactions'] ??
        json['data'] ??
        [];

    List<Transaction> txs = [];
    if (transactionsJson is List) {
      txs = transactionsJson
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final categoriesJson = json['transactions_categories'];
    final categories = categoriesJson is List
        ? categoriesJson
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    double income = _toDouble(json['total_credit'] ??
        json['income'] ??
        json['total_income'] ??
        json['entradas'] ??
        0);
    double expense = _toDouble(json['total_debit'] ??
        json['expense'] ??
        json['total_expense'] ??
        json['saidas'] ??
        0);
    double balance = _toDouble(json['total_revenue'] ??
        json['balance'] ??
        json['total_balance'] ??
        json['saldo'] ??
        0);

    if (balance == 0 && (income > 0 || expense > 0)) {
      balance = income - expense;
    }

    final savingsRate = _toDouble(json['savings_rate'] ??
        (income > 0 ? ((income - expense) / income) * 100 : 0));
    final creditCount =
        json['credit_count'] is num ? (json['credit_count'] as num).toInt() : 0;
    final debitCount =
        json['debit_count'] is num ? (json['debit_count'] as num).toInt() : 0;

    return DashboardData(
      totalBalance: balance,
      totalIncome: income,
      totalExpense: expense,
      savingsRate: savingsRate,
      creditCount: creditCount,
      debitCount: debitCount,
      recentTransactions: txs,
      categories: categories,
      extra: json,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    if (value is num) return value.toDouble();
    return 0;
  }
}
