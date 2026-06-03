import 'package:flutter/material.dart';
import 'package:sample/data/expense_database.dart';
import 'package:sample/models/expense.dart';
import 'package:sample/widgets/num_pad.dart';
import 'package:sample/screens/history_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final databaseExpenses = await ExpenseDatabase.getExpenses();
      setState(() {
        _expenses.clear();
        _expenses.addAll(databaseExpenses);
      });
      print('✓ ロード完了: ${databaseExpenses.length}件の支出を読み込みました');
    } catch (e) {
      print('✗ ロードエラー: $e');
    }
  }

  Future<void> _addExpense(int amount) async {
    final e = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedCategory,
      amount: amount,
      date: DateTime.now(),
    );
    setState(() {
      _expenses.insert(0, e);
    });
    try {
      await ExpenseDatabase.insertExpense(e);
      print('✓ 保存完了: ¥$amount($_selectedCategory) ID: ${e.id}');
    } catch (error) {
      print('✗ 保存エラー: $error');
      // エラー時はUIから削除
      setState(() {
        _expenses.removeWhere((ex) => ex.id == e.id);
      });
    }
  }

  Future<void> _removeExpense(String id) async {
    setState(() {
      _expenses.removeWhere((e) => e.id == id);
    });
    await ExpenseDatabase.deleteExpense(id);
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
      appBar: AppBar(title: const Text('MY家計簿')), 
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 今月の合計
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('今月いくら使ったか', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('¥${_monthTotal.toString()}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistoryScreen(expenses: _expenses),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                          child: Text('履歴を見る', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // カテゴリ選択
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
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

                const SizedBox(height: 12),

                // 計算機（テンキー）
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                        ),
                        NumPad(onSubmit: _addExpense),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 直近の支出
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                  child: Text('直近の支出', style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                _expenses.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('まだ支出がありません')))
                    : ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
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
                              padding: const EdgeInsets.only(right: 10),
                              child: const Icon(Icons.delete, color: Colors.white, size: 20),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(e.category, style: const TextStyle(fontSize: 12)),
                              subtitle: Text('${e.date.month}/${e.date.day}', style: const TextStyle(fontSize: 10)),
                              trailing: Text('¥${e.amount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}