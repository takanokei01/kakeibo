import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sample/data/expense_database.dart';
import 'package:sample/models/expense.dart';
import 'package:sample/widgets/num_pad.dart';
import 'package:sample/screens/history_screen.dart';

class MainPageWidget extends StatefulWidget {
  const MainPageWidget({super.key});

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
      if (!mounted) return;
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

  Future<Expense?> _editExpense(Expense expense) async {
    final updated = await showDialog<Expense>(
      context: context,
      builder: (context) =>
          _ExpenseEditDialog(expense: expense, categories: _categories),
    );

    if (updated == null) return null;

    setState(() {
      final index = _expenses.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _expenses[index] = updated;
      }
    });
    await ExpenseDatabase.updateExpense(updated);
    return updated;
  }

  Future<bool> _confirmDeleteExpense(Expense expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支出を削除しますか？'),
        content: Text('${expense.category} ¥${expense.amount} を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _removeExpense(expense.id);
      return true;
    }
    return false;
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          expenses: _expenses,
          onEditExpense: _editExpense,
          onDeleteExpense: _confirmDeleteExpense,
        ),
      ),
    );
  }

  int get _monthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0, (int prev, e) => prev + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final recentExpenses = _expenses.take(10).toList();

    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('MY家計簿')),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                title: Text(
                  'MY家計簿',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ログアウト'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 今月の合計
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '今月いくら使ったか',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¥${_monthTotal.toString()}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _openHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 8.0,
                          ),
                          child: Text(
                            '履歴を見る',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // カテゴリ選択
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    children: [
                      const Text('カテゴリ：'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedCategory,
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _selectedCategory = v;
                          });
                        },
                      ),
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
                  child: Text(
                    '直近の支出',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                if (_expenses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('まだ支出がありません'),
                    ),
                  )
                else ...[
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: recentExpenses.length,
                    itemBuilder: (context, index) {
                      final e = recentExpenses[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          e.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          e.memo.isEmpty
                              ? '${e.date.month}/${e.date.day}'
                              : '${e.date.month}/${e.date.day}  ${e.memo}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¥${e.amount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editExpense(e);
                                } else if (value == 'delete') {
                                  _confirmDeleteExpense(e);
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
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openHistory,
                      child: const Text('もっと見る'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseEditDialog extends StatefulWidget {
  final Expense expense;
  final List<String> categories;

  const _ExpenseEditDialog({required this.expense, required this.categories});

  @override
  State<_ExpenseEditDialog> createState() => _ExpenseEditDialogState();
}

class _ExpenseEditDialogState extends State<_ExpenseEditDialog> {
  late String _category;
  late TextEditingController _amountController;
  late TextEditingController _memoController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _category = widget.categories.contains(widget.expense.category)
        ? widget.expense.category
        : widget.categories.first;
    _amountController = TextEditingController(
      text: widget.expense.amount.toString(),
    );
    _memoController = TextEditingController(text: widget.expense.memo);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _errorText = '金額を正しく入力してください';
      });
      return;
    }

    Navigator.pop(
      context,
      Expense(
        id: widget.expense.id,
        category: _category,
        amount: amount,
        date: widget.expense.date,
        memo: _memoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('支出を編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'カテゴリ'),
              items: widget.categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _category = value;
                });
              },
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: '金額'),
            ),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(labelText: 'メモ'),
              maxLines: 3,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
