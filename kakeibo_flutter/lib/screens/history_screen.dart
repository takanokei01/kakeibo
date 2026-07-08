import 'package:flutter/material.dart';
import 'package:sample/models/expense.dart';

class HistoryScreen extends StatefulWidget {
  final List<Expense> expenses;
  final Future<Expense?> Function(Expense expense) onEditExpense;
  final Future<bool> Function(Expense expense) onDeleteExpense;

  const HistoryScreen({
    super.key,
    required this.expenses,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<Expense> _expenses;

  @override
  void initState() {
    super.initState();
    _expenses = List<Expense>.from(widget.expenses);
  }

  Map<DateTime, List<Expense>> _groupExpensesByMonth() {
    final grouped = <DateTime, List<Expense>>{};
    for (final expense in _expenses) {
      final key = DateTime(expense.date.year, expense.date.month);
      grouped.putIfAbsent(key, () => []).add(expense);
    }
    return grouped;
  }

  int _monthTotal(List<Expense> monthExpenses) {
    return monthExpenses.fold(0, (sum, e) => sum + e.amount);
  }

  Future<void> _editExpense(Expense expense) async {
    final updated = await widget.onEditExpense(expense);
    if (updated == null) return;

    setState(() {
      final index = _expenses.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _expenses[index] = updated;
      }
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _deleteExpense(Expense expense) async {
    final deleted = await widget.onDeleteExpense(expense);
    if (!deleted) return;

    setState(() {
      _expenses.removeWhere((e) => e.id == expense.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupExpensesByMonth();
    final sortedMonths = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('支出履歴')),
      body: sortedMonths.isEmpty
          ? const Center(child: Text('支出がありません'))
          : ListView.builder(
              itemCount: sortedMonths.length,
              itemBuilder: (context, index) {
                final month = sortedMonths[index];
                final monthExpenses = grouped[month]!;
                final total = _monthTotal(monthExpenses);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.blue.shade50,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${month.year}年${month.month}月',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '合計: ¥$total',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...monthExpenses.map((e) {
                      return ListTile(
                        title: Text(e.category),
                        subtitle: Text(
                          e.memo.isEmpty
                              ? '${e.date.year}/${e.date.month}/${e.date.day}'
                              : '${e.date.year}/${e.date.month}/${e.date.day}\n${e.memo}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¥${e.amount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editExpense(e);
                                } else if (value == 'delete') {
                                  _deleteExpense(e);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('編集')),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('削除'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                  ],
                );
              },
            ),
    );
  }
}
