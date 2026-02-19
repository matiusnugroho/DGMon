import 'package:flutter/material.dart';

void main() => runApp(const DgMonApp());

enum FlowType { inFlow, outFlow }

extension FlowTypeX on FlowType {
  String get label => this == FlowType.inFlow ? 'In' : 'Out';
  IconData get icon =>
      this == FlowType.inFlow ? Icons.call_received : Icons.call_made;
}

class CashAccount {
  const CashAccount({
    required this.id,
    required this.name,
    required this.openingBalance,
  });

  final String id;
  final String name;
  final double openingBalance;
}

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final FlowType type;
}

class TxItem {
  const TxItem({
    required this.id,
    required this.cashId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String id;
  final String cashId;
  final String categoryId;
  final FlowType type;
  final double amount;
  final DateTime date;
  final String note;
}

class DgMonApp extends StatelessWidget {
  const DgMonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DGMon Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
      ),
      home: const TrackerPage(),
    );
  }
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  int _tab = 0;
  int _seed = 0;
  late final List<CashAccount> _cashAccounts;
  late final List<CategoryItem> _categories;
  final List<TxItem> _transactions = <TxItem>[];

  @override
  void initState() {
    super.initState();
    _cashAccounts = <CashAccount>[
      CashAccount(id: _id('cash'), name: 'Wallet', openingBalance: 0),
    ];
    _categories = <CategoryItem>[
      CategoryItem(id: _id('cat'), name: 'Salary', type: FlowType.inFlow),
      CategoryItem(id: _id('cat'), name: 'Food', type: FlowType.outFlow),
      CategoryItem(id: _id('cat'), name: 'Transport', type: FlowType.outFlow),
    ];
  }

  String _id(String prefix) => '$prefix-${++_seed}';

  CashAccount _cashById(String id) =>
      _cashAccounts.firstWhere((CashAccount c) => c.id == id);
  CategoryItem _catById(String id) =>
      _categories.firstWhere((CategoryItem c) => c.id == id);

  List<TxItem> get _sortedTx {
    final List<TxItem> list = List<TxItem>.from(_transactions);
    list.sort((TxItem a, TxItem b) => b.date.compareTo(a.date));
    return list;
  }

  double _balance(CashAccount cash) {
    final double movement = _transactions
        .where((TxItem tx) => tx.cashId == cash.id)
        .fold<double>(0, (double sum, TxItem tx) {
          return sum + (tx.type == FlowType.inFlow ? tx.amount : -tx.amount);
        });
    return cash.openingBalance + movement;
  }

  double get _totalBalance => _cashAccounts.fold<double>(
    0,
    (double sum, CashAccount cash) => sum + _balance(cash),
  );

  double _sumByType(FlowType type) => _transactions
      .where((TxItem tx) => tx.type == type)
      .fold<double>(0, (double sum, TxItem tx) => sum + tx.amount);

  double? _toAmount(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));
  String _money(double value) => '\$${value.toStringAsFixed(2)}';
  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _createCash() async {
    String nameText = '';
    String openingText = '';
    final GlobalKey<FormState> form = GlobalKey<FormState>();

    final (String, double)? draft = await showDialog<(String, double)>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        scrollable: true,
        title: const Text('Create Cash Account'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (String v) => nameText = v,
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Opening balance'),
                onChanged: (String v) => openingText = v,
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty || _toAmount(v) != null)
                    ? null
                    : 'Invalid number',
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!(form.currentState?.validate() ?? false)) return;
              Navigator.pop(dialog, (
                nameText.trim(),
                _toAmount(openingText) ?? 0,
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || draft == null) return;

    setState(() {
      _cashAccounts.add(
        CashAccount(id: _id('cash'), name: draft.$1, openingBalance: draft.$2),
      );
    });
  }

  Future<void> _createCategory() async {
    String nameText = '';
    FlowType type = FlowType.outFlow;
    final GlobalKey<FormState> form = GlobalKey<FormState>();

    final (String, FlowType)? draft = await showDialog<(String, FlowType)>(
      context: context,
      builder: (BuildContext dialog) => StatefulBuilder(
        builder: (BuildContext _, void Function(void Function()) setDialog) {
          return AlertDialog(
            scrollable: true,
            title: const Text('Create Category'),
            content: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (String v) => nameText = v,
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  DropdownButtonFormField<FlowType>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: FlowType.values
                        .map(
                          (FlowType t) => DropdownMenuItem<FlowType>(
                            value: t,
                            child: Text(t.label),
                          ),
                        )
                        .toList(),
                    onChanged: (FlowType? v) {
                      if (v != null) setDialog(() => type = v);
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!(form.currentState?.validate() ?? false)) return;
                  Navigator.pop(dialog, (nameText.trim(), type));
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted || draft == null) return;

    setState(() {
      _categories.add(
        CategoryItem(id: _id('cat'), name: draft.$1, type: draft.$2),
      );
    });
  }

  Future<void> _createTransaction() async {
    if (_cashAccounts.isEmpty) {
      _snack('Create a cash account first.');
      return;
    }
    if (_categories.isEmpty) {
      _snack('Create a category first.');
      return;
    }

    String amountText = '';
    String noteText = '';
    final GlobalKey<FormState> form = GlobalKey<FormState>();
    FlowType type = FlowType.outFlow;
    String cashId = _cashAccounts.first.id;
    DateTime date = DateTime.now();
    String? categoryId;

    void syncCategory() {
      final List<CategoryItem> filtered = _categories
          .where((CategoryItem c) => c.type == type)
          .toList();
      categoryId = filtered.isEmpty ? null : (categoryId ?? filtered.first.id);
      if (filtered.isNotEmpty &&
          !filtered.any((CategoryItem c) => c.id == categoryId)) {
        categoryId = filtered.first.id;
      }
    }

    syncCategory();

    final TxItem? newTx = await showModalBottomSheet<TxItem>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheet) => StatefulBuilder(
        builder: (BuildContext _, void Function(void Function()) setSheet) {
          final List<CategoryItem> filtered = _categories
              .where((CategoryItem c) => c.type == type)
              .toList();
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(sheet).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SegmentedButton<FlowType>(
                      segments: const <ButtonSegment<FlowType>>[
                        ButtonSegment(
                          value: FlowType.inFlow,
                          label: Text('In'),
                        ),
                        ButtonSegment(
                          value: FlowType.outFlow,
                          label: Text('Out'),
                        ),
                      ],
                      selected: <FlowType>{type},
                      onSelectionChanged: (Set<FlowType> v) {
                        setSheet(() {
                          type = v.first;
                          syncCategory();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: cashId,
                      decoration: const InputDecoration(labelText: 'Cash'),
                      items: _cashAccounts
                          .map(
                            (CashAccount c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (String? v) {
                        if (v != null) setSheet(() => cashId = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (filtered.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: filtered
                            .map(
                              (CategoryItem c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (String? v) =>
                            setSheet(() => categoryId = v),
                      ),
                    if (filtered.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No category for selected type. Add one first.',
                        ),
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Amount'),
                      onChanged: (String v) => amountText = v,
                      validator: (String? v) {
                        final double? val = v == null ? null : _toAmount(v);
                        return (val == null || val <= 0)
                            ? 'Invalid amount'
                            : null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                      onChanged: (String v) => noteText = v,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(_date(date)),
                      trailing: TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setSheet(() => date = picked);
                          }
                        },
                        child: const Text('Pick'),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(sheet),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            if (!(form.currentState?.validate() ?? false)) {
                              return;
                            }
                            if (categoryId == null) {
                              _snack(
                                'Create category for ${type.label} first.',
                              );
                              return;
                            }
                            Navigator.pop(
                              sheet,
                              TxItem(
                                id: _id('tx'),
                                cashId: cashId,
                                categoryId: categoryId!,
                                type: type,
                                amount: _toAmount(amountText)!,
                                date: date,
                                note: noteText.trim(),
                              ),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (!mounted || newTx == null) return;
    setState(() => _transactions.add(newTx));
  }

  Widget _txTile(TxItem tx) {
    final Color color = tx.type == FlowType.inFlow
        ? Colors.green.shade700
        : Colors.red.shade700;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(tx.type.icon, color: color),
      ),
      title: Text(tx.note.isEmpty ? _catById(tx.categoryId).name : tx.note),
      subtitle: Text(
        '${_cashById(tx.cashId).name} | ${_catById(tx.categoryId).name} | ${_date(tx.date)}',
      ),
      trailing: Text(
        '${tx.type == FlowType.inFlow ? '+' : '-'}${_money(tx.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _overview() => ListView(
    padding: const EdgeInsets.all(16),
    children: <Widget>[
      Card(
        child: ListTile(
          title: const Text('Total Balance'),
          trailing: Text(
            _money(_totalBalance),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      Row(
        children: <Widget>[
          Expanded(
            child: Card(
              child: ListTile(
                title: const Text('In'),
                trailing: Text(_money(_sumByType(FlowType.inFlow))),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: ListTile(
                title: const Text('Out'),
                trailing: Text(_money(_sumByType(FlowType.outFlow))),
              ),
            ),
          ),
        ],
      ),
      Card(
        child: Column(
          children: _cashAccounts
              .map(
                (CashAccount c) => ListTile(
                  title: Text(c.name),
                  subtitle: Text('Opening: ${_money(c.openingBalance)}'),
                  trailing: Text(_money(_balance(c))),
                ),
              )
              .toList(),
        ),
      ),
      Card(child: Column(children: _sortedTx.take(5).map(_txTile).toList())),
    ],
  );

  Widget _transactionsView() {
    final List<TxItem> txs = _sortedTx;
    if (txs.isEmpty) {
      return const Center(child: Text('No transactions yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: txs.length,
      itemBuilder: (BuildContext context, int i) {
        final TxItem tx = txs[i];
        return Dismissible(
          key: ValueKey<String>(tx.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => setState(
            () => _transactions.removeWhere((TxItem t) => t.id == tx.id),
          ),
          background: Container(
            alignment: Alignment.centerRight,
            color: Theme.of(context).colorScheme.error,
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          child: Card(child: _txTile(tx)),
        );
      },
    );
  }

  Widget _manage() {
    final List<CategoryItem> inCats = _categories
        .where((CategoryItem c) => c.type == FlowType.inFlow)
        .toList();
    final List<CategoryItem> outCats = _categories
        .where((CategoryItem c) => c.type == FlowType.outFlow)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Cash Accounts'),
                    TextButton.icon(
                      onPressed: _createCash,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                ..._cashAccounts.map(
                  (CashAccount c) => ListTile(title: Text(c.name)),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Categories'),
                    TextButton.icon(
                      onPressed: _createCategory,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const Text('In'),
                ...inCats.map(
                  (CategoryItem c) => ListTile(title: Text(c.name)),
                ),
                const SizedBox(height: 8),
                const Text('Out'),
                ...outCats.map(
                  (CategoryItem c) => ListTile(title: Text(c.name)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _overview(),
      _transactionsView(),
      _manage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('DGMon Expense Tracker'),
        actions: <Widget>[
          IconButton(
            onPressed: _createTransaction,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create transaction',
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: _createTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Transaction'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (int i) => setState(() => _tab = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Tx',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Manage',
          ),
        ],
      ),
    );
  }
}
