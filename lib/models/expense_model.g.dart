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
      amountConfidence: fields[10] as double?,
      dateConfidence: fields[11] as double?,
      companyConfidence: fields[12] as double?,
      vatConfidence: fields[13] as double?,
      categoryConfidence: fields[14] as double?,
      normalizedMerchantNameConfidence: fields[15] as double?,
      creditCard: fields[16] as String?,
      // La correction est ici. On vérifie si la valeur est null et on met 'false' par défaut.
      isSent: fields[17] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..writeByte(18)
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
      ..write(obj.normalizedMerchantName)
      ..writeByte(10)
      ..write(obj.amountConfidence)
      ..writeByte(11)
      ..write(obj.dateConfidence)
      ..writeByte(12)
      ..write(obj.companyConfidence)
      ..writeByte(13)
      ..write(obj.vatConfidence)
      ..writeByte(14)
      ..write(obj.categoryConfidence)
      ..writeByte(15)
      ..write(obj.normalizedMerchantNameConfidence)
      ..writeByte(16)
      ..write(obj.creditCard)
      ..writeByte(17)
      ..write(obj.isSent);
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