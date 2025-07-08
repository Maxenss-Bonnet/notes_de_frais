import 'package:hive/hive.dart';
import 'package:notes_de_frais/models/task_model.dart';

class TaskQueueService {
  final Box<TaskModel> _taskBox = Hive.box<TaskModel>('tasks');

  Future<void> enqueueTask(TaskModel task) async {
    await _taskBox.add(task);
  }

  TaskModel? getNextTask() {
    if (_taskBox.isNotEmpty) {
      return _taskBox.getAt(0);
    }
    return null;
  }

  Future<void> completeTask(dynamic key) async {
    await _taskBox.delete(key);
  }

  Box<TaskModel> getTaskBox() {
    return _taskBox;
  }
}