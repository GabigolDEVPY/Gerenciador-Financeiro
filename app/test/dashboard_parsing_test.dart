import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/models/fixed_transaction.dart';
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
      expect(dashboard.categories.single['category'], 'food');
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

  test('parses fixed transaction fields and serializes API date fields', () {
    final fixed = FixedTransaction.fromJson({
      'id': 12,
      'title': 'Aluguel',
      'description': 'Apartamento',
      'amount': '1200.00',
      'category': 'housing',
      'type': 'debit',
      'recurrence_type': 'monthly',
      'start_date': '2026-11-05',
      'next_date': '2026-12-05',
      'day_of_month': 5,
      'occurrences': 12,
      'generated_occurrences': 1,
      'is_active': true,
    });

    expect(fixed.id, 12);
    expect(fixed.amount, 1200);
    expect(fixed.nextDate, DateTime(2026, 12, 5));
    expect(fixed.toJson()['start_date'], '2026-11-05');
    expect(fixed.toJson()['day_of_month'], 5);
    expect(fixed.isFinished, isFalse);
  });
}
