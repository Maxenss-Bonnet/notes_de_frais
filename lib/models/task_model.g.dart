// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 1;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Gestion de la compatibilité ascendante
    // Les anciennes tâches n'ont que 2 champs (type et payload)
    // Les nouvelles tâches ont 3 champs (type, payload, sendStatus)
    final type = fields[0];
    final payload = fields[1];
    final sendStatus = numOfFields > 2 ? fields[2] : null;

    // Vérification de type pour éviter les erreurs de casting
    if (type is TaskType) {
      return TaskModel(
        type: type,
        payload: payload,
        sendStatus: sendStatus as SendStatus?,
      );
    } else {
      // Fallback pour les données corrompues ou incompatibles
      print(
          "Warning: TaskModel data corruption detected, using default values");
      return TaskModel(
        type: TaskType.sendSingleExpense,
        payload: payload,
        sendStatus: SendStatus.pending,
      );
    }
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.payload)
      ..writeByte(2)
      ..write(obj.sendStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SendStatusAdapter extends TypeAdapter<SendStatus> {
  @override
  final int typeId = 2;

  @override
  SendStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SendStatus.pending;
      case 1:
        return SendStatus.emailSent;
      case 2:
        return SendStatus.sheetUpdated;
      case 3:
        return SendStatus.filesDeleted;
      case 4:
        return SendStatus.completed;
      default:
        return SendStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SendStatus obj) {
    switch (obj) {
      case SendStatus.pending:
        writer.writeByte(0);
        break;
      case SendStatus.emailSent:
        writer.writeByte(1);
        break;
      case SendStatus.sheetUpdated:
        writer.writeByte(2);
        break;
      case SendStatus.filesDeleted:
        writer.writeByte(3);
        break;
      case SendStatus.completed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 3;

  @override
  TaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskType.sendSingleExpense;
      case 1:
        return TaskType.sendExpenseBatch;
      default:
        return TaskType.sendSingleExpense;
    }
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    switch (obj) {
      case TaskType.sendSingleExpense:
        writer.writeByte(0);
        break;
      case TaskType.sendExpenseBatch:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
