import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';
import 'fixed_transactions_screen.dart';
import 'transactions_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoadingData = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareOfflineSync();
    });
  }

  Future<void> _prepareOfflineSync() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<TransactionProvider>();
    provider.onSessionExpired = auth.expireSession;
    final username = auth.username;
    if (username != null) await provider.initializeUser(username);
    if (!mounted) return;

    await _loadData();
    if (!mounted) return;
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        if (mounted &&
            results.any((result) => result != ConnectivityResult.none)) {
          _loadData();
        }
      },
    );
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted || _isLoadingData) return;
    _isLoadingData = true;
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final provider = context.read<TransactionProvider>();
      await Future.wait([
        provider.loadDashboard(token),
        provider.loadTransactions(token),
      ]);
    } finally {
      _isLoadingData = false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(
        onRefresh: _loadData,
        onTransactionsTap: () => setState(() => _currentIndex = 1),
        onAddTap: () => setState(() => _currentIndex = 2),
      ),
      const TransactionsScreen(),
      const AddTransactionScreen(),
      const FixedTransactionsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Início',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  activeIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Transações',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  activeIcon: Icon(Icons.add_circle_rounded),
                  label: 'Adicionar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_repeat_outlined),
                  activeIcon: Icon(Icons.event_repeat_rounded),
                  label: 'Fixos',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onTransactionsTap;
  final VoidCallback onAddTap;

  const _DashboardTab({
    required this.onRefresh,
    required this.onTransactionsTap,
    required this.onAddTap,
  });

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _showIncomeCategories = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final dashboard = txProvider.dashboard;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${auth.username ?? 'Usuário'}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Aqui está o resumo das suas finanças',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onAddTap,
                      tooltip: 'Nova transação',
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.primary,
                    ),
                    IconButton(
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (r) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      color: AppColors.textSecondary,
                      tooltip: 'Sair',
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            if (txProvider.hasPendingChanges)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${txProvider.pendingChangeCount} ${txProvider.pendingChangeCount == 1 ? 'alteração pendente' : 'alterações pendentes'}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onRefresh,
                          tooltip: 'Tentar sincronizar',
                          icon: const Icon(Icons.sync_rounded),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: txProvider.isLoading && dashboard == null
                    ? const SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : BalanceCard(
                        balance: dashboard?.totalBalance ?? 0,
                        income: dashboard?.totalIncome ?? 0,
                        expense: dashboard?.totalExpense ?? 0,
                        savingsRate: dashboard?.savingsRate ?? 0,
                        creditCount: dashboard?.creditCount ?? 0,
                        debitCount: dashboard?.debitCount ?? 0,
                      ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CategorySummary(
                  categories: dashboard?.categories ?? const [],
                  showIncome: _showIncomeCategories,
                  onChanged: (value) =>
                      setState(() => _showIncomeCategories = value),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transações recentes',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    TextButton(
                        onPressed: widget.onTransactionsTap,
                        child: const Text('Ver todas')),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (txProvider.error != null && dashboard == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: AppColors.expense.withValues(alpha: 0.7)),
                      const SizedBox(height: 12),
                      Text(
                        txProvider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: widget.onRefresh,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (dashboard != null
                ? dashboard.recentTransactions.isEmpty
                : txProvider.transactions.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 56, color: AppColors.textSecondary),
                      SizedBox(height: 12),
                      Text(
                        'Nenhuma transação ainda',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: BuildingSliverList(
                  transactions: dashboard != null
                      ? dashboard.recentTransactions.take(8).toList()
                      : txProvider.transactions.take(8).toList(),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _CategorySummary extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final bool showIncome;
  final ValueChanged<bool> onChanged;

  const _CategorySummary({
    required this.categories,
    required this.showIncome,
    required this.onChanged,
  });

  static const _labels = {
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

  @override
  Widget build(BuildContext context) {
    final visible = categories
        .where((item) => item['type'] == (showIncome ? 'credit' : 'debit'))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Fluxo por categoria',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Saídas')),
                  ButtonSegment(value: true, label: Text('Entradas')),
                ],
                selected: {showIncome},
                onSelectionChanged: (value) => onChanged(value.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Text(
              showIncome
                  ? 'Nenhuma receita encontrada'
                  : 'Nenhuma despesa encontrada',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            ...visible.map((item) {
              final key = item['category']?.toString() ?? '';
              final amount = _asDouble(item['total']);
              final percentage =
                  _asDouble(item['percentage']).clamp(0, 100).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _labels[key] ?? key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                              .format(amount),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      color: showIncome ? AppColors.income : AppColors.expense,
                      backgroundColor: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  static double _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}

class BuildingSliverList extends StatelessWidget {
  final List transactions;

  const BuildingSliverList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = transactions[index];
          final provider = context.watch<TransactionProvider>();
          return TransactionCard(
            transaction: transaction,
            isPending: provider.isTransactionPending(transaction.id),
          );
        },
        childCount: transactions.length,
      ),
    );
  }
}
