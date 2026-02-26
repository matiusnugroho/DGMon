part of 'package:dgmon/main.dart';

extension _RingkasanMenuX on _FinanceDashboardPageState {
  Widget _buildRingkasanTab() {
    final List<_TransactionData> recentTransactions = _transactions
        .take(5)
        .toList(growable: false);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _HeaderSection(),
            const SizedBox(height: 20),
            _BalanceCard(
              totalBalance: _totalBalance,
              totalIncome: _totalIncome,
              totalExpense: _totalExpense,
              netValue: _netValue,
            ),
            const SizedBox(height: 24),
            _AccountCarousel(
              accounts: _cashAccounts
                  .map(
                    (_CashAccount account) => _AccountBalanceData(
                      name: account.name,
                      balance: _balanceForAccount(account.name),
                    ),
                  )
                  .toList(growable: false),
              onAddPressed: _handleAddCashAccount,
            ),
            const SizedBox(height: 24),
            _TransactionSection(
              title: 'Transaksi Terbaru',
              transactions: recentTransactions,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatefulWidget {
  const _HeaderSection();

  @override
  State<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<_HeaderSection> {
  late DateTime _now;
  Timer? _timeTicker;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timeTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timeTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _greetingForHour(_now.hour),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.netValue,
  });

  final int totalBalance;
  final int totalIncome;
  final int totalExpense;
  final int netValue;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: <Color>[context.gradientStart, context.gradientEnd],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.shadow,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'TOTAL SALDO',
                style: textTheme.labelSmall?.copyWith(
                  color: context.subtleOnPrimary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatSignedCurrency(totalBalance),
            style: textTheme.headlineMedium?.copyWith(
              color: context.scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _MetricItem(
                title: 'Masuk',
                value: _formatWholeCurrency(totalIncome),
                labelColor: context.subtleOnPrimary,
                valueColor: context.scheme.onPrimary,
              ),
              _MetricItem(
                title: 'Keluar',
                value: '-${_formatWholeCurrency(totalExpense)}',
                labelColor: context.subtleOnPrimary,
                valueColor: context.scheme.onPrimary,
              ),
              _MetricItem(
                title: 'Bersih',
                value: _formatSignedCurrency(netValue),
                labelColor: context.subtleOnPrimary,
                valueColor: context.scheme.onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.title,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Text(title, style: textTheme.labelSmall?.copyWith(color: labelColor)),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AccountCarousel extends StatelessWidget {
  const _AccountCarousel({required this.accounts, required this.onAddPressed});

  final List<_AccountBalanceData> accounts;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          for (final _AccountBalanceData account in accounts)
            _AccountCard(name: account.name, balance: account.balance),
          _AddAccountCard(onPressed: onAddPressed),
        ],
      ),
    );
  }
}

class _AccountBalanceData {
  const _AccountBalanceData({required this.name, required this.balance});

  final String name;
  final int balance;
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.name, required this.balance});

  final String name;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color onCardColor = context.scheme.onPrimary;
    final Color negativeBalanceColor = const Color(0xFFFFDADA);

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            context.gradientStart,
            Color.lerp(context.gradientEnd, Colors.black, 0.25) ??
                context.gradientEnd,
          ],
        ),
        border: Border.all(color: onCardColor.withValues(alpha: 0.15)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.shadow.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -8,
              top: -12,
              child: Text(
                'DG',
                style: textTheme.displaySmall?.copyWith(
                  color: onCardColor.withValues(alpha: 0.14),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                ),
              ),
            ),
            Positioned(
              right: -42,
              bottom: -44,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: onCardColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Icon(
                        Icons.contactless,
                        color: onCardColor.withValues(alpha: 0.8),
                        size: 17,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: onCardColor.withValues(alpha: 0.22),
                      border: Border.all(
                        color: onCardColor.withValues(alpha: 0.36),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: onCardColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatSignedCurrency(balance),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: balance < 0 ? negativeBalanceColor : onCardColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add_circle_outline, color: context.scheme.primary),
            const SizedBox(height: 8),
            Text(
              'Tambah akun kas',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Geser untuk lihat kartu lain',
              style: textTheme.bodySmall?.copyWith(color: context.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
