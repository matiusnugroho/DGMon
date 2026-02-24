import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _storageBoxName = 'dgmon_storage';
const String _cashAccountsStorageKey = 'cash_accounts';
const String _categoriesStorageKey = 'categories';
const String _transactionsStorageKey = 'transactions';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(_storageBoxName);
  runApp(const DgMonApp());
}

enum _CategoryFlow { income, expense }

extension _CategoryFlowX on _CategoryFlow {
  String get label => this == _CategoryFlow.income ? 'Masuk' : 'Keluar';
}

String _flowToStorage(_CategoryFlow flow) =>
    flow == _CategoryFlow.income ? 'income' : 'expense';

_CategoryFlow _flowFromStorage(String value) =>
    value == 'income' ? _CategoryFlow.income : _CategoryFlow.expense;

class _CategoryData {
  const _CategoryData({
    required this.id,
    required this.name,
    required this.flow,
  });

  final String id;
  final String name;
  final _CategoryFlow flow;

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'name': name,
    'flow': _flowToStorage(flow),
  };

  static _CategoryData? fromJson(Map<String, dynamic> json) {
    final String? id = json['id'] as String?;
    final String? name = json['name'] as String?;
    final String? flowRaw = json['flow'] as String?;
    if (id == null || name == null || flowRaw == null) {
      return null;
    }
    return _CategoryData(id: id, name: name, flow: _flowFromStorage(flowRaw));
  }
}

class _CashAccount {
  const _CashAccount({required this.name, required this.openingBalance});

  final String name;
  final int openingBalance;

  Map<String, Object> toJson() => <String, Object>{
    'name': name,
    'openingBalance': openingBalance,
  };

  static _CashAccount? fromJson(Map<String, dynamic> json) {
    final String? name = json['name'] as String?;
    final int? openingBalance = json['openingBalance'] as int?;
    if (name == null || openingBalance == null) {
      return null;
    }
    return _CashAccount(name: name, openingBalance: openingBalance);
  }
}

class DgMonApp extends StatelessWidget {
  const DgMonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DGMon Keuangan',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      ),
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

class FinanceDashboardPage extends StatefulWidget {
  const FinanceDashboardPage({super.key});

