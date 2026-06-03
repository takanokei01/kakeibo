import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sample/firebase_options.dart';
import 'package:sample/models/expense.dart';

class ExpenseDatabase {
  static const _boxName = 'expenses';
  static late Box<dynamic> _box;
  static FirebaseFirestore? _firestore;
  static bool _firestoreEnabled = false;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  /// 初期化: Hive と（可能であれば）Firebase を初期化し、Firestore の変更をローカル Hive に反映するリスナーを開始します。
  static Future<void> init() async {
    // Hive 初期化
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      print('Hive initialization error: $e');
      rethrow;
    }

    // Firebase がまだ初期化されていなければ、生成された options で初期化
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firestore = FirebaseFirestore.instance;
      _firestoreEnabled = true;

      // Firestore -> Hive の一方向同期（リアルタイム）
      _subscription = _firestore!
          .collection(_boxName)
          .snapshots()
          .listen((snapshot) {
        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
            final data = doc.data();
            if (data != null) {
              try {
                final expense = Expense.fromJson(Map<String, dynamic>.from(data));
                _box.put(expense.id, expense.toJson());
              } catch (e) {
                print('Error converting Firestore doc to Expense: $e');
              }
            }
          } else if (change.type == DocumentChangeType.removed) {
            _box.delete(doc.id);
          }
        }
        print('Firestore sync: received ${snapshot.docChanges.length} changes');
      }, onError: (e) {
        print('Firestore listener error: $e');
      });
    } catch (e) {
      print('Firebase init failed or not configured: $e');
      _firestoreEnabled = false;
    }
  }

  static Box<dynamic> get box => _box;

  static Future<List<Expense>> getExpenses() async {
    try {
      final values = _box.values.toList();
      final expenses = values
          .whereType<Map<dynamic, dynamic>>()
          .map((json) => Expense.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    } catch (e) {
      print('Error loading expenses: $e');
      return [];
    }
  }

  /// 追加: Hive に保存した後、Firestore にも書き込みを試みます。
  static Future<void> insertExpense(Expense expense) async {
    try {
      await _box.put(expense.id, expense.toJson());
    } catch (e) {
      print('Error inserting expense into Hive: $e');
      rethrow;
    }

    if (_firestoreEnabled && _firestore != null) {
      try {
        await _firestore!.collection(_boxName).doc(expense.id).set(expense.toJson());
      } catch (e) {
        print('Error writing expense to Firestore: $e');
      }
    }
  }

  /// 削除: Hive と Firestore の両方から削除します。
  static Future<void> deleteExpense(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      print('Error deleting expense from Hive: $e');
      rethrow;
    }

    if (_firestoreEnabled && _firestore != null) {
      try {
        await _firestore!.collection(_boxName).doc(id).delete();
      } catch (e) {
        print('Error deleting expense from Firestore: $e');
      }
    }
  }

  /// 完全クリア（開発用）
  static Future<void> clearAll() async {
    try {
      await _box.clear();
    } catch (e) {
      print('Error clearing expenses: $e');
      rethrow;
    }
    if (_firestoreEnabled && _firestore != null) {
      try {
        final batch = _firestore!.batch();
        final snapshots = await _firestore!.collection(_boxName).get();
        for (final doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        print('Error clearing Firestore expenses: $e');
      }
    }
  }

  /// アプリ終了時に呼ぶと Firestore リスナーを解除します。
  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
