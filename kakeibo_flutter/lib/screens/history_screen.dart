import 'package:flutter/material.dart';
import 'package:sample/models/expense.dart';

class HistoryScreen extends StatelessWidget {
  final List<Expense> expenses;

  const HistoryScreen({Key? key, required this.expenses}) : super(key: key);

  // 月ごとに支出をグループ化
  Map<String, List<Expense>> _groupExpensesByMonth() {
    final grouped = <String, List<Expense>>{};
    for (final expense in expenses) {
      final key = '${expense.date.year}年${expense.date.month}月';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(expense);
    }
    return grouped;
  }

  // 月の合計を計算
  int _monthTotal(List<Expense> monthExpenses) {
    return monthExpenses.fold(0, (sum, e) => sum + e.amount);
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
                          vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(month,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('合計: ¥$total',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ],
                      ),
                    ),
                    ...monthExpenses.asMap().entries.map((entry) {
                      final e = entry.value;
                      return ListTile(
                        title: Text(e.category),
                        subtitle: Text(
                          e.memo.isEmpty
                              ? '${e.date.year}/${e.date.month}/${e.date.day}'
                              : '${e.date.year}/${e.date.month}/${e.date.day}\n${e.memo}',
                        ),
                        trailing: Text('¥${e.amount}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    const Divider(),
                  ],
                );
              },
            ),
    );
  }
}