  @override
  State<FinanceDashboardPage> createState() => _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends State<FinanceDashboardPage> {
  int _categorySeed = 0;
  int _selectedBottomNavIndex = 0;
  late List<_CashAccount> _cashAccounts;
  late List<_CategoryData> _categories;
  late List<_TransactionData> _transactions;

  String _nextCategoryId() => 'cat-${++_categorySeed}';

  @override
  void initState() {
    super.initState();
    _cashAccounts = _defaultCashAccounts();
    _categories = _defaultCategories();
    _transactions = _defaultTransactions();
    _categorySeed = _deriveCategorySeed(_categories);
    _loadPersistedState();
  }

  Box<dynamic>? get _storageBox => Hive.isBoxOpen(_storageBoxName)
      ? Hive.box<dynamic>(_storageBoxName)
      : null;

  List<_CashAccount> _defaultCashAccounts() => <_CashAccount>[
    const _CashAccount(name: 'BRI', openingBalance: 20000000),
    const _CashAccount(name: 'Tunai', openingBalance: 1000000),
    const _CashAccount(name: 'Dompet', openingBalance: 0),
  ];

  List<_CategoryData> _defaultCategories() => <_CategoryData>[
    const _CategoryData(
      id: 'cat-1',
      name: 'Makan',
      flow: _CategoryFlow.expense,
    ),
    const _CategoryData(
      id: 'cat-2',
      name: 'Minum',
      flow: _CategoryFlow.expense,
    ),
    const _CategoryData(
      id: 'cat-3',
      name: 'Transportasi',
      flow: _CategoryFlow.expense,
    ),
    const _CategoryData(id: 'cat-4', name: 'Gaji', flow: _CategoryFlow.income),
  ];

  List<_TransactionData> _defaultTransactions() => <_TransactionData>[
    const _TransactionData(
      title: 'Motor',
      account: 'Dompet',
      category: 'Transportasi',
      amount: -15000,
    ),
    const _TransactionData(
      title: 'Makan',
      account: 'BRI',
      category: 'Makan',
      amount: -20000,
    ),
  ];

  int _deriveCategorySeed(List<_CategoryData> categories) {
    int maxId = 4;
    final RegExp pattern = RegExp(r'^cat-(\d+)$');
    for (final _CategoryData category in categories) {
      final RegExpMatch? match = pattern.firstMatch(category.id);
      final int? parsed = match == null ? null : int.tryParse(match.group(1)!);
      if (parsed != null && parsed > maxId) {
        maxId = parsed;
      }
    }
    return maxId;
  }

  List<T> _decodeStoredList<T>(
    dynamic raw,
    T? Function(Map<String, dynamic>) parser,
  ) {
    if (raw is! List) {
      return <T>[];
    }

    final List<T> output = <T>[];
    for (final dynamic item in raw) {
      if (item is! Map) {
        continue;
      }
      final Map<String, dynamic> normalizedMap = <String, dynamic>{};
      item.forEach((dynamic key, dynamic value) {
        normalizedMap[key.toString()] = value;
      });
      final T? parsed = parser(normalizedMap);
      if (parsed != null) {
        output.add(parsed);
      }
    }
    return output;
  }

  void _loadPersistedState() {
    final Box<dynamic>? box = _storageBox;
    if (box == null) {
      return;
    }

    final List<_CashAccount> storedAccounts = _decodeStoredList<_CashAccount>(
      box.get(_cashAccountsStorageKey),
      _CashAccount.fromJson,
    );
    final List<_CategoryData> storedCategories =
        _decodeStoredList<_CategoryData>(
          box.get(_categoriesStorageKey),
          _CategoryData.fromJson,
        );
    final List<_TransactionData> storedTransactions =
        _decodeStoredList<_TransactionData>(
          box.get(_transactionsStorageKey),
          _TransactionData.fromJson,
        );

    if (storedAccounts.isNotEmpty) {
      _cashAccounts = storedAccounts;
    }
    if (storedCategories.isNotEmpty) {
      _categories = storedCategories;
    }
    if (storedTransactions.isNotEmpty) {
      _transactions = storedTransactions;
    }
    _categorySeed = _deriveCategorySeed(_categories);

    final bool hasNoStoredState =
        !box.containsKey(_cashAccountsStorageKey) &&
        !box.containsKey(_categoriesStorageKey) &&
        !box.containsKey(_transactionsStorageKey);
    if (hasNoStoredState) {
      _persistState();
    }
  }

  void _persistState() {
    final Box<dynamic>? box = _storageBox;
    if (box == null) {
      return;
    }

    unawaited(
      box.put(
        _cashAccountsStorageKey,
        _cashAccounts
            .map((_CashAccount account) => account.toJson())
            .toList(growable: false),
      ),
    );
    unawaited(
      box.put(
        _categoriesStorageKey,
        _categories
            .map((_CategoryData category) => category.toJson())
            .toList(growable: false),
      ),
    );
    unawaited(
      box.put(
        _transactionsStorageKey,
        _transactions
            .map((_TransactionData transaction) => transaction.toJson())
            .toList(growable: false),
      ),
    );
  }

  int _balanceForAccount(String accountName) {
    final _CashAccount account = _cashAccounts.firstWhere(
      (_CashAccount item) => item.name == accountName,
    );

    final int movement = _transactions
        .where((_TransactionData tx) => tx.account == accountName)
        .fold<int>(0, (int sum, _TransactionData tx) => sum + tx.amount);

    return account.openingBalance + movement;
  }

  int get _totalBalance => _cashAccounts.fold<int>(
    0,
    (int sum, _CashAccount account) => sum + _balanceForAccount(account.name),
  );

  int get _totalIncome => _transactions
      .where((_TransactionData tx) => tx.amount > 0)
      .fold<int>(0, (int sum, _TransactionData tx) => sum + tx.amount);

  int get _totalExpense => _transactions
      .where((_TransactionData tx) => tx.amount < 0)
      .fold<int>(0, (int sum, _TransactionData tx) => sum + tx.amount.abs());

  int get _netValue => _totalIncome - _totalExpense;

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<_CategoryData?> _showCreateCategoryDialog() async {
    String categoryName = '';
    _CategoryFlow selectedFlow = _CategoryFlow.expense;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<_CategoryData>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext modalContext,
                void Function(void Function()) setModalState,
              ) {
                return AlertDialog(
                  title: const Text('Tambah kategori'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Nama kategori',
                          ),
                          validator: (String? value) {
                            final String trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Nama kategori wajib diisi';
                            }
                            final bool alreadyExists = _categories.any(
                              (_CategoryData category) =>
                                  category.name.toLowerCase() ==
                                  trimmed.toLowerCase(),
                            );
                            if (alreadyExists) {
                              return 'Kategori sudah ada';
                            }
                            return null;
                          },
                          onChanged: (String value) => categoryName = value,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<_CategoryFlow>(
                          initialValue: selectedFlow,
                          decoration: const InputDecoration(labelText: 'Arus'),
                          items: _CategoryFlow.values
                              .map(
                                (_CategoryFlow flow) =>
                                    DropdownMenuItem<_CategoryFlow>(
                                      value: flow,
                                      child: Text(flow.label),
                                    ),
                              )
                              .toList(),
                          onChanged: (_CategoryFlow? value) {
                            if (value == null) {
                              return;
                            }
                            setModalState(() {
                              selectedFlow = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.of(dialogContext).pop(
                          _CategoryData(
                            id: _nextCategoryId(),
                            name: categoryName.trim(),
                            flow: selectedFlow,
                          ),
                        );
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                );
              },
        );
      },
    );
  }

