import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sample/firebase_options.dart';
import 'package:sample/models/expense.dart';

class ExpenseDatabase {
  static const _boxNamePrefix = 'expenses_';
  static const _usersCollection = 'users';
  static const _expensesCollection = 'expenses';

  static Box<dynamic>? _box;
  static FirebaseFirestore? _firestore;
  static bool _firestoreEnabled = false;
  static String? _userId;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  static Future<void> init() async {
    await Hive.initFlutter();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firestore = FirebaseFirestore.instance;
      _firestoreEnabled = true;
    } catch (error) {
      debugPrint('Firebase init failed or not configured: $error');
      _firestoreEnabled = false;
    }
  }

  static Future<void> setUser(String? userId) async {
    if (_userId == userId && (_box?.isOpen ?? false)) {
      return;
    }

    await _subscription?.cancel();
    _subscription = null;

    final previousBox = _box;
    _box = null;
    _userId = null;
    if (previousBox != null && previousBox.isOpen) {
      await previousBox.close();
    }

    if (userId == null) {
      return;
    }

    final box = await Hive.openBox<dynamic>(_boxNameForUser(userId));
    _box = box;
    _userId = userId;

    if (!_firestoreEnabled || _firestore == null) {
      return;
    }

    final initialSync = Completer<void>();
    _subscription = _collectionFor(userId).snapshots().listen(
      (snapshot) async {
        if (_userId != userId || _box != box || !box.isOpen) {
          if (!initialSync.isCompleted) initialSync.complete();
          return;
        }

        try {
          for (final change in snapshot.docChanges) {
            final document = change.doc;
            if (change.type == DocumentChangeType.removed) {
              await box.delete(document.id);
              continue;
            }

            final data = document.data();
            if (data == null) {
              continue;
            }

            try {
              final expense = Expense.fromJson(data);
              await box.put(expense.id, expense.toJson());
            } catch (error) {
              debugPrint('Error converting Firestore doc to Expense: $error');
            }
          }
        } catch (error) {
          debugPrint('Error syncing Firestore expenses: $error');
        } finally {
          if (!initialSync.isCompleted) initialSync.complete();
        }
      },
      onError: (Object error) {
        debugPrint('Firestore listener error: $error');
        if (!initialSync.isCompleted) initialSync.complete();
      },
    );

    await initialSync.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  static Future<List<Expense>> getExpenses() async {
    final box = _requireBox();
    try {
      final expenses =
          box.values
              .whereType<Map<dynamic, dynamic>>()
              .map((json) => Expense.fromJson(Map<String, dynamic>.from(json)))
              .toList()
            ..sort((first, second) => second.date.compareTo(first.date));
      return expenses;
    } catch (error) {
      debugPrint('Error loading expenses: $error');
      return [];
    }
  }

  static Future<void> insertExpense(Expense expense) async {
    final box = _requireBox();
    final userId = _requireUserId();
    await box.put(expense.id, expense.toJson());

    if (_firestoreEnabled && _firestore != null) {
      try {
        await _collectionFor(userId).doc(expense.id).set(expense.toJson());
      } catch (error) {
        debugPrint('Error writing expense to Firestore: $error');
      }
    }
  }

  static Future<void> updateExpense(Expense expense) async {
    await insertExpense(expense);
  }

  static Future<void> deleteExpense(String id) async {
    final box = _requireBox();
    final userId = _requireUserId();
    await box.delete(id);

    if (_firestoreEnabled && _firestore != null) {
      try {
        await _collectionFor(userId).doc(id).delete();
      } catch (error) {
        debugPrint('Error deleting expense from Firestore: $error');
      }
    }
  }

  static Future<void> clearAll() async {
    final box = _requireBox();
    final userId = _requireUserId();
    await box.clear();

    if (_firestoreEnabled && _firestore != null) {
      try {
        final batch = _firestore!.batch();
        final snapshots = await _collectionFor(userId).get();
        for (final document in snapshots.docs) {
          batch.delete(document.reference);
        }
        await batch.commit();
      } catch (error) {
        debugPrint('Error clearing Firestore expenses: $error');
      }
    }
  }

  static CollectionReference<Map<String, dynamic>> _collectionFor(
    String userId,
  ) {
    return _firestore!
        .collection(_usersCollection)
        .doc(userId)
        .collection(_expensesCollection);
  }

  static String _boxNameForUser(String userId) {
    final encodedUserId = userId.codeUnits
        .map((unit) => unit.toRadixString(16).padLeft(4, '0'))
        .join();
    return '$_boxNamePrefix$encodedUserId';
  }

  static Box<dynamic> _requireBox() {
    final box = _box;
    if (box == null || !box.isOpen || _userId == null) {
      throw StateError('ExpenseDatabase has no authenticated user.');
    }
    return box;
  }

  static String _requireUserId() {
    final userId = _userId;
    if (userId == null) {
      throw StateError('ExpenseDatabase has no authenticated user.');
    }
    return userId;
  }

  static Future<void> dispose() async {
    await setUser(null);
  }
}
