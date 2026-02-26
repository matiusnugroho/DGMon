import 'dart:async';

import 'package:excel/excel.dart' as xl;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'menus/ringkasan_menu.dart';
part 'menus/kas_menu.dart';
part 'menus/kategori_menu.dart';
part 'menus/transaksi_menu.dart';

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

enum _TransactionFilterType { today, thisMonth, specificMonth, monthRange }

extension _TransactionFilterTypeX on _TransactionFilterType {
  String get label => switch (this) {
    _TransactionFilterType.today => 'Hari ini',
    _TransactionFilterType.thisMonth => 'Bulan ini',
    _TransactionFilterType.specificMonth => 'Pada bulan',
    _TransactionFilterType.monthRange => 'Rentang bulan',
  };
}

enum _TransactionMenuAction { exportFilteredExcel, exportAllExcel }

extension _TransactionMenuActionX on _TransactionMenuAction {
  String get label => switch (this) {
    _TransactionMenuAction.exportFilteredExcel => 'Unduh sesuai filter',
    _TransactionMenuAction.exportAllExcel => 'Unduh semua transaksi',
  };
}

enum _CashAccountMenuAction {
  viewTransactions,
  editAccount,
  adjustBalance,
  deleteAccount,
}

extension _CashAccountMenuActionX on _CashAccountMenuAction {
  String get label => switch (this) {
    _CashAccountMenuAction.viewTransactions => 'Lihat transaksi',
    _CashAccountMenuAction.editAccount => 'Edit akun',
    _CashAccountMenuAction.adjustBalance => 'Adjust saldo',
    _CashAccountMenuAction.deleteAccount => 'Hapus akun',
  };
}

enum _CategoryMenuAction { viewTransactions, editCategory, deleteCategory }

extension _CategoryMenuActionX on _CategoryMenuAction {
  String get label => switch (this) {
    _CategoryMenuAction.viewTransactions => 'Lihat transaksi',
    _CategoryMenuAction.editCategory => 'Edit kategori',
    _CategoryMenuAction.deleteCategory => 'Hapus kategori',
  };
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
  _TransactionFilterType _selectedTransactionFilter =
      _TransactionFilterType.today;
  String? _selectedTransactionAccountFilter;
  String? _selectedTransactionCategoryFilter;
  late List<_CashAccount> _cashAccounts;
  late List<_CategoryData> _categories;
  late List<_TransactionData> _transactions;
  late int _selectedMonthKey;
  late int _rangeStartMonthKey;
  late int _rangeEndMonthKey;

  String _nextCategoryId() => 'cat-${++_categorySeed}';

  @override
  void initState() {
    super.initState();
    _cashAccounts = _defaultCashAccounts();
    _categories = _defaultCategories();
    _transactions = _defaultTransactions();
    _categorySeed = _deriveCategorySeed(_categories);
    _loadPersistedState();
    final int currentMonthKey = _monthKey(DateTime.now());
    _selectedMonthKey = currentMonthKey;
    _rangeStartMonthKey = currentMonthKey;
    _rangeEndMonthKey = currentMonthKey;
  }

  Box<dynamic>? get _storageBox => Hive.isBoxOpen(_storageBoxName)
      ? Hive.box<dynamic>(_storageBoxName)
      : null;

  List<_CashAccount> _defaultCashAccounts() => <_CashAccount>[];

  List<_CategoryData> _defaultCategories() => <_CategoryData>[];

  List<_TransactionData> _defaultTransactions() => <_TransactionData>[];

