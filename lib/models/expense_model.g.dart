// lib/models/expense_model.g.dart

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 0;

  @override
  ExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseModel(
      imagePath: fields[0] as String,
      processedImagePaths: (fields[1] as List).cast<String>(),
      date: fields[2] as DateTime?,
      amount: fields[3] as double?,
      vat: fields[4] as double?,
      company: fields[5] as String?,
      associatedTo: fields[6] as String?,
      isInTrash: fields[7] as bool,
      category: fields[8] as String?,
      normalizedMerchantName: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.processedImagePaths)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.vat)
      ..writeByte(5)
      ..write(obj.company)
      ..writeByte(6)
      ..write(obj.associatedTo)
      ..writeByte(7)
      ..write(obj.isInTrash)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.normalizedMerchantName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ExpenseModelAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}