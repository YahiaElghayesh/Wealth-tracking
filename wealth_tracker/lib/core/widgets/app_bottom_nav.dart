import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The bottom nav from the approved mockup: Net Worth and Calculator sit as
/// plain items either side, while Ledger and Statistics share one rounded
/// accent-soft pill background -- a graphical tie between those two tabs,
/// present on every screen, not just Statistics'. Flutter's stock
/// [NavigationBar] has no notion of grouping two destinations under one
/// shared background, hence this custom bar instead.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Net Worth',
    ),
    (
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Ledger',
    ),
    (
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Ledger Statistics',
    ),
    (
      icon: Icons.calculate_outlined,
      selectedIcon: Icons.calculate,
      label: 'Calculator',
    ),
    (
      icon: Icons.event_repeat_outlined,
      selectedIcon: Icons.event_repeat,
      label: 'Recurring',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  item: _items[0],
                  selected: index == 0,
                  onTap: () => onChanged(0),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          item: _items[1],
                          selected: index == 1,
                          onTap: () => onChanged(1),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          item: _items[2],
                          selected: index == 2,
                          onTap: () => onChanged(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _NavItem(
                  item: _items[3],
                  selected: index == 3,
                  onTap: () => onChanged(3),
                ),
              ),
              Expanded(
                child: _NavItem(
                  item: _items[4],
                  selected: index == 4,
                  onTap: () => onChanged(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData selectedIcon, String label}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final color = selected ? theme.colorScheme.primary : colors.textDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
