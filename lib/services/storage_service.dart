import 'package:hive/hive.dart';
import 'package:notes_de_frais/models/expense_model.dart';

class StorageService {
  final Box<ExpenseModel> _expenseBox = Hive.box<ExpenseModel>('expenses');

  Future<void> saveExpense(ExpenseModel expense) async {
    await _expenseBox.add(expense);
  }

  List<ExpenseModel> getExpenses({int page = 1, int limit = 15}) {
    final allExpenses = _expenseBox.values.where((e) => !e.isInTrash).toList().reversed.toList();
    final startIndex = (page - 1) * limit;

    if (startIndex >= allExpenses.length) {
      return [];
    }

    final endIndex = (startIndex + limit > allExpenses.length) ? allExpenses.length : startIndex + limit;

    return allExpenses.sublist(startIndex, endIndex);
  }

  int get totalExpensesCount => _expenseBox.values.where((e) => !e.isInTrash).length;

  int getUnsentExpensesCount() {
    return _expenseBox.values.where((e) => !e.isInTrash && !e.isSent).length;
  }

  Future<void> moveToTrash(dynamic key) async {
    final expense = _expenseBox.get(key);
    if (expense != null) {
      expense.isInTrash = true;
      await expense.save();
    }
  }

  Future<void> restoreFromTrash(dynamic key) async {
    final expense = _expenseBox.get(key);
    if (expense != null) {
      expense.isInTrash = false;
      await expense.save();
    }
  }

  Future<void> permanentlyDelete(dynamic key) async {
    await _expenseBox.delete(key);
  }

  Future<void> emptyTrash() async {
    final keysToDelete = _expenseBox.keys.where((key) {
      final expense = _expenseBox.get(key);
      return expense != null && expense.isInTrash;
    }).toList();

    await _expenseBox.deleteAll(keysToDelete);
  }

  Box<ExpenseModel> getExpenseBox() {
    return _expenseBox;
  }
}