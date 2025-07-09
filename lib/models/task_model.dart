import 'package:hive/hive.dart';

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
  final dynamic payload;

  TaskModel({required this.type, required this.payload});
}