import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all'; // all, credit, debit
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<TransactionProvider>().loadTransactions(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final all = txProvider.transactions;

    final filtered =
        _filter == 'all' ? all : all.where((t) => t.type == _filter).toList();
    final query = _searchController.text.trim().toLowerCase();
    final matching = filtered.where((transaction) {
      final matchesText = query.isEmpty ||
          transaction.title.toLowerCase().contains(query) ||
          transaction.description.toLowerCase().contains(query);
      final date = transaction.createdAt?.toLocal();
      final matchesStart = _startDate == null ||
          (date != null &&
              !DateTime(date.year, date.month, date.day).isBefore(DateTime(
                  _startDate!.year, _startDate!.month, _startDate!.day)));
      final matchesEnd = _endDate == null ||
          (date != null &&
              !DateTime(date.year, date.month, date.day).isAfter(
                  DateTime(_endDate!.year, _endDate!.month, _endDate!.day)));
      return matchesText && matchesStart && matchesEnd;
    }).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Transações',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar título ou descrição',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: true),
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(_startDate == null
                      ? 'Data inicial'
                      : _formatDate(_startDate!)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: false),
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: Text(
                      _endDate == null ? 'Data final' : _formatDate(_endDate!)),
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    tooltip: 'Limpar datas',
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    icon: const Icon(Icons.filter_alt_off_rounded),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Entradas',
                  selected: _filter == 'credit',
                  color: AppColors.income,
                  onTap: () => setState(() => _filter = 'credit'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Saídas',
                  selected: _filter == 'debit',
                  color: AppColors.expense,
                  onTap: () => setState(() => _filter = 'debit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: txProvider.isLoading && all.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : matching.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text(
                              'Nenhuma transação encontrada',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          final token = context.read<AuthProvider>().token;
                          if (token != null) {
                            await context
                                .read<TransactionProvider>()
                                .loadTransactions(token);
                          }
                        },
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: matching.length,
                          itemBuilder: (context, index) {
                            return TransactionCard(
                              transaction: matching[index],
                              isPending: txProvider.isTransactionPending(
                                matching[index].id,
                              ),
                              onEdit: () => _edit(matching[index]),
                              onDelete: () => _delete(matching[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(Transaction transaction) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(transaction: transaction),
      ),
    );
  }

  Future<void> _delete(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir transação?'),
        content: Text('"${transaction.title}" será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || transaction.id == null) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<TransactionProvider>();
    final success = await provider.deleteTransaction(token, transaction.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? provider.hasPendingChanges
                ? 'Exclusão salva; aguardando sincronização.'
                : 'Transação excluída.'
            : 'Não foi possível excluir a transação.'),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = selected;
        }
      } else {
        _endDate = selected;
        if (_startDate != null && _startDate!.isAfter(selected)) {
          _startDate = selected;
        }
      }
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : Colors.grey.shade200,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
