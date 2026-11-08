import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/models/transaction.dart';

void main() {
  group('Dashboard API compatibility', () {
    test('parses the same summary shape returned by the web API', () {
      final dashboard = DashboardData.fromJson({
        'total_credit': 2500.0,
        'total_debit': 1800.0,
        'total_revenue': 700.0,
        'credit_count': 4,
        'debit_count': 5,
        'savings_rate': 28.0,
        'last_transactions': [
          {
            'id': 1,
            'title': 'Salário',
            'amount': 1500.0,
            'category': 'work_wage',
            'description': 'Pagamento principal',
            'type': 'credit',
            'created': '2026-11-08T10:00:00Z',
          }
        ],
        'transactions_categories': [
          {
            'category': 'food',
            'type': 'debit',
            'total': 420.0,
            'percentage': 35.0,
          }
        ],
      });

      expect(dashboard.totalIncome, 2500.0);
      expect(dashboard.totalExpense, 1800.0);
      expect(dashboard.totalBalance, 700.0);
      expect(dashboard.recentTransactions.length, 1);
      expect(dashboard.recentTransactions.first.title, 'Salário');
      expect(dashboard.recentTransactions.first.createdAt, isNotNull);
    });

    test('accepts the created field used by the Django API', () {
      final transaction = Transaction.fromJson({
        'id': 9,
        'title': 'Mercado',
        'amount': 125.50,
        'category': 'food',
        'description': 'Compras do mês',
        'type': 'debit',
        'created': '2026-11-04T23:10:00Z',
      });

      expect(transaction.title, 'Mercado');
      expect(transaction.amount, 125.5);
      expect(transaction.isExpense, isTrue);
      expect(transaction.createdAt, isNotNull);
    });
  });
}
