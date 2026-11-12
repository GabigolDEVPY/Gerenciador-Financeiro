import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final double savingsRate;
  final int creditCount;
  final int debitCount;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    this.savingsRate = 0,
    this.creditCount = 0,
    this.debitCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Total',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Entradas',
                  value: currency.format(income),
                  subtitle: '$creditCount lançamentos',
                  color: Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Saídas',
                  value: currency.format(expense),
                  subtitle: '$debitCount lançamentos',
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Taxa de economia',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${savingsRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
