part of 'package:dgmon/main.dart';

extension _KategoriMenuX on _FinanceDashboardPageState {
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final _CategoryData category = _categories[index];
                  return _CategorySettingItem(
                    categoryName: category.name,
                    flow: category.flow,
                    onActionSelected: (_CategoryMenuAction action) {
                      _handleCategoryMenuAction(
                        index: index,
                        category: category,
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
                onPressed: () async {
                  final _CategoryData? newCategory =
                      await _showCreateCategoryDialog();
                  if (!mounted || newCategory == null) {
                    return;
                  }
                  _applyState(() {
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
}

class _CategorySettingItem extends StatelessWidget {
  const _CategorySettingItem({
    required this.categoryName,
    required this.flow,
    required this.onActionSelected,
  });

  final String categoryName;
  final _CategoryFlow flow;
  final ValueChanged<_CategoryMenuAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isExpense = flow == _CategoryFlow.expense;
    final Color badgeColor = isExpense
        ? const Color(0xFFF8EDE8)
        : const Color(0xFFE9F4EC);
    final Color iconColor = isExpense
        ? const Color(0xFFB6463F)
        : const Color(0xFF2B995D);

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
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor,
            ),
            child: Icon(
              isExpense ? Icons.redo_rounded : Icons.reply_rounded,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  flow == _CategoryFlow.expense
                      ? 'Kategori pengeluaran'
                      : 'Kategori pemasukan',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_CategoryMenuAction>(
            tooltip: 'Aksi kategori',
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
                <PopupMenuEntry<_CategoryMenuAction>>[
                  PopupMenuItem<_CategoryMenuAction>(
                    value: _CategoryMenuAction.viewTransactions,
                    child: _SettingsMenuItemRow(
                      icon: Icons.receipt_long,
                      label: _CategoryMenuAction.viewTransactions.label,
                    ),
                  ),
                  PopupMenuItem<_CategoryMenuAction>(
                    value: _CategoryMenuAction.editCategory,
                    child: _SettingsMenuItemRow(
                      icon: Icons.edit_outlined,
                      label: _CategoryMenuAction.editCategory.label,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<_CategoryMenuAction>(
                    value: _CategoryMenuAction.deleteCategory,
                    child: _SettingsMenuItemRow(
                      icon: Icons.delete_outline,
                      label: _CategoryMenuAction.deleteCategory.label,
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

class _SettingsMenuItemRow extends StatelessWidget {
  const _SettingsMenuItemRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    const Color softMenuTextColor = Color(0xFF4A5560);
    final Color textColor = isDestructive
        ? context.scheme.error
        : softMenuTextColor;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: textColor),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: textColor)),
      ],
    );
  }
}
