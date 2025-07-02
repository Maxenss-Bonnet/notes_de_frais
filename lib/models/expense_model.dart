import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  String imagePath;

  @HiveField(1)
  List<String> processedImagePaths;

  @HiveField(2)
  DateTime? date;

  @HiveField(3)
  double? amount;

  @HiveField(4)
  double? vat;

  @HiveField(5)
  String? company;

  @HiveField(6)
  String? associatedTo;

  @HiveField(7)
  bool isInTrash;

  ExpenseModel({
    required this.imagePath,
    this.processedImagePaths = const [],
    this.date,
    this.amount,
    this.vat,
    this.company,
    this.associatedTo,
    this.isInTrash = false,
  });
}