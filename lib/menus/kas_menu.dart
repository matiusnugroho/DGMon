part of 'package:dgmon/main.dart';

extension _KasMenuX on _FinanceDashboardPageState {
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cashAccounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final _CashAccount account = _cashAccounts[index];
                  return _CashAccountSettingItem(
                    accountName: account.name,
                    currentBalance: _balanceForAccount(account.name),
                    openingBalance: account.openingBalance,
                    onActionSelected: (_CashAccountMenuAction action) {
                      _handleCashAccountMenuAction(
                        index: index,
                        account: account,
                        action: action,
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _handleAddCashAccount,
                icon: const Icon(Icons.add),
                label: const Text('Tambah akun kas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashAccountSettingItem extends StatelessWidget {
  const _CashAccountSettingItem({
    required this.accountName,
    required this.currentBalance,
    required this.openingBalance,
    required this.onActionSelected,
  });

  final String accountName;
  final int currentBalance;
  final int openingBalance;
  final ValueChanged<_CashAccountMenuAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF9E9E9E).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF2F0),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: context.scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saat ini ${_formatSignedCurrency(currentBalance)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.mutedText,
                  ),
                ),
                Text(
                  'Saldo awal ${_formatWholeCurrency(openingBalance)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_CashAccountMenuAction>(
            tooltip: 'Aksi akun kas',
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.mutedText,
              size: 22,
            ),
            onSelected: onActionSelected,
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<_CashAccountMenuAction>>[
                  PopupMenuItem<_CashAccountMenuAction>(
                    value: _CashAccountMenuAction.viewTransactions,
                    child: _SettingsMenuItemRow(
                      icon: Icons.receipt_long,
                      label: _CashAccountMenuAction.viewTransactions.label,
                    ),
                  ),
                  PopupMenuItem<_CashAccountMenuAction>(
                    value: _CashAccountMenuAction.editAccount,
                    child: _SettingsMenuItemRow(
                      icon: Icons.edit_outlined,
                      label: _CashAccountMenuAction.editAccount.label,
                    ),
                  ),
                  PopupMenuItem<_CashAccountMenuAction>(
                    value: _CashAccountMenuAction.adjustBalance,
                    child: _SettingsMenuItemRow(
                      icon: Icons.tune_rounded,
                      label: _CashAccountMenuAction.adjustBalance.label,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<_CashAccountMenuAction>(
                    value: _CashAccountMenuAction.deleteAccount,
                    child: _SettingsMenuItemRow(
                      icon: Icons.delete_outline,
                      label: _CashAccountMenuAction.deleteAccount.label,
                      isDestructive: true,
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}
