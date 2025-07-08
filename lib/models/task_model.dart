// lib/models/task_model.dart

import 'package:hive/hive.dart';
import 'package:notes_de_frais/models/expense_model.dart';

part 'task_model.g.dart';

enum TaskType {
  sendSingleExpense,
  sendBatchExpense,
}

@HiveType(typeId: 1)
class TaskModel extends HiveObject {
  @HiveField(0)
  final TaskType type;

  @HiveField(1)
  final dynamic payload; // Could be ExpenseModel or List<ExpenseModel>

  TaskModel({required this.type, required this.payload});
}