  int _deriveCategorySeed(List<_CategoryData> categories) {
    int maxId = 0;
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

  List<int> _availableMonthKeys() {
    final DateTime now = DateTime.now();
    int minYear = now.year - 5;
    int maxYear = now.year + 2;

    for (final _TransactionData transaction in _transactions) {
      final int year = transaction.date.toLocal().year;
      if (year < minYear) {
        minYear = year;
      }
      if (year > maxYear) {
        maxYear = year;
      }
    }

    final List<int> monthKeys = <int>[];
    for (int year = maxYear; year >= minYear; year--) {
      for (int month = 12; month >= 1; month--) {
        monthKeys.add(year * 100 + month);
      }
    }
    return monthKeys;
  }

  List<_TransactionData> _filteredTransactions({
    required int selectedMonthKey,
    required int rangeStartMonthKey,
    required int rangeEndMonthKey,
    String? accountFilter,
    String? categoryFilter,
  }) {
    final DateTime now = DateTime.now();
    final int normalizedRangeStart = rangeStartMonthKey <= rangeEndMonthKey
        ? rangeStartMonthKey
        : rangeEndMonthKey;
    final int normalizedRangeEnd = rangeStartMonthKey <= rangeEndMonthKey
        ? rangeEndMonthKey
        : rangeStartMonthKey;

    return _transactions
        .where((_TransactionData transaction) {
          if (accountFilter != null && transaction.account != accountFilter) {
            return false;
          }
          if (categoryFilter != null &&
              transaction.category != categoryFilter) {
            return false;
          }
          final DateTime transactionDate = transaction.date.toLocal();
          switch (_selectedTransactionFilter) {
            case _TransactionFilterType.today:
              return _isSameDay(transactionDate, now);
            case _TransactionFilterType.thisMonth:
              return transactionDate.year == now.year &&
                  transactionDate.month == now.month;
            case _TransactionFilterType.specificMonth:
              return _monthKey(transactionDate) == selectedMonthKey;
            case _TransactionFilterType.monthRange:
              final int transactionMonthKey = _monthKey(transactionDate);
              return transactionMonthKey >= normalizedRangeStart &&
                  transactionMonthKey <= normalizedRangeEnd;
          }
        })
        .toList(growable: false);
  }

  Future<void> _handleAddCashAccount() async {
    final _CashAccount? newAccount = await _showCreateCashAccountDialog();
    if (!mounted || newAccount == null) {
      return;
    }

    setState(() {
      _cashAccounts.add(newAccount);
      _persistState();
    });
  }

  void _openTransactionsForAccount(String accountName) {
    setState(() {
      _selectedBottomNavIndex = 1;
      _selectedTransactionAccountFilter = accountName;
      _selectedTransactionCategoryFilter = null;
    });
  }

  void _openTransactionsForCategory(String categoryName) {
    setState(() {
      _selectedBottomNavIndex = 1;
      _selectedTransactionCategoryFilter = categoryName;
      _selectedTransactionAccountFilter = null;
    });
  }

  Future<String?> _showEditCashAccountDialog(_CashAccount account) async {
    String accountName = account.name;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit akun kas'),
          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: account.name,
              decoration: const InputDecoration(labelText: 'Nama akun'),
              validator: (String? value) {
                final String trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Nama akun wajib diisi';
                }
                final bool duplicateExists = _cashAccounts.any(
                  (_CashAccount item) =>
                      item.name.toLowerCase() == trimmed.toLowerCase() &&
                      item.name.toLowerCase() != account.name.toLowerCase(),
                );
                if (duplicateExists) {
                  return 'Akun kas sudah ada';
                }
                return null;
              },
              onChanged: (String value) => accountName = value,
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
                Navigator.of(dialogContext).pop(accountName.trim());
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _showAdjustBalanceDialog(_CashAccount account) async {
    bool isIncrease = true;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController();

    final int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext modalContext,
                void Function(void Function()) setModalState,
              ) {
                return AlertDialog(
                  title: const Text('Adjust saldo akun'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Saldo saat ini ${_formatSignedCurrency(_balanceForAccount(account.name))}',
                          style: Theme.of(modalContext).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: <Widget>[
                            ChoiceChip(
                              label: const Text('Tambah'),
                              selected: isIncrease,
                              onSelected: (_) {
                                setModalState(() {
                                  isIncrease = true;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Kurangi'),
                              selected: !isIncrease,
                              onSelected: (_) {
                                setModalState(() {
                                  isIncrease = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            _ThousandSeparatorInputFormatter(),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Nominal adjust',
                            prefixText: 'Rp ',
                          ),
                          validator: (String? value) {
                            if (_parsePositiveWholeNumber(value) == null) {
                              return 'Nominal tidak valid';
                            }
                            return null;
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
                        final int amount =
                            _parsePositiveWholeNumber(amountController.text) ??
                            0;
                        Navigator.of(
                          dialogContext,
                        ).pop(isIncrease ? amount : -amount);
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                );
              },
        );
      },
    );

    amountController.dispose();
    return result;
  }

  Future<void> _deleteCashAccountAt(int index) async {
    if (_cashAccounts.length == 1) {
      _showSnack('Minimal harus ada satu akun kas.');
      return;
    }

    final _CashAccount account = _cashAccounts[index];
    final bool hasTransaction = _transactions.any(
      (_TransactionData transaction) => transaction.account == account.name,
    );
    if (hasTransaction) {
      _showSnack('Akun ini sudah dipakai transaksi dan tidak bisa dihapus.');
      return;
    }

    setState(() {
      _cashAccounts.removeAt(index);
      if (_selectedTransactionAccountFilter == account.name) {
        _selectedTransactionAccountFilter = null;
      }
      _persistState();
    });
  }

  Future<void> _handleCashAccountMenuAction({
    required int index,
    required _CashAccount account,
    required _CashAccountMenuAction action,
  }) async {
    int resolveIndex() {
      if (index >= 0 &&
          index < _cashAccounts.length &&
          _cashAccounts[index].name == account.name) {
        return index;
      }
      return _cashAccounts.indexWhere(
        (_CashAccount item) => item.name == account.name,
      );
    }

    switch (action) {
      case _CashAccountMenuAction.viewTransactions:
        _openTransactionsForAccount(account.name);
        return;
      case _CashAccountMenuAction.editAccount:
        final String? newName = await _showEditCashAccountDialog(account);
        if (!mounted || newName == null || newName == account.name) {
          return;
        }
        final int currentIndex = resolveIndex();
        if (currentIndex == -1) {
          return;
        }
        setState(() {
          final String oldName = _cashAccounts[currentIndex].name;
          _cashAccounts[currentIndex] = _CashAccount(
            name: newName,
            openingBalance: _cashAccounts[currentIndex].openingBalance,
          );
          _transactions = _transactions
              .map(
                (_TransactionData tx) => tx.account == oldName
                    ? _TransactionData(
                        title: tx.title,
                        account: newName,
                        category: tx.category,
                        amount: tx.amount,
                        date: tx.date,
                      )
                    : tx,
              )
              .toList(growable: false);
          if (_selectedTransactionAccountFilter == oldName) {
            _selectedTransactionAccountFilter = newName;
          }
          _persistState();
        });
        return;
      case _CashAccountMenuAction.adjustBalance:
        final int? delta = await _showAdjustBalanceDialog(account);
        if (!mounted || delta == null || delta == 0) {
          return;
        }
        final int currentIndex = resolveIndex();
        if (currentIndex == -1) {
          return;
        }
        setState(() {
          final _CashAccount current = _cashAccounts[currentIndex];
          _cashAccounts[currentIndex] = _CashAccount(
            name: current.name,
            openingBalance: current.openingBalance + delta,
          );
          _persistState();
        });
        return;
      case _CashAccountMenuAction.deleteAccount:
        final int currentIndex = resolveIndex();
        if (currentIndex == -1) {
          return;
        }
        await _deleteCashAccountAt(currentIndex);
        return;
    }
  }

  Future<_CategoryData?> _showEditCategoryDialog(_CategoryData category) async {
    String categoryName = category.name;
    _CategoryFlow selectedFlow = category.flow;
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
                  title: const Text('Edit kategori'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          initialValue: category.name,
                          decoration: const InputDecoration(
                            labelText: 'Nama kategori',
                          ),
                          validator: (String? value) {
                            final String trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Nama kategori wajib diisi';
                            }
                            final bool duplicateExists = _categories.any(
                              (_CategoryData item) =>
                                  item.name.toLowerCase() ==
                                      trimmed.toLowerCase() &&
                                  item.id != category.id,
                            );
                            if (duplicateExists) {
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
                            id: category.id,
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

  Future<void> _deleteCategoryAt(int index) async {
    if (_categories.length == 1) {
      _showSnack('Minimal harus ada satu kategori.');
      return;
    }

    final _CategoryData category = _categories[index];
    final bool hasTransaction = _transactions.any(
      (_TransactionData tx) => tx.category == category.name,
    );
    if (hasTransaction) {
      _showSnack(
        'Kategori ini sudah dipakai transaksi dan tidak bisa dihapus.',
      );
      return;
    }

    setState(() {
      _categories.removeAt(index);
      if (_selectedTransactionCategoryFilter == category.name) {
        _selectedTransactionCategoryFilter = null;
      }
      _persistState();
    });
  }

  Future<void> _handleCategoryMenuAction({
    required int index,
    required _CategoryData category,
    required _CategoryMenuAction action,
  }) async {
    int resolveIndex() {
      if (index >= 0 &&
          index < _categories.length &&
          _categories[index].id == category.id) {
        return index;
      }
      return _categories.indexWhere(
        (_CategoryData item) => item.id == category.id,
      );
    }

    switch (action) {
      case _CategoryMenuAction.viewTransactions:
        _openTransactionsForCategory(category.name);
        return;
      case _CategoryMenuAction.editCategory:
        final _CategoryData? editedCategory = await _showEditCategoryDialog(
          category,
        );
        if (!mounted || editedCategory == null) {
          return;
        }
        final int currentIndex = resolveIndex();
        if (currentIndex == -1) {
          return;
        }
        final _CategoryData currentCategory = _categories[currentIndex];
        setState(() {
          _categories[currentIndex] = editedCategory;
          if (editedCategory.name != currentCategory.name) {
            _transactions = _transactions
                .map(
                  (_TransactionData tx) => tx.category == currentCategory.name
                      ? _TransactionData(
                          title: tx.title,
                          account: tx.account,
                          category: editedCategory.name,
                          amount: tx.amount,
                          date: tx.date,
                        )
                      : tx,
                )
                .toList(growable: false);
            if (_selectedTransactionCategoryFilter == currentCategory.name) {
              _selectedTransactionCategoryFilter = editedCategory.name;
            }
          }
          _persistState();
        });
        return;
      case _CategoryMenuAction.deleteCategory:
        final int currentIndex = resolveIndex();
        if (currentIndex == -1) {
          return;
        }
        await _deleteCategoryAt(currentIndex);
        return;
    }
  }

  Future<int?> _showMonthPickerDialog(
    List<int> monthKeys,
    int initialMonthKey,
  ) async {
    if (monthKeys.isEmpty) {
      return null;
    }

    final DateTime? pickedMonth = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _MonthPickerDialog(
          initialMonth: _dateFromMonthKey(initialMonthKey),
          firstMonth: _dateFromMonthKey(monthKeys.last),
          lastMonth: _dateFromMonthKey(monthKeys.first),
        );
      },
    );
    if (!mounted || pickedMonth == null) {
      return null;
    }
    return _monthKey(pickedMonth);
  }

  Future<void> _pickSpecificMonth(
    List<int> monthKeys,
    int effectiveSelectedMonthKey,
  ) async {
    final int? pickedMonthKey = await _showMonthPickerDialog(
      monthKeys,
      effectiveSelectedMonthKey,
    );
    if (!mounted || pickedMonthKey == null) {
      return;
    }

    setState(() {
      _selectedMonthKey = pickedMonthKey;
    });
  }

  Future<void> _pickRangeStartMonth(
    List<int> monthKeys,
    int effectiveRangeStartMonthKey,
  ) async {
    final int? pickedMonthKey = await _showMonthPickerDialog(
      monthKeys,
      effectiveRangeStartMonthKey,
    );
    if (!mounted || pickedMonthKey == null) {
      return;
    }

    setState(() {
      _rangeStartMonthKey = pickedMonthKey;
    });
  }

  Future<void> _pickRangeEndMonth(
    List<int> monthKeys,
    int effectiveRangeEndMonthKey,
  ) async {
    final int? pickedMonthKey = await _showMonthPickerDialog(
      monthKeys,
      effectiveRangeEndMonthKey,
    );
    if (!mounted || pickedMonthKey == null) {
      return;
    }

    setState(() {
      _rangeEndMonthKey = pickedMonthKey;
    });
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _applyState(VoidCallback updater) {
    if (!mounted) {
      return;
    }
    setState(updater);
  }

  Future<void> _exportTransactionRecapExcel(
    List<_TransactionData> transactions,
  ) async {
    if (transactions.isEmpty) {
      _showSnack('Tidak ada transaksi untuk diekspor.');
      return;
    }

    final String fileName = _buildTransactionRecapFileName(DateTime.now());
    final Uint8List bytes = _buildTransactionRecapExcelBytes(transactions);
    Object? saveAsError;

    try {
      final String? path = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      if (!mounted) {
        return;
      }
      if (path == null || path.isEmpty) {
        _showSnack('Penyimpanan dibatalkan.');
        return;
      }
      _showSnack('Rekap Excel berhasil diunduh.');
      return;
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      _showSnack(
        'Fitur unduh belum aktif. Stop app lalu jalankan ulang, jangan hanya hot reload.',
      );
      return;
    } catch (error) {
      saveAsError = error;
      // Fallback saat Save As tidak tersedia pada platform tertentu.
    }

    try {
      final String path = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      if (!mounted) {
        return;
      }
      final String normalizedPath = path.toLowerCase();
      if (normalizedPath.startsWith('error while saving file')) {
        throw StateError(path);
      }
      _showSnack('Rekap Excel tersimpan di $path');
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      _showSnack(
        'Plugin unduh belum aktif. Stop app lalu jalankan ulang, jangan hanya hot reload.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      debugPrint(
        'Export excel failed. saveAsError=$saveAsError saveFileError=$error',
      );
      _showSnack('Gagal membuat file Excel.');
    }
  }

  Uint8List _buildTransactionRecapExcelBytes(List<_TransactionData> source) {
    final xl.Excel workbook = xl.Excel.createExcel();
    const String sheetName = 'Rekap';
    final String defaultSheetName = workbook.getDefaultSheet() ?? 'Sheet1';
    if (defaultSheetName != sheetName) {
      workbook.rename(defaultSheetName, sheetName);
    }
    workbook.setDefaultSheet(sheetName);

    workbook.appendRow(sheetName, <xl.CellValue?>[
      xl.TextCellValue('Tanggal'),
      xl.TextCellValue('Transaksi'),
      xl.TextCellValue('Akun'),
      xl.TextCellValue('Kategori'),
      xl.TextCellValue('Arus'),
      xl.TextCellValue('Nominal'),
    ]);

    for (final _TransactionData transaction in source) {
      workbook.appendRow(sheetName, <xl.CellValue?>[
        xl.TextCellValue(_formatDateForExport(transaction.date.toLocal())),
        xl.TextCellValue(transaction.title),
        xl.TextCellValue(transaction.account),
        xl.TextCellValue(transaction.category),
        xl.TextCellValue(transaction.isExpense ? 'Keluar' : 'Masuk'),
        xl.IntCellValue(transaction.amount),
      ]);
    }

    final int totalIncome = source
        .where((_TransactionData tx) => tx.amount > 0)
        .fold<int>(0, (int sum, _TransactionData tx) => sum + tx.amount);
    final int totalExpense = source
        .where((_TransactionData tx) => tx.amount < 0)
        .fold<int>(0, (int sum, _TransactionData tx) => sum + tx.amount.abs());
    final int netAmount = totalIncome - totalExpense;

    workbook.appendRow(sheetName, <xl.CellValue?>[]);
    workbook.appendRow(sheetName, <xl.CellValue?>[
      xl.TextCellValue('Total pemasukan'),
      xl.IntCellValue(totalIncome),
    ]);
    workbook.appendRow(sheetName, <xl.CellValue?>[
      xl.TextCellValue('Total pengeluaran'),
      xl.IntCellValue(-totalExpense),
    ]);
    workbook.appendRow(sheetName, <xl.CellValue?>[
      xl.TextCellValue('Selisih'),
      xl.IntCellValue(netAmount),
    ]);

    final List<int>? encoded = workbook.encode();
    if (encoded == null) {
      throw StateError('Workbook tidak dapat di-encode.');
    }
    return Uint8List.fromList(encoded);
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
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandSeparatorInputFormatter(),
                  ],
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
    if (_cashAccounts.isEmpty) {
      _showSnack('Belum ada akun kas. Tambah dulu di menu Kas.');
      return;
    }

    if (_categories.isEmpty) {
      _showSnack('Belum ada kategori. Tambah dulu di menu Kategori.');
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
      _selectedBottomNavIndex = 1;
      _selectedTransactionAccountFilter = null;
      _selectedTransactionCategoryFilter = null;
      _selectedTransactionFilter = _TransactionFilterType.specificMonth;
      _selectedMonthKey = _monthKey(newTransaction.date);
      _persistState();
    });
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
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.accounts.isEmpty ? null : widget.accounts.first;
    _selectedCategoryId = widget.categories.isEmpty
        ? null
        : widget.categories.first.id;
    _selectedDate = DateTime.now();
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
        date: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
      ),
    );
  }

  Future<void> _pickTransactionDate() async {
    final DateTime initialDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Pilih tanggal transaksi',
    );
    if (pickedDate == null) {
      return;
    }
    setState(() {
      _selectedDate = pickedDate;
    });
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
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                _ThousandSeparatorInputFormatter(),
              ],
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
            InkWell(
              onTap: _pickTransactionDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal transaksi',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(_formatDateForInput(_selectedDate)),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: context.mutedText,
                    ),
                  ],
                ),
              ),
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

const List<String> _monthNames = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> _shortMonthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

int _monthKey(DateTime date) => date.year * 100 + date.month;

DateTime _dateFromMonthKey(int monthKey) =>
    DateTime(monthKey ~/ 100, monthKey % 100);

bool _isSameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _monthName(int month) => _monthNames[month - 1];

String _shortMonthName(int month) => _shortMonthNames[month - 1];

String _formatMonthYear(int monthKey) {
  final DateTime monthDate = _dateFromMonthKey(monthKey);
  return '${_monthName(monthDate.month)} ${monthDate.year}';
}

String _formatTransactionDate(DateTime date) {
  final DateTime localDate = date.toLocal();
  if (_isSameDay(localDate, DateTime.now())) {
    return 'Hari ini';
  }
  return '${localDate.day} ${_shortMonthName(localDate.month)} ${localDate.year}';
}

String _formatDateForInput(DateTime date) {
  final DateTime localDate = date.toLocal();
  if (_isSameDay(localDate, DateTime.now())) {
    return 'Hari ini (${localDate.day} ${_monthName(localDate.month)} ${localDate.year})';
  }
  return '${localDate.day} ${_monthName(localDate.month)} ${localDate.year}';
}

String _formatDateForExport(DateTime date) {
  final DateTime localDate = date.toLocal();
  return '${_padTwoDigits(localDate.day)}-${_padTwoDigits(localDate.month)}-${localDate.year}';
}

String _buildTransactionRecapFileName(DateTime dateTime) {
  return 'rekap_transaksi_${dateTime.year}${_padTwoDigits(dateTime.month)}${_padTwoDigits(dateTime.day)}_${_padTwoDigits(dateTime.hour)}${_padTwoDigits(dateTime.minute)}';
}

String _padTwoDigits(int value) => value.toString().padLeft(2, '0');

String _formatGroupedNumber(String source) {
  final List<String> chunks = <String>[];
  for (int i = source.length; i > 0; i -= 3) {
    final int start = i - 3 < 0 ? 0 : i - 3;
    chunks.insert(0, source.substring(start, i));
  }
  return chunks.join('.');
}

class _ThousandSeparatorInputFormatter extends TextInputFormatter {
  const _ThousandSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final String formatted = _formatGroupedNumber(numericOnly);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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

String _formatWholeCurrency(int value) =>
    'Rp ${_formatGroupedNumber(value.toString())}';

String _formatSignedCurrency(int value) {
  if (value < 0) {
    return '-${_formatWholeCurrency(value.abs())}';
  }
  return _formatWholeCurrency(value);
}

String _greetingForHour(int hour) {
  if (hour >= 4 && hour < 11) {
    return 'Selamat pagi';
  }
  if (hour >= 11 && hour < 15) {
    return 'Selamat siang';
  }
  if (hour >= 15 && hour < 18) {
    return 'Selamat sore';
  }
  return 'Selamat malam';
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
        height: 72,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _BottomNavItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                selected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.receipt_long,
                label: 'Transaksi',
                selected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
            const SizedBox(width: 56),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Kas',
                selected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.category_outlined,
                label: 'Kategori',
                selected: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color itemColor = selected
        ? context.scheme.primary
        : context.scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: itemColor, size: 20),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: itemColor,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
