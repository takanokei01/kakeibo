import 'package:flutter/material.dart';
import 'package:sample/models/expense.dart';
import 'package:sample/widgets/num_pad.dart';

class MainPageWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MainPageWidget();
  }
}

class _MainPageWidget extends State<MainPageWidget> {
  final List<Expense> _expenses = [];
  final List<String> _categories = ['食費', '交通費', '日用品', 'その他'];
  String _selectedCategory = '食費';

  void _addExpense(int amount) {
    final e = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedCategory,
      amount: amount,
      date: DateTime.now(),
    );
    setState(() {
      _expenses.insert(0, e);
    });
  }

  void _removeExpense(String id) {
    setState(() {
      _expenses.removeWhere((e) => e.id == id);
    });
  }

  int get _monthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0, (int prev, e) => prev + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家計簿')), 
      body: SafeArea(
        child: Column(
          children: [
            // 今月の合計
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('今月いくら使ったか', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('¥${_monthTotal.toString()}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ),

            // カテゴリ選択
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text('カテゴリ：'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _selectedCategory = v;
                      });
                    },
                  )
                ],
              ),
            ),

            // テンキー（高さを柔軟にしてオーバーフローを防ぐ）
            Flexible(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: NumPad(onSubmit: _addExpense),
              ),
            ),

            const Divider(),

            // 直近支出リスト
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Align(alignment: Alignment.centerLeft, child: Text('直近の支出')),
            ),
            Expanded(
              child: _expenses.isEmpty
                  ? const Center(child: Text('まだ支出がありません'))
                  : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final e = _expenses[index];
                        return Dismissible(
                          key: Key(e.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _removeExpense(e.id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: ListTile(
                            title: Text(e.category),
                            subtitle: Text('${e.date.year}/${e.date.month}/${e.date.day}'),
                            trailing: Text('¥${e.amount}'),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}