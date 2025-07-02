import 'package:hive/hive.dart';
import 'package:notes_de_frais/models/expense_model.dart';

class StorageService {
  final Box<ExpenseModel> _expenseBox = Hive.box<ExpenseModel>('expenses');

  Future<void> saveExpense(ExpenseModel expense) async {
    await _expenseBox.add(expense);
  }

  Future<void> moveToTrash(int key) async {
    final expense = _expenseBox.get(key);
    if (expense != null) {
      expense.isInTrash = true;
      await expense.save();
    }
  }

  Future<void> restoreFromTrash(int key) async {
    final expense = _expenseBox.get(key);
    if (expense != null) {
      expense.isInTrash = false;
      await expense.save();
    }
  }

  Future<void> permanentlyDelete(int key) async {
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