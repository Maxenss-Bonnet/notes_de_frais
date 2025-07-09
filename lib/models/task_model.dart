import 'package:hive/hive.dart';

part 'task_model.g.dart';

enum TaskExecutionStatus {
  idle,
  processing,
  success,
  error,
}

class TaskStatus {
  final TaskExecutionStatus executionStatus;
  final String? message;
  final int totalTasks;
  final int completedTasks;
  final String? stepMessage;
  final int currentStep;
  final int totalSteps;

  TaskStatus({
    this.executionStatus = TaskExecutionStatus.idle,
    this.message,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.stepMessage,
    this.currentStep = 0,
    this.totalSteps = 0,
  });

  double get progress {
    if (totalTasks == 0) return 0.0;

    final double subProgress = totalSteps > 0 ? (currentStep / totalSteps) : 0.0;

    return (completedTasks + subProgress) / totalTasks;
  }
}


enum TaskType {
  sendSingleExpense,
  sendExpenseBatch,
}

@HiveType(typeId: 1)
class TaskModel extends HiveObject {
  @HiveField(0)
  final TaskType type;

  @HiveField(1)
  final dynamic payload;

  TaskModel({required this.type, required this.payload});
}