  Future<_CashAccount?> _showCreateCashAccountDialog() async {
    String accountName = '';
    String openingBalanceText = '0';
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<_CashAccount>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tambah akun kas'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nama akun'),
                  validator: (String? value) {
                    final String trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Nama akun wajib diisi';
                    }
                    final bool alreadyExists = _cashAccounts.any(
                      (_CashAccount account) =>
                          account.name.toLowerCase() == trimmed.toLowerCase(),
                    );
                    if (alreadyExists) {
                      return 'Akun kas sudah ada';
                    }
                    return null;
                  },
                  onChanged: (String value) => accountName = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: openingBalanceText,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Saldo awal',
                    prefixText: 'Rp ',
                  ),
                  validator: (String? value) {
                    if (_parseNonNegativeWholeNumber(value) == null) {
                      return 'Saldo awal tidak valid';
                    }
                    return null;
                  },
                  onChanged: (String value) => openingBalanceText = value,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.of(dialogContext).pop(
                  _CashAccount(
                    name: accountName.trim(),
                    openingBalance:
                        _parseNonNegativeWholeNumber(openingBalanceText) ?? 0,
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAddTransaction() async {
    if (_categories.isEmpty) {
      _showSnack('Belum ada kategori. Tambah dulu di Pengaturan.');
      return;
    }

    final _TransactionData? newTransaction =
        await showModalBottomSheet<_TransactionData>(
          context: context,
          isScrollControlled: true,
          backgroundColor: context.cardBackground,
          builder: (_) => _AddTransactionSheet(
            accounts: _cashAccounts
                .map((_CashAccount account) => account.name)
                .toList(growable: false),
            categories: _categories,
          ),
        );

    if (!mounted || newTransaction == null) {
      return;
    }

    setState(() {
      _transactions.insert(0, newTransaction);
      _persistState();
    });
  }

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
            ),
            const SizedBox(height: 24),
            const _InsightSection(),
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

  Widget _buildPengaturanKasTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Pengaturan Kas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola akun kas dan saldo awal.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.mutedText),
            ),
            const SizedBox(height: 16),
            if (_cashAccounts.isEmpty)
              Text(
                'Belum ada akun kas.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.mutedText),
              ),
            if (_cashAccounts.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cashAccounts.length,
                itemBuilder: (BuildContext context, int index) {
                  final _CashAccount account = _cashAccounts[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(account.name),
                    subtitle: Text(
                      'Saldo awal ${_formatWholeCurrency(account.openingBalance)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        if (_cashAccounts.length == 1) {
                          _showSnack('Minimal harus ada satu akun kas.');
                          return;
                        }

                        final bool hasTransaction = _transactions.any(
                          (_TransactionData transaction) =>
                              transaction.account == account.name,
                        );
                        if (hasTransaction) {
                          _showSnack(
                            'Akun ini sudah dipakai transaksi dan tidak bisa dihapus.',
                          );
                          return;
                        }

                        setState(() {
                          _cashAccounts.removeAt(index);
                          _persistState();
                        });
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final _CashAccount? newAccount =
                      await _showCreateCashAccountDialog();
                  if (!mounted || newAccount == null) {
                    return;
                  }

                  setState(() {
                    _cashAccounts.add(newAccount);
                    _persistState();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah akun kas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPengaturanKategoriTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Pengaturan Kategori',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola kategori pemasukan dan pengeluaran.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.mutedText),
            ),
            const SizedBox(height: 16),
            if (_categories.isEmpty)
              Text(
                'Belum ada kategori.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.mutedText),
              ),
            if (_categories.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                itemBuilder: (BuildContext context, int index) {
                  final _CategoryData category = _categories[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(category.name),
                    subtitle: Text(category.flow.label),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _categories.length == 1
                          ? null
                          : () {
                              setState(() {
                                _categories.removeAt(index);
                                _persistState();
                              });
                            },
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final _CategoryData? newCategory =
                      await _showCreateCategoryDialog();
                  if (!mounted || newCategory == null) {
                    return;
                  }
                  setState(() {
                    _categories.add(newCategory);
                    _persistState();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah kategori'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaftarTransaksiTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Daftar Transaksi',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Semua catatan pemasukan dan pengeluaran.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.mutedText),
            ),
            const SizedBox(height: 20),
            _TransactionSection(
              title: 'Semua Transaksi',
              transactions: _transactions,
            ),
          ],
        ),
      ),
    );
  }

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
          onPressed: _handleAddTransaction,
          child: Icon(Icons.add, size: 28, color: context.scheme.onPrimary),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedBottomNavIndex,
        onTap: (int index) {
          if (_selectedBottomNavIndex == index) {
            return;
          }
          setState(() {
            _selectedBottomNavIndex = index;
          });
        },
      ),
      body: switch (_selectedBottomNavIndex) {
        0 => _buildRingkasanTab(),
        1 => _buildDaftarTransaksiTab(),
        2 => _buildPengaturanKasTab(),
        _ => _buildPengaturanKategoriTab(),
      },
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet({
    required this.accounts,
    required this.categories,
  });

  final List<String> accounts;
  final List<_CategoryData> categories;

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedAccount;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.accounts.isEmpty ? null : widget.accounts.first;
    _selectedCategoryId = widget.categories.isEmpty
        ? null
        : widget.categories.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccount == null || _selectedCategoryId == null) {
      return;
    }

    final int? rawAmount = _parsePositiveWholeNumber(_amountController.text);
    if (rawAmount == null) {
      return;
    }

    final _CategoryData selectedCategory = widget.categories.firstWhere(
      (_CategoryData category) => category.id == _selectedCategoryId,
    );

    final int signedAmount = selectedCategory.flow == _CategoryFlow.expense
        ? -rawAmount
        : rawAmount;

    Navigator.of(context).pop(
      _TransactionData(
        title: _titleController.text.trim(),
        account: _selectedAccount!,
        category: selectedCategory.name,
        amount: signedAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tambah Transaksi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nama transaksi',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama transaksi wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
              validator: (String? value) {
                if (_parsePositiveWholeNumber(value) == null) {
                  return 'Nominal tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccount,
              decoration: const InputDecoration(
                labelText: 'Akun',
                border: OutlineInputBorder(),
              ),
              items: widget.accounts
                  .map(
                    (String account) => DropdownMenuItem<String>(
                      value: account,
                      child: Text(account),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedAccount = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: widget.categories
                  .map(
                    (_CategoryData category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text('${category.name} (${category.flow.label})'),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveTransaction,
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int? _parsePositiveWholeNumber(String? value) {
  if (value == null) {
    return null;
  }
  final String numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (numericOnly.isEmpty) {
    return null;
  }
  final int? parsedValue = int.tryParse(numericOnly);
  if (parsedValue == null || parsedValue <= 0) {
    return null;
  }
  return parsedValue;
}

int? _parseNonNegativeWholeNumber(String? value) {
  if (value == null) {
    return null;
  }
  final String numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (numericOnly.isEmpty) {
    return null;
  }
  return int.tryParse(numericOnly);
}

String _formatWholeCurrency(int value) {
  final String source = value.toString();
  final List<String> chunks = <String>[];
  for (int i = source.length; i > 0; i -= 3) {
    final int start = i - 3 < 0 ? 0 : i - 3;
    chunks.insert(0, source.substring(start, i));
  }
  return 'Rp ${chunks.join('.')}';
}

String _formatSignedCurrency(int value) {
  if (value < 0) {
    return '-${_formatWholeCurrency(value.abs())}';
  }
  return _formatWholeCurrency(value);
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
              'Selamat pagi, Duo',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keuanganmu lagi rapi hari ini.',
              style: textTheme.bodyMedium?.copyWith(color: context.mutedText),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            CircleAvatar(
              radius: 22,
              backgroundColor: context.gradientStart,
              child: Icon(Icons.person, color: context.scheme.onPrimary),
            ),
          ],
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'TOTAL SALDO',
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
  const _AccountCarousel({required this.accounts});

  final List<_AccountBalanceData> accounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: accounts
            .map(
              (_AccountBalanceData account) =>
                  _AccountCard(name: account.name, balance: account.balance),
            )
            .toList(growable: false),
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
            _formatSignedCurrency(balance),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: balance < 0 ? context.scheme.error : null,
            ),
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
        'Pengeluaran minggu ini naik 65% untuk kategori makan dibanding minggu lalu.',
        style: textTheme.bodyMedium,
      ),
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
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
  });

  final String title;
  final String account;
  final String category;
  final int amount;

  Map<String, Object> toJson() => <String, Object>{
    'title': title,
    'account': account,
    'category': category,
    'amount': amount,
  };

  static _TransactionData? fromJson(Map<String, dynamic> json) {
    final String? title = json['title'] as String?;
    final String? account = json['account'] as String?;
    final String? category = json['category'] as String?;
    final int? amount = json['amount'] as int?;
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
    );
  }

  bool get isExpense => amount < 0;
  String get subtitle => '$account - $category - Hari ini';
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
              color: isExpense ? context.scheme.error : context.scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

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
            IconButton(
              onPressed: () => onTap(0),
              tooltip: 'Ringkasan',
              icon: Icon(
                Icons.dashboard,
                color: selectedIndex == 0
                    ? context.scheme.primary
                    : context.scheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              onPressed: () => onTap(1),
              tooltip: 'Daftar transaksi',
              icon: Icon(
                Icons.receipt_long,
                color: selectedIndex == 1
                    ? context.scheme.primary
                    : context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 40),
            IconButton(
              onPressed: () => onTap(2),
              tooltip: 'Pengaturan kas',
              icon: Icon(
                Icons.account_balance_wallet_outlined,
                color: selectedIndex == 2
                    ? context.scheme.primary
                    : context.scheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              onPressed: () => onTap(3),
              tooltip: 'Pengaturan kategori',
              icon: Icon(
                Icons.category_outlined,
                color: selectedIndex == 3
                    ? context.scheme.primary
                    : context.scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
