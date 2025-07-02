class ExpenseModel {
  String imagePath;
  DateTime? date;
  double? amount;
  double? vat;
  String? company;
  String? associatedTo;

  ExpenseModel({
    required this.imagePath,
    this.date,
    this.amount,
    this.vat,
    this.company,
    this.associatedTo,
  });
}