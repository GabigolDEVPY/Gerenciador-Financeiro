import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work_wage':
      case 'salary':
      case 'salario':
        return Icons.work_rounded;
      case 'food':
      case 'comida':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'transporte':
        return Icons.directions_car_rounded;
      case 'shopping':
      case 'compras':
        return Icons.shopping_bag_rounded;
      case 'health':
      case 'saude':
        return Icons.favorite_rounded;
      case 'entertainment':
      case 'lazer':
        return Icons.sports_esports_rounded;
      case 'bills':
      case 'contas':
        return Icons.receipt_long_rounded;
      case 'education':
      case 'educacao':
        return Icons.school_rounded;
      default:
        return transaction.isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;
    }
  }

  String _formatCategory(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
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
