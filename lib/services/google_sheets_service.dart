import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';

class GoogleSheetsService {
  static const _scopes = [SheetsApi.spreadsheetsScope, drive.DriveApi.driveFileScope];

  Future<AuthClient> _getAuthClient() async {
    final credentialsJson = await rootBundle.loadString('assets/credentials.json');
    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    return await clientViaServiceAccount(credentials, _scopes);
  }

  Future<String?> _uploadFileToDrive(drive.DriveApi driveApi, String filePath) async {
    final file = File(filePath);
    try {
      final driveFile = drive.File()..name = 'justificatif_${DateTime.now().millisecondsSinceEpoch}.png';
      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      final fileId = result.id;
      if (fileId == null) return null;

      await driveApi.permissions.create(
        drive.Permission(role: 'reader', type: 'anyone'),
        fileId,
      );

      final fileData = await driveApi.files.get(fileId, $fields: 'webViewLink') as drive.File;
      return fileData.webViewLink;

    } catch (e) {
      print('Erreur lors du téléversement sur Google Drive : $e');
      return null;
    }
  }

  Future<void> appendExpense(ExpenseModel expense, String spreadsheetId) async {
    try {
      final client = await _getAuthClient();
      final sheetsApi = SheetsApi(client);
      final driveApi = drive.DriveApi(client);

      String? receiptLink;
      if (expense.processedImagePaths.isNotEmpty) {
        receiptLink = await _uploadFileToDrive(driveApi, expense.processedImagePaths.first);
      }

      final dateFormat = DateFormat('dd/MM/yyyy');
      final List<dynamic> row = [
        expense.date != null ? dateFormat.format(expense.date!) : 'N/A',
        expense.company ?? 'N/A',
        expense.associatedTo ?? 'N/A',
        expense.amount,
        expense.vat,
        receiptLink ?? 'Aucun justificatif',
      ];

      await sheetsApi.spreadsheets.values.append(
        ValueRange(values: [row]),
        spreadsheetId,
        'Dépenses!A1',
        valueInputOption: 'USER_ENTERED',
      );
      print('Note de frais ajoutée à Google Sheets avec lien vers le justificatif.');
    } catch (e) {
      print('Erreur lors de l\'ajout à Google Sheets: $e');
      rethrow;
    }
  }
}