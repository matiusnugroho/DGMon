import 'package:flutter/material.dart';

void main() => runApp(const DgMonApp());

class DgMonApp extends StatelessWidget {
  const DgMonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DGMon Finance Dashboard',
      theme: ThemeData(useMaterial3: true),
      home: const FinanceDashboardPage(),
    );
  }
}

extension _FinanceTheme on BuildContext {
  ThemeData get _theme => Theme.of(this);
  ColorScheme get scheme => _theme.colorScheme;

  Color get pageBackground => scheme.surfaceContainerLowest;
  Color get cardBackground => scheme.surface;
  Color get gradientStart => scheme.primary;
  Color get gradientEnd =>
      Color.lerp(scheme.primary, scheme.secondary, 0.4) ?? scheme.primary;
  Color get mutedText => scheme.onSurface.withValues(alpha: 0.65);
  Color get subtleOnPrimary => scheme.onPrimary.withValues(alpha: 0.72);
  Color get shadow => scheme.shadow.withValues(alpha: 0.2);
}

class FinanceDashboardPage extends StatelessWidget {
  const FinanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBackground,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: <Color>[context.gradientStart, context.gradientEnd],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: context.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: context.scheme.primary.withValues(alpha: 0),
          elevation: 0,
          onPressed: () {},
          child: Icon(Icons.add, size: 28, color: context.scheme.onPrimary),
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _HeaderSection(),
              SizedBox(height: 20),
              _BalanceCard(),
              SizedBox(height: 24),
              _AccountCarousel(),
              SizedBox(height: 24),
              _InsightSection(),
              SizedBox(height: 24),
              _TransactionSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Good Morning, Duo',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your money is under control',
              style: textTheme.bodyMedium?.copyWith(color: context.mutedText),
            ),
          ],
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: context.gradientStart,
          child: Icon(Icons.person, color: context.scheme.onPrimary),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'TOTAL BALANCE',
                style: textTheme.labelSmall?.copyWith(
                  color: context.subtleOnPrimary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.visibility, color: context.subtleOnPrimary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$20,965,000',
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
                title: 'Income',
                value: '\$0',
                labelColor: context.subtleOnPrimary,
                valueColor: context.scheme.onPrimary,
              ),
              _MetricItem(
                title: 'Expense',
                value: '\$35,000',
                labelColor: context.subtleOnPrimary,
                valueColor: context.scheme.onPrimary,
              ),
              _MetricItem(
                title: 'Net',
                value: '-\$35,000',
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
  const _AccountCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const <Widget>[
          _AccountCard(name: 'BRI', balance: '\$19,980,000'),
          _AccountCard(name: 'Tunai', balance: '\$1,000,000'),
          _AccountCard(name: 'Wallet', balance: '-\$15,000'),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.name, required this.balance});

  final String name;
  final String balance;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: context.cardBackground,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.shadow.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            name,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            balance,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.cardBackground,
      ),
      child: Text(
        'You spent 65% more on Food this week compared to last week.',
        style: textTheme.bodyMedium,
      ),
    );
  }
}

class _TransactionSection extends StatelessWidget {
  const _TransactionSection();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Recent Transactions',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        const _TransactionItem(
          title: 'Motor',
          subtitle: 'Wallet • Today',
          amount: '-\$15,000',
        ),
        const _TransactionItem(
          title: 'Makan',
          subtitle: 'BRI • Today',
          amount: '-\$20,000',
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: context.cardBackground,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(color: context.mutedText),
              ),
            ],
          ),
          Text(
            amount,
            style: textTheme.titleSmall?.copyWith(
              color: context.scheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: context.cardBackground,
      surfaceTintColor: context.cardBackground,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Icon(Icons.dashboard, color: context.scheme.primary),
            const SizedBox(width: 40),
            Icon(Icons.bar_chart, color: context.scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
