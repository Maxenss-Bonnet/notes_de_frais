import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';

class GoogleSheetsService {
  static const _scopes = [SheetsApi.spreadsheetsScope];

  Future<SheetsApi> _getSheetsApi() async {
    final credentialsJson = await rootBundle.loadString('assets/credentials.json');
    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    final client = await clientViaServiceAccount(credentials, _scopes);
    return SheetsApi(client);
  }

  Future<void> appendExpense(ExpenseModel expense, String spreadsheetId) async {
    try {
      final sheetsApi = await _getSheetsApi();
      final dateFormat = DateFormat('dd/MM/yyyy');

      final List<dynamic> row = [
        expense.date != null ? dateFormat.format(expense.date!) : 'N/A',
        expense.company ?? 'N/A',
        expense.associatedTo ?? 'N/A',
        expense.amount,
        expense.vat,
      ];

      await sheetsApi.spreadsheets.values.append(
        ValueRange(values: [row]),
        spreadsheetId,
        'Feuille 1!A1', // Assurez-vous que le nom de la feuille est correct
        valueInputOption: 'USER_ENTERED',
      );
      print('Note de frais ajoutée à Google Sheets.');
    } catch (e) {
      print('Erreur lors de l\'ajout à Google Sheets: $e');
      rethrow;
    }
  }
}