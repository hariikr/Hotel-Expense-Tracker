import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../features/billing/models/bill_model.dart';
import '../../features/transactions/cubits/transaction_cubit.dart';
import '../../services/language_service.dart';
import '../../services/share_service.dart';
import '../../services/smart_insights_service.dart';
import '../../utils/app_theme.dart';
import '../ai/ai_chat_screen.dart';
import '../billing/billing_screen.dart';
import '../billing/create_bill_screen.dart';
import '../settings/manage_categories_screen.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

final NumberFormat _money =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _Entry {
  final String title;
  final String? detail;
  final double amount;
  final bool isExpense;

  const _Entry(this.title, this.detail, this.amount, this.isExpense);
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  static const int _collapsedEntryCount = 6;

  final SmartInsightsService _insightsService = SmartInsightsService();
  SmartInsightsResponse? _smartInsights;
  bool _isLoadingInsights = false;
  bool _showAllEntries = false;

  // Kept so a background refresh shows the previous numbers instead of a
  // blank spinner.
  TransactionLoaded? _lastLoaded;

  String get _lang => LanguageService.getLanguageCode();
  String _t(String en, String ml) => _lang == 'ml' ? ml : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    await context.read<TransactionCubit>().loadTransactions(DateTime.now());
    await _loadSmartInsights();
  }

  Future<void> _loadSmartInsights() async {
    setState(() => _isLoadingInsights = true);
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState is Authenticated ? authState.user.id : null;

      if (userId == null) {
        if (mounted) setState(() => _isLoadingInsights = false);
        return;
      }

      final insights = await _insightsService.getSmartInsights(
        userId: userId,
        period: 'week',
      );
      if (mounted) {
        setState(() {
          _smartInsights = insights;
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading insights: $e');
      if (mounted) setState(() => _isLoadingInsights = false);
    }
  }

  Future<void> _shareToday(TransactionLoaded state) async {
    await ShareService.shareDailySummary(
      date: state.selectedDate,
      expenses: state.expenses,
      incomes: state.incomes,
    );
  }

  Future<void> _open(Widget screen, {bool reload = true}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (reload && mounted) _loadData();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoaded) _lastLoaded = state;
          final data = _lastLoaded;

          if (data == null) {
            if (state is TransactionError) return _buildError();
            return const Center(child: CircularProgressIndicator());
          }

          final isRefreshing = state is TransactionLoading;

          return Column(
            children: [
              SizedBox(
                height: 3,
                child: isRefreshing ? const LinearProgressIndicator() : null,
              ),
              if (state is TransactionError) _buildErrorBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _buildTodayCard(data),
                      const SizedBox(height: 16),
                      _buildActions(),
                      const SizedBox(height: 20),
                      _buildEntries(data),
                      if (data.bills.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildOrders(data),
                      ],
                      ..._buildInsightsSection(),
                      if (data.expenses.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildTopExpenses(data),
                      ],
                      const SizedBox(height: 16),
                      _buildAllTime(data),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.backgroundColor,
      foregroundColor: AppTheme.textPrimary,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      toolbarHeight: 68,
      titleSpacing: 4,
      title: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          final date = state is TransactionLoaded
              ? state.selectedDate
              : (_lastLoaded?.selectedDate ?? DateTime.now());
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isToday(date)
                    ? _t('Today', 'ഇന്ന്')
                    : DateFormat('d MMM').format(date),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                DateFormat('EEEE, d MMMM').format(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            final data = state is TransactionLoaded ? state : _lastLoaded;
            if (data == null) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: _t('Share today', 'ഇന്നത്തെ കണക്ക് പങ്കിടുക'),
              onPressed: () => _shareToday(data),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: _t('Refresh', 'പുതുക്കുക'),
          onPressed: _loadData,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              _t("Couldn't load today's data",
                  'ഇന്നത്തെ കണക്കുകൾ ലോഡ് ചെയ്യാനായില്ല'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t('Check the internet connection and try again.',
                  'ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(_t('Try again', 'വീണ്ടും ശ്രമിക്കുക')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppTheme.lossColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 20, color: AppTheme.lossColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t('Showing the last saved numbers.',
                  'അവസാനം ലഭിച്ച കണക്കുകളാണ് കാണിക്കുന്നത്.'),
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            ),
          ),
          TextButton(
            onPressed: _loadData,
            child: Text(_t('Retry', 'വീണ്ടും')),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Today card
  // ---------------------------------------------------------------------------

  Widget _buildTodayCard(TransactionLoaded s) {
    final profit = s.dailyProfit;
    final isProfit = profit >= 0;
    final tone = isProfit ? AppTheme.profitColor : AppTheme.lossColor;
    final billTotal = s.bills.fold<double>(0, (sum, b) => sum + b.totalAmount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: tone,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                isProfit
                    ? _t("Today's profit", 'ഇന്നത്തെ ലാഭം')
                    : _t("Today's loss", 'ഇന്നത്തെ നഷ്ടം'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              _money.format(profit.abs()),
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: tone,
                letterSpacing: -1,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.darkSurface),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _miniStat(
                    _t('Income', 'വരുമാനം'),
                    s.dailyIncome,
                    AppTheme.profitColor,
                  ),
                ),
                const VerticalDivider(width: 24, color: AppTheme.darkSurface),
                Expanded(
                  child: _miniStat(
                    _t('Expense', 'ചെലവ്'),
                    s.dailyExpense,
                    AppTheme.lossColor,
                  ),
                ),
              ],
            ),
          ),
          if (s.bills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('${s.bills.length} bills today',
                          'ഇന്ന് ${s.bills.length} ബില്ലുകൾ'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _money.format(billTotal),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            _money.format(amount),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Widget _buildActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _bigAction(
                label: _t('Income', 'വരുമാനം'),
                icon: Icons.add,
                color: AppTheme.profitColor,
                onTap: () => _open(const AddIncomeScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bigAction(
                label: _t('Expense', 'ചെലവ്'),
                icon: Icons.remove,
                color: AppTheme.lossColor,
                onTap: () => _open(const AddExpenseScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _smallAction(
                label: _t('New bill', 'പുതിയ ബിൽ'),
                icon: Icons.receipt_long_outlined,
                onTap: () => _open(const CreateBillScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _smallAction(
                label: _t('Ask AI', 'AI-യോട് ചോദിക്കൂ'),
                icon: Icons.auto_awesome_outlined,
                onTap: () => _open(const AiChatScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bigAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 64,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        icon: Icon(icon, size: 28),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _smallAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.cardColor,
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.darkSurface),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon, size: 20, color: AppTheme.primaryColor),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Today's entries
  // ---------------------------------------------------------------------------

  Widget _buildEntries(TransactionLoaded s) {
    final incomes = s.incomes
        .map((i) => _Entry(
              i.categoryName ?? _t('Income', 'വരുമാനം'),
              i.description,
              i.amount,
              false,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final expenses = s.expenses
        .map((e) => _Entry(
              e.categoryName ?? _t('Expense', 'ചെലവ്'),
              e.quantity,
              e.amount,
              true,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final entries = [...incomes, ...expenses];
    final canCollapse = entries.length > _collapsedEntryCount;
    final visible = _showAllEntries || !canCollapse
        ? entries
        : entries.take(_collapsedEntryCount).toList();

    return _section(
      title: _t("Today's entries", 'ഇന്നത്തെ കണക്കുകൾ'),
      trailing: entries.isEmpty
          ? null
          : Text(
              '${entries.length}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
      child: entries.isEmpty
          ? _buildEmptyEntries()
          : Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppTheme.surfaceColor),
                  _entryRow(visible[i]),
                ],
                if (canCollapse)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _showAllEntries = !_showAllEntries),
                      icon: Icon(
                        _showAllEntries ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(
                        _showAllEntries
                            ? _t('Show less', 'കുറച്ച് കാണിക്കുക')
                            : _t('Show all ${entries.length}',
                                'എല്ലാം കാണിക്കുക (${entries.length})'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _entryRow(_Entry e) {
    final color = e.isExpense ? AppTheme.lossColor : AppTheme.profitColor;
    final detail = e.detail?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              e.isExpense ? Icons.remove : Icons.add,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${e.isExpense ? '−' : '+'}${_money.format(e.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEntries() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.edit_note, size: 36, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Nothing added yet today',
                      'ഇന്ന് ഇതുവരെ ഒന്നും ചേർത്തിട്ടില്ല'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _t('Tap Income or Expense above to start.',
                      'മുകളിലെ വരുമാനം / ചെലവ് ബട്ടൺ അമർത്തുക.'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Orders (bills)
  // ---------------------------------------------------------------------------

  Widget _buildOrders(TransactionLoaded s) {
    return _section(
      title: _t("Today's orders", 'ഇന്നത്തെ ഓർഡറുകൾ'),
      trailing: TextButton(
        onPressed: () => _open(const BillingScreen()),
        child: Text(_t('See all', 'എല്ലാം കാണുക')),
      ),
      child: Column(
        children: [
          for (var i = 0; i < s.bills.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppTheme.surfaceColor),
            _billRow(s.bills[i]),
          ],
        ],
      ),
    );
  }

  Widget _billRow(BillModel bill) {
    final items =
        bill.items.map((item) => '${item.itemName} ×${item.quantity}').join(', ');
    final time = DateFormat('h:mm a').format(bill.createdAt ?? DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$time · ${bill.billNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    items,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _money.format(bill.totalAmount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI insights
  // ---------------------------------------------------------------------------

  List<Widget> _buildInsightsSection() {
    final insights = _smartInsights?.insights ?? const <SmartInsight>[];

    if (insights.isEmpty && !_isLoadingInsights) return const [];

    return [
      const SizedBox(height: 16),
      _section(
        title: _t('Insights', 'നിർദ്ദേശങ്ങൾ'),
        leading: const Icon(Icons.auto_awesome,
            size: 20, color: AppTheme.accentColor),
        trailing: _isLoadingInsights
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                onPressed: _loadSmartInsights,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: _t('Refresh', 'പുതുക്കുക'),
              ),
        child: insights.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _t('Getting insights…', 'നിർദ്ദേശങ്ങൾ തയ്യാറാക്കുന്നു…'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < insights.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppTheme.surfaceColor),
                    _insightRow(insights[i]),
                  ],
                ],
              ),
      ),
    ];
  }

  Widget _insightRow(SmartInsight insight) {
    final Color color;
    switch (insight.type) {
      case 'profit':
        color = AppTheme.profitColor;
        break;
      case 'expense':
      case 'warning':
        color = AppTheme.lossColor;
        break;
      case 'income':
        color = AppTheme.secondaryColor;
        break;
      case 'suggestion':
        color = AppTheme.accentOrange;
        break;
      default:
        color = AppTheme.primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(insight.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top expenses
  // ---------------------------------------------------------------------------

  Widget _buildTopExpenses(TransactionLoaded s) {
    final totals = <String, double>{};
    for (final expense in s.expenses) {
      final category = expense.categoryName ?? _t('Other', 'മറ്റുള്ളവ');
      totals[category] = (totals[category] ?? 0) + expense.amount;
    }
    final top = (totals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();
    final total = s.dailyExpense;

    return _section(
      title: _t('Top expenses', 'പ്രധാന ചെലവുകൾ'),
      child: Column(
        children: [
          for (final entry in top)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _money.format(entry.value),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          total > 0
                              ? '${(entry.value / total * 100).round()}%'
                              : '',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? entry.value / total : 0,
                      minHeight: 8,
                      backgroundColor: AppTheme.surfaceColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.lossLight),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // All time
  // ---------------------------------------------------------------------------

  Widget _buildAllTime(TransactionLoaded s) {
    final profit = s.allTimeProfit;
    return _section(
      title: _t('All time', 'ഇതുവരെ ആകെ'),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: _allTimeStat(
                  _t('Income', 'വരുമാനം'), s.allTimeTotalIncome, null),
            ),
            Expanded(
              child: _allTimeStat(
                  _t('Expense', 'ചെലവ്'), s.allTimeTotalExpense, null),
            ),
            Expanded(
              child: _allTimeStat(
                profit >= 0 ? _t('Profit', 'ലാഭം') : _t('Loss', 'നഷ്ടം'),
                profit.abs(),
                profit >= 0 ? AppTheme.profitColor : AppTheme.lossColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _allTimeStat(String label, double amount, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            _money.format(amount),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared building blocks
  // ---------------------------------------------------------------------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.darkSurface),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    Widget? leading,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                if (leading != null) ...[leading, const SizedBox(width: 8)],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: child,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer
  // ---------------------------------------------------------------------------

  Widget _buildDrawer() {
    return NavigationDrawer(
      backgroundColor: AppTheme.cardColor,
      surfaceTintColor: Colors.transparent,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Text(
            _t('Hotel accounts', 'ഹോട്ടൽ കണക്കുകൾ'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        _drawerItem(
          icon: Icons.category_outlined,
          label: _t('Manage categories', 'വിഭാഗങ്ങൾ'),
          onTap: () => _open(const ManageCategoriesScreen()),
        ),
        _drawerItem(
          icon: Icons.receipt_long_outlined,
          label: _t('Bills', 'ബില്ലുകൾ'),
          onTap: () => _open(const BillingScreen()),
        ),
        _drawerItem(
          icon: Icons.auto_awesome_outlined,
          label: _t('AI assistant', 'AI സഹായി'),
          onTap: () => _open(const AiChatScreen()),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(color: AppTheme.darkSurface),
        ),
        _drawerItem(
          icon: Icons.logout,
          label: _t('Log out', 'ലോഗ് ഔട്ട്'),
          color: AppTheme.lossColor,
          onTap: _confirmLogout,
          closeFirst: true,
        ),
      ],
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool closeFirst = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        minTileHeight: 56,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        leading: Icon(icon, color: color ?? AppTheme.textPrimary),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
        onTap: () {
          if (closeFirst) Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('Log out?', 'ലോഗ് ഔട്ട് ചെയ്യണോ?')),
        content: Text(_t(
          'You will need to sign in again to see your accounts.',
          'കണക്കുകൾ കാണാൻ വീണ്ടും ലോഗിൻ ചെയ്യേണ്ടി വരും.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_t('Cancel', 'വേണ്ട')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.lossColor),
            child: Text(_t('Log out', 'ലോഗ് ഔട്ട്')),
          ),
        ],
      ),
    );
  }
}
