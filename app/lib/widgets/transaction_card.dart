import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'housing':
        return Icons.home_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'leisure':
      case 'entertainment':
        return Icons.sports_esports_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'debt':
        return Icons.account_balance_wallet_rounded;
      case 'transfer':
      case 'transfer_received':
        return Icons.sync_alt_rounded;
      case 'work':
      case 'work_wage':
        return Icons.work_rounded;
      case 'freelance':
        return Icons.computer_rounded;
      case 'investment_return':
        return Icons.show_chart_rounded;
      case 'other_income':
      case 'other':
        return Icons.wallet_rounded;
      default:
        return transaction.isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;
    }
  }

  String _formatCategory(String category) {
    final normalized = category.trim();
    final map = {
      'housing': 'Moradia',
      'food': 'Alimentação',
      'transport': 'Transporte',
      'health': 'Saúde',
      'education': 'Educação',
      'leisure': 'Lazer',
      'shopping': 'Compras',
      'travel': 'Viagem',
      'investment': 'Investimento',
      'debt': 'Dívida / Empréstimo',
      'transfer': 'Transferência',
      'work': 'Trabalho / Freelance',
      'other': 'Outros',
      'work_wage': 'Trabalho / Salário',
      'freelance': 'Freelance / Extra',
      'investment_return': 'Retorno de Investimento',
      'transfer_received': 'Transferências Recebidas',
      'other_income': 'Outras Receitas',
    };

    return map[normalized.toLowerCase()] ??
        normalized
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
                w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isIncome = transaction.isIncome;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.income : AppColors.expense)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: isIncome ? AppColors.income : AppColors.expense,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCategory(transaction.category),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'} ${currency.format(transaction.amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
              if (transaction.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yy').format(transaction.createdAt!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
