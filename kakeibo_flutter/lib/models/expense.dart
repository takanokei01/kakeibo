class Expense {
  final String id;
  final String category;
  final int amount;
  final DateTime date;
  final String memo;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.memo = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'memo': memo,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toInt(),
        date: DateTime.parse(json['date'] as String),
        memo: json['memo'] as String? ?? '',
      );
}
