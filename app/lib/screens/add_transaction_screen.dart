import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'debit';
  String _category = 'food';

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    if (transaction != null) {
      _titleController.text = transaction.title;
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _descriptionController.text = transaction.description;
      _type = transaction.type;
      _category = transaction.category;
    }
  }

  final List<Map<String, dynamic>> _categories = [
    {'value': 'housing', 'label': 'Moradia', 'icon': Icons.home_rounded},
    {'value': 'food', 'label': 'Alimentação', 'icon': Icons.restaurant_rounded},
    {
      'value': 'transport',
      'label': 'Transporte',
      'icon': Icons.directions_car_rounded
    },
    {'value': 'health', 'label': 'Saúde', 'icon': Icons.favorite_rounded},
    {'value': 'education', 'label': 'Educação', 'icon': Icons.school_rounded},
    {
      'value': 'leisure',
      'label': 'Lazer',
      'icon': Icons.sports_esports_rounded
    },
    {
      'value': 'shopping',
      'label': 'Compras',
      'icon': Icons.shopping_bag_rounded
    },
    {'value': 'travel', 'label': 'Viagem', 'icon': Icons.flight_rounded},
    {
      'value': 'investment',
      'label': 'Investimento',
      'icon': Icons.trending_up_rounded
    },
    {
      'value': 'debt',
      'label': 'Dívida / Empréstimo',
      'icon': Icons.account_balance_wallet_rounded
    },
    {
      'value': 'transfer',
      'label': 'Transferência',
      'icon': Icons.sync_alt_rounded
    },
    {
      'value': 'work',
      'label': 'Trabalho / Freelance',
      'icon': Icons.work_rounded
    },
    {'value': 'other', 'label': 'Outros', 'icon': Icons.more_horiz_rounded},
    {
      'value': 'work_wage',
      'label': 'Trabalho / Salário',
      'icon': Icons.payments_rounded
    },
    {
      'value': 'freelance',
      'label': 'Freelance / Extra',
      'icon': Icons.computer_rounded
    },
    {
      'value': 'investment_return',
      'label': 'Retorno de Investimento',
      'icon': Icons.show_chart_rounded
    },
    {
      'value': 'transfer_received',
      'label': 'Transferências Recebidas',
      'icon': Icons.call_received_rounded
    },
    {
      'value': 'other_income',
      'label': 'Outras Receitas',
      'icon': Icons.wallet_rounded
    },
  ];

  List<Map<String, dynamic>> get _visibleCategories {
    final debitValues = {
      'housing',
      'food',
      'transport',
      'health',
      'education',
      'leisure',
      'shopping',
      'travel',
      'investment',
      'debt',
      'transfer',
      'work',
      'other'
    };
    final creditValues = {
      'work_wage',
      'freelance',
      'investment_return',
      'transfer_received',
      'other_income'
    };

    final allowed = _type == 'credit' ? creditValues : debitValues;
    return _categories.where((cat) => allowed.contains(cat['value'])).toList();
  }

  void _setType(String nextType) {
    setState(() {
      _type = nextType;
      final candidates = nextType == 'credit'
          ? [
              'work_wage',
              'freelance',
              'investment_return',
              'transfer_received',
              'other_income'
            ]
          : [
              'housing',
              'food',
              'transport',
              'health',
              'education',
              'leisure',
              'shopping',
              'travel',
              'investment',
              'debt',
              'transfer',
              'work',
              'other'
            ];
      _category = candidates.contains(_category) ? _category : candidates.first;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '.').replaceAll('R\$', '').trim(),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Valor inválido'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final transaction = Transaction(
      id: widget.transaction?.id,
      amount: amount,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      type: _type,
      createdAt: widget.transaction?.createdAt,
    );

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final provider = context.read<TransactionProvider>();
    final success = widget.transaction == null
        ? await provider.addTransaction(token, transaction)
        : await provider.updateTransaction(token, transaction);

    if (!mounted) return;

    if (success) {
      if (widget.transaction != null) {
        Navigator.of(context).pop();
      }
      _titleController.clear();
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _type = 'debit';
        _category = 'food';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.hasPendingChanges
                ? 'Salvo no dispositivo; aguardando sincronização.'
                : widget.transaction == null
                    ? 'Transação adicionada com sucesso.'
                    : 'Transação atualizada com sucesso.',
          ),
          backgroundColor:
              provider.hasPendingChanges ? AppColors.warning : AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erro ao adicionar'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.transaction == null
                      ? 'Nova transação'
                      : 'Editar transação',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.transaction == null
                      ? 'Registre uma entrada ou saída'
                      : 'Atualize os dados da transação',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                // Tipo: Entrada / Saída
                const Text(
                  'Tipo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: 'Entrada',
                        icon: Icons.arrow_downward_rounded,
                        selected: _type == 'credit',
                        color: AppColors.income,
                        onTap: () => _setType('credit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeButton(
                        label: 'Saída',
                        icon: Icons.arrow_upward_rounded,
                        selected: _type == 'debit',
                        color: AppColors.expense,
                        onTap: () => _setType('debit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  controller: _titleController,
                  label: 'Título',
                  hint: 'Ex: Salário, Mercado, Uber...',
                  prefixIcon: Icons.title_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe um título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                CustomTextField(
                  controller: _amountController,
                  label: 'Valor',
                  hint: '0,00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.attach_money_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o valor';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                CustomTextField(
                  controller: _descriptionController,
                  label: 'Descrição (opcional)',
                  hint: 'Detalhes adicionais...',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                const Text(
                  'Categoria',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _visibleCategories.map((cat) {
                    final selected = _category == cat['value'];
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat['value']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.grey.shade200,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 18,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                CustomButton(
                  text: widget.transaction == null
                      ? 'Adicionar transação'
                      : 'Salvar alterações',
                  isLoading: txProvider.isLoading,
                  onPressed: _submit,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? color : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
