import 'package:hive_flutter/hive_flutter.dart';
import 'package:sample/models/expense.dart';

class ExpenseDatabase {
  static const _boxName = 'expenses';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box<dynamic> get _box => Hive.box(_boxName);

  static Future<List<Expense>> getExpenses() async {
    final values = _box.values;
    final expenses = values
        .cast<Map<dynamic, dynamic>>()
        .map((json) => Expense.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  static Future<void> insertExpense(Expense expense) async {
    await _box.put(expense.id, expense.toJson());
  }

  static Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }
}
