import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';

class GoogleSheetsService {
  static const _scopes = [SheetsApi.spreadsheetsScope];

  Future<AuthClient> _getAuthClient() async {
    final credentialsJson = await rootBundle.loadString('assets/credentials.json');
    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    return await clientViaServiceAccount(credentials, _scopes);
  }

  Future<void> appendExpense(ExpenseModel expense, String spreadsheetId) async {
    try {
      final client = await _getAuthClient();
      final sheetsApi = SheetsApi(client);

      final dateFormat = DateFormat('dd/MM/yyyy');
      final List<dynamic> row = [
        expense.date != null ? dateFormat.format(expense.date!) : 'N/A',
        expense.company ?? 'N/A',
        expense.associatedTo ?? 'N/A',
        expense.amount,
        expense.vat,
        expense.creditCard ?? 'N/A',
      ];

      await sheetsApi.spreadsheets.values.append(
        ValueRange(values: [row]),
        spreadsheetId,
        'Dépenses!A1',
        valueInputOption: 'USER_ENTERED',
      );
      print('Note de frais ajoutée à Google Sheets.');
    } catch (e) {
      print('Erreur lors de l\'ajout à Google Sheets: $e');
      rethrow;
    }
  }

  Future<void> appendExpenseBatch(List<ExpenseModel> expenses, String spreadsheetId) async {
    if (expenses.isEmpty) return;
    try {
      final client = await _getAuthClient();
      final sheetsApi = SheetsApi(client);

      final List<List<dynamic>> rows = [];
      final dateFormat = DateFormat('dd/MM/yyyy');

      for (final expense in expenses) {
        rows.add([
          expense.date != null ? dateFormat.format(expense.date!) : 'N/A',
          expense.company ?? 'N/A',
          expense.associatedTo ?? 'N/A',
          expense.amount,
          expense.vat,
          expense.creditCard ?? 'N/A',
        ]);
      }

      await sheetsApi.spreadsheets.values.append(
        ValueRange(values: rows),
        spreadsheetId,
        'Dépenses!A1',
        valueInputOption: 'USER_ENTERED',
      );
      print('${expenses.length} notes de frais ajoutées à Google Sheets en un lot.');
    } catch (e) {
      print('Erreur lors de l\'ajout du lot à Google Sheets: $e');
      rethrow;
    }
  }
}