part of 'package:dgmon/main.dart';

extension _TransaksiMenuX on _FinanceDashboardPageState {
  Widget _buildDaftarTransaksiTab() {
    final List<int> monthKeys = _availableMonthKeys();
    final int effectiveSelectedMonthKey = monthKeys.contains(_selectedMonthKey)
        ? _selectedMonthKey
        : monthKeys.first;
    final int effectiveRangeStartMonthKey =
        monthKeys.contains(_rangeStartMonthKey)
        ? _rangeStartMonthKey
        : monthKeys.last;
    final int effectiveRangeEndMonthKey = monthKeys.contains(_rangeEndMonthKey)
        ? _rangeEndMonthKey
        : monthKeys.first;
    final List<_TransactionData> filteredTransactions = _filteredTransactions(
      selectedMonthKey: effectiveSelectedMonthKey,
      rangeStartMonthKey: effectiveRangeStartMonthKey,
      rangeEndMonthKey: effectiveRangeEndMonthKey,
      accountFilter: _selectedTransactionAccountFilter,
      categoryFilter: _selectedTransactionCategoryFilter,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Daftar Transaksi',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semua catatan pemasukan dan pengeluaran.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_TransactionMenuAction>(
                  tooltip: 'Unduh Excel',
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  icon: Icon(
                    Icons.file_download_outlined,
                    color: context.scheme.primary,
                    size: 24,
                  ),
                  onSelected: (_TransactionMenuAction action) {
                    switch (action) {
                      case _TransactionMenuAction.exportFilteredExcel:
                        unawaited(
                          _exportTransactionRecapExcel(filteredTransactions),
                        );
                        return;
                      case _TransactionMenuAction.exportAllExcel:
                        unawaited(_exportTransactionRecapExcel(_transactions));
                        return;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<_TransactionMenuAction>>[
                        PopupMenuItem<_TransactionMenuAction>(
                          value: _TransactionMenuAction.exportFilteredExcel,
                          child: _SettingsMenuItemRow(
                            icon: Icons.filter_alt_outlined,
                            label: _TransactionMenuAction
                                .exportFilteredExcel
                                .label,
                          ),
                        ),
                        PopupMenuItem<_TransactionMenuAction>(
                          value: _TransactionMenuAction.exportAllExcel,
                          child: _SettingsMenuItemRow(
                            icon: Icons.download_rounded,
                            label: _TransactionMenuAction.exportAllExcel.label,
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _TransactionFilterType.values
                  .map(
                    (_TransactionFilterType filterType) => ChoiceChip(
                      label: Text(filterType.label),
                      selected: _selectedTransactionFilter == filterType,
                      onSelected: (bool isSelected) {
                        if (!isSelected) {
                          return;
                        }
                        _applyState(() {
                          _selectedTransactionFilter = filterType;
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            if (_selectedTransactionAccountFilter != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.scheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: context.scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filter kas: ${_selectedTransactionAccountFilter!}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _applyState(() {
                            _selectedTransactionAccountFilter = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'Hapus filter kas',
                      ),
                    ],
                  ),
                ),
              ),
            if (_selectedTransactionCategoryFilter != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.scheme.secondaryContainer.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.category_outlined,
                        size: 18,
                        color: context.scheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filter kategori: ${_selectedTransactionCategoryFilter!}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _applyState(() {
                            _selectedTransactionCategoryFilter = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'Hapus filter kategori',
                      ),
                    ],
                  ),
                ),
              ),
            if (_selectedTransactionFilter ==
                _TransactionFilterType.specificMonth)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () =>
                      _pickSpecificMonth(monthKeys, effectiveSelectedMonthKey),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Pada bulan',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    child: Text(
                      _formatMonthYear(effectiveSelectedMonthKey),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            if (_selectedTransactionFilter == _TransactionFilterType.monthRange)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickRangeStartMonth(
                          monthKeys,
                          effectiveRangeStartMonthKey,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Dari bulan',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                          child: Text(
                            _formatMonthYear(effectiveRangeStartMonthKey),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickRangeEndMonth(
                          monthKeys,
                          effectiveRangeEndMonthKey,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Sampai bulan',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                          child: Text(
                            _formatMonthYear(effectiveRangeEndMonthKey),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            _TransactionSection(
              title: 'Semua Transaksi',
              transactions: filteredTransactions,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.initialMonth,
    required this.firstMonth,
    required this.lastMonth,
  });

  final DateTime initialMonth;
  final DateTime firstMonth;
  final DateTime lastMonth;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _visibleYear;

  @override
  void initState() {
    super.initState();
    _visibleYear = widget.initialMonth.year;
  }

  bool get _canGoToPreviousYear => _visibleYear > widget.firstMonth.year;

  bool get _canGoToNextYear => _visibleYear < widget.lastMonth.year;

  bool _isMonthEnabled(int month) {
    final int monthKey = _monthKey(DateTime(_visibleYear, month));
    return monthKey >= _monthKey(widget.firstMonth) &&
        monthKey <= _monthKey(widget.lastMonth);
  }

  bool _isSelectedMonth(int month) =>
      _visibleYear == widget.initialMonth.year &&
      month == widget.initialMonth.month;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih bulan'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  onPressed: _canGoToPreviousYear
                      ? () {
                          setState(() {
                            _visibleYear -= 1;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '$_visibleYear',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: _canGoToNextYear
                      ? () {
                          setState(() {
                            _visibleYear += 1;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(12, (int index) {
                final int month = index + 1;
                final bool isEnabled = _isMonthEnabled(month);
                return ChoiceChip(
                  label: Text(_shortMonthName(month)),
                  selected: _isSelectedMonth(month),
                  onSelected: isEnabled
                      ? (_) {
                          Navigator.of(
                            context,
                          ).pop(DateTime(_visibleYear, month));
                        }
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

class _TransactionSection extends StatelessWidget {
  const _TransactionSection({required this.title, required this.transactions});

  final String title;
  final List<_TransactionData> transactions;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Text(
            'Belum ada transaksi.',
            style: textTheme.bodyMedium?.copyWith(color: context.mutedText),
          ),
        for (final _TransactionData transaction in transactions)
          _TransactionItem(
            title: transaction.title,
            subtitle: transaction.subtitle,
            amount: transaction.formattedAmount,
            isExpense: transaction.isExpense,
          ),
      ],
    );
  }
}

class _TransactionData {
  const _TransactionData({
    required this.title,
    required this.account,
    required this.category,
    required this.amount,
    required this.date,
  });

  final String title;
  final String account;
  final String category;
  final int amount;
  final DateTime date;

  Map<String, Object> toJson() => <String, Object>{
    'title': title,
    'account': account,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  static _TransactionData? fromJson(Map<String, dynamic> json) {
    final String? title = json['title'] as String?;
    final String? account = json['account'] as String?;
    final String? category = json['category'] as String?;
    final int? amount = json['amount'] as int?;
    final String? dateRaw = json['date'] as String?;
    final DateTime parsedDate = dateRaw == null
        ? DateTime.now()
        : DateTime.tryParse(dateRaw)?.toLocal() ?? DateTime.now();
    if (title == null ||
        account == null ||
        category == null ||
        amount == null) {
      return null;
    }
    return _TransactionData(
      title: title,
      account: account,
      category: category,
      amount: amount,
      date: parsedDate,
    );
  }

  bool get isExpense => amount < 0;
  String get subtitle =>
      '$account - $category - ${_formatTransactionDate(date)}';
  String get formattedAmount =>
      '${isExpense ? '-' : '+'}${_formatWholeCurrency(amount.abs())}';
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color amountColor = isExpense
        ? const Color(0xFF9F2F2A)
        : const Color(0xFF1E8F52);
    final Color iconColor = isExpense
        ? const Color(0xFFB6463F)
        : const Color(0xFF2B995D);
    final Color iconBackground = isExpense
        ? const Color(0xFFF8EDE8)
        : const Color(0xFFE9F4EC);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF9E9E9E).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBackground,
                  ),
                  child: Icon(
                    isExpense ? Icons.redo_rounded : Icons.reply_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.mutedText,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: textTheme.titleMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
