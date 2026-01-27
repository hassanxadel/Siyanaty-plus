import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';

/// Service for expense tracking and management
class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // ==================== LOCAL DATABASE METHODS ====================

  /// Add a new expense
  Future<int> addExpense(Expense expense) async {
    try {
      return await _dbHelper.insertExpense(expense.toMap());
    } catch (e) {
      print('[Expense] Error adding expense: $e');
      rethrow;
    }
  }

  /// Get all expenses for a car
  Future<List<Expense>> getExpensesByCar(int carId) async {
    try {
      final maps = await _dbHelper.getExpensesByCar(carId);
      return maps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      print('[Expense] Error getting expenses: $e');
      return [];
    }
  }

  /// Get expenses by category
  Future<List<Expense>> getExpensesByCategory(int carId, String category) async {
    try {
      final maps = await _dbHelper.getExpensesByCategory(carId, category);
      return maps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      print('[Expense] Error getting expenses by category: $e');
      return [];
    }
  }

  /// Get expenses in date range
  Future<List<Expense>> getExpensesInRange(int carId, DateTime startDate, DateTime endDate) async {
    try {
      final maps = await _dbHelper.getExpensesInRange(
        carId,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      );
      return maps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      print('[Expense] Error getting expenses in range: $e');
      return [];
    }
  }

  /// Get monthly expenses
  Future<List<Expense>> getMonthlyExpenses(int carId, int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return getExpensesInRange(carId, startDate, endDate);
  }

  /// Get yearly expenses
  Future<List<Expense>> getYearlyExpenses(int carId, int year) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);
    return getExpensesInRange(carId, startDate, endDate);
  }

  /// Update an expense
  Future<bool> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) return false;
      await _dbHelper.updateExpense(expense.id!, expense.toMap());
      return true;
    } catch (e) {
      print('[Expense] Error updating expense: $e');
      return false;
    }
  }

  /// Delete an expense
  Future<bool> deleteExpense(int id) async {
    try {
      await _dbHelper.deleteExpense(id);
      return true;
    } catch (e) {
      print('[Expense] Error deleting expense: $e');
      return false;
    }
  }

  /// Get total expenses for a car
  Future<double> getTotalExpenses(int carId) async {
    try {
      return await _dbHelper.getTotalExpenses(carId);
    } catch (e) {
      print('[Expense] Error getting total expenses: $e');
      return 0.0;
    }
  }

  /// Get category breakdown
  Future<Map<String, double>> getCategoryBreakdown(int carId) async {
    try {
      final expenses = await getExpensesByCar(carId);
      final breakdown = <String, double>{};

      for (var expense in expenses) {
        breakdown[expense.category] = (breakdown[expense.category] ?? 0.0) + expense.amount;
      }

      return breakdown;
    } catch (e) {
      print('[Expense] Error getting category breakdown: $e');
      return {};
    }
  }

  /// Get monthly spending
  Future<Map<int, double>> getMonthlySpending(int carId, int year) async {
    try {
      final expenses = await getYearlyExpenses(carId, year);
      final monthlySpending = <int, double>{};

      for (var expense in expenses) {
        final month = expense.date.month;
        monthlySpending[month] = (monthlySpending[month] ?? 0.0) + expense.amount;
      }

      return monthlySpending;
    } catch (e) {
      print('[Expense] Error getting monthly spending: $e');
      return {};
    }
  }

  /// Calculate cost per kilometer
  Future<double> getCostPerKilometer(int carId, int totalMileage) async {
    try {
      if (totalMileage == 0) return 0.0;
      final totalExpenses = await getTotalExpenses(carId);
      return totalExpenses / totalMileage;
    } catch (e) {
      print('[Expense] Error calculating cost per km: $e');
      return 0.0;
    }
  }

  // ==================== FIREBASE METHODS ====================

  /// Backup all expenses to Firebase
  Future<bool> backupExpensesToFirebase() async {
    try {
      if (_userId == null) {
        print('[Expense] No user logged in');
        return false;
      }

      final localExpenses = await _dbHelper.getAllExpenses();
      
      if (localExpenses.isEmpty) {
        print('[Expense] No expenses to backup');
        return true;
      }

      // Get existing cloud expenses
      final cloudSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .get();

      final existingLocalIds = cloudSnapshot.docs
          .map((doc) => doc.data()['local_id'] as int?)
          .where((id) => id != null)
          .toSet();

      int uploadedCount = 0;
      int skippedCount = 0;

      for (var expenseMap in localExpenses) {
        final expense = Expense.fromMap(expenseMap);
        
        if (expense.id != null && existingLocalIds.contains(expense.id)) {
          skippedCount++;
          continue;
        }

        try {
          final docId = expense.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('expenses')
              .doc(docId)
              .set(expense.toFirestore());
          
          uploadedCount++;
        } catch (e) {
          print('[Expense] Error uploading expense ${expense.id}: $e');
        }
      }

      print('[Expense] Backup complete: $uploadedCount uploaded, $skippedCount skipped');
      return true;
    } catch (e) {
      print('[Expense] Backup error: $e');
      return false;
    }
  }

  /// Restore expenses from Firebase
  Future<bool> restoreExpensesFromFirebase() async {
    try {
      if (_userId == null) {
        print('[Expense] No user logged in');
        return false;
      }

      final cloudSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .get();

      if (cloudSnapshot.docs.isEmpty) {
        print('[Expense] No expenses to restore');
        return true;
      }

      final localExpenses = await _dbHelper.getAllExpenses();
      final existingLocalIds = localExpenses
          .map((e) => e['id'] as int?)
          .where((id) => id != null)
          .toSet();

      int restoredCount = 0;
      int skippedCount = 0;

      for (var doc in cloudSnapshot.docs) {
        try {
          final expense = Expense.fromFirestore(doc.data(), doc.id);
          
          if (expense.id != null && existingLocalIds.contains(expense.id)) {
            skippedCount++;
            continue;
          }

          // Check for duplicates by car_id, date, and amount
          final duplicateCheck = await _dbHelper.database.then((db) => 
            db.query(
              DatabaseHelper.tableExpenses,
              where: 'car_id = ? AND date = ? AND amount = ?',
              whereArgs: [expense.carId, expense.date.millisecondsSinceEpoch, expense.amount],
            )
          );

          if (duplicateCheck.isNotEmpty) {
            skippedCount++;
            continue;
          }

          final expenseMap = expense.toMap();
          expenseMap.remove('id');
          
          await _dbHelper.insertExpense(expenseMap);
          restoredCount++;
        } catch (e) {
          print('[Expense] Error restoring expense ${doc.id}: $e');
        }
      }

      print('[Expense] Restore complete: $restoredCount restored, $skippedCount skipped');
      return true;
    } catch (e) {
      print('[Expense] Restore error: $e');
      return false;
    }
  }

  /// Get Firebase expenses count
  Future<int> getFirebaseExpensesCount() async {
    try {
      if (_userId == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('[Expense] Error getting Firebase count: $e');
      return 0;
    }
  }
}

