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

  /// Nettoie les tâches corrompues ou incompatibles
  Future<void> cleanupCorruptedTasks() async {
    final keysToRemove = <dynamic>[];
    
    for (final key in _taskBox.keys) {
      try {
        final task = _taskBox.get(key);
        if (task == null) {
          keysToRemove.add(key);
          continue;
        }
        
        // Vérifier que la tâche a des données valides
        if (task.payload == null) {
          print("Removing corrupted task with null payload: $key");
          keysToRemove.add(key);
        }
      } catch (e) {
        print("Removing corrupted task due to error: $key, error: $e");
        keysToRemove.add(key);
      }
    }
    
    if (keysToRemove.isNotEmpty) {
      await _taskBox.deleteAll(keysToRemove);
      print("Cleaned up ${keysToRemove.length} corrupted tasks");
    }
  }
}