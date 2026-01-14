import 'package:flutter/foundation.dart';

class Expense {
  final String id;
  final String category;
  final int amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        category: json['category'] as String,
        amount: json['amount'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}
