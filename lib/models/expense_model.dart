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

  @HiveField(8)
  String? category;

  @HiveField(9)
  String? normalizedMerchantName;

  @HiveField(10)
  double? amountConfidence;

  @HiveField(11)
  double? dateConfidence;

  @HiveField(12)
  double? companyConfidence;

  @HiveField(13)
  double? vatConfidence;

  @HiveField(14)
  double? categoryConfidence;

  @HiveField(15)
  double? normalizedMerchantNameConfidence;

  @HiveField(16)
  String? creditCard;

  @HiveField(17)
  bool isSent;

  @HiveField(18)
  String? comment;

  @HiveField(19)
  double? distance;

  ExpenseModel({
    required this.imagePath,
    this.processedImagePaths = const [],
    this.date,
    this.amount,
    this.vat,
    this.company,
    this.associatedTo,
    this.isInTrash = false,
    this.category,
    this.normalizedMerchantName,
    this.amountConfidence,
    this.dateConfidence,
    this.companyConfidence,
    this.vatConfidence,
    this.categoryConfidence,
    this.normalizedMerchantNameConfidence,
    this.creditCard,
    this.isSent = false,
    this.comment,
    this.distance,
  });
}