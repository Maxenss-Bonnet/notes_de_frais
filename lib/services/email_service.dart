import 'dart:io';
import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/pdf_service.dart';
import 'package:path/path.dart' as p;

class EmailService {
  final PdfService _pdfService = PdfService();

  String _formatHtmlBody(ExpenseModel expense, String employeeName) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    final date = expense.date != null ? dateFormat.format(expense.date!) : 'N/A';
    final amount = expense.amount != null ? numberFormat.format(expense.amount) : 'N/A';
    final vat = expense.vat != null ? numberFormat.format(expense.vat) : 'N/A';
    final company = expense.company ?? 'N/A';
    final associatedTo = expense.associatedTo ?? 'N/A';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; color: #333; }
        .container { border: 1px solid #ddd; padding: 20px; border-radius: 8px; max-width: 600px; }
        h2 { color: #005a9c; border-bottom: 2px solid #005a9c; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f2f2f2; }
        .footer { margin-top: 30px; font-size: 0.8em; color: #777; text-align: center; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Nouvelle note de frais de ${employeeName}</h2>
        <p>Une nouvelle note de frais a été soumise pour l'entreprise <strong>$associatedTo</strong>.</p>
        <table>
          <tr>
            <th>Fournisseur</th>
            <td>$company</td>
          </tr>
          <tr>
            <th>Date</th>
            <td>$date</td>
          </tr>
          <tr>
            <th>Montant TTC</th>
            <td><strong>$amount</strong></td>
          </tr>
          <tr>
            <th>Montant TVA</th>
            <td>$vat</td>
          </tr>
        </table>
        <p class="footer">E-mail généré automatiquement par l'application Notes de Frais.</p>
      </div>
    </body>
    </html>
    ''';
  }

  String _sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _formatBatchHtmlBody(List<ExpenseModel> expenses, String employeeName) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final totalAmount = expenses.map((e) => e.amount ?? 0).fold(0.0, (a, b) => a + b);
    final totalVat = expenses.map((e) => e.vat ?? 0).fold(0.0, (a, b) => a + b);

    final expenseRows = expenses.map((expense) {
      final date = expense.date != null ? dateFormat.format(expense.date!) : 'N/A';
      final amount = expense.amount != null ? numberFormat.format(expense.amount) : 'N/A';
      final vat = expense.vat != null ? numberFormat.format(expense.vat) : 'N/A';
      final company = expense.company ?? 'N/A';
      final category = expense.category ?? 'N/A';
      final associatedTo = expense.associatedTo ?? 'N/A';
      final type = expense.category == 'Frais Kilométriques' ? 'Indemnité Kilométrique' : 'Note de Frais';

      return '''
        <tr>
          <td>$date</td>
          <td>$type</td>
          <td>$company</td>
          <td>$category</td>
          <td>$associatedTo</td>
          <td>$amount</td>
          <td>$vat</td>
        </tr>
      ''';
    }).join('');

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; color: #333; }
        .container { border: 1px solid #ddd; padding: 20px; border-radius: 8px; max-width: 800px; margin: auto; }
        h2 { color: #005a9c; border-bottom: 2px solid #005a9c; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 14px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f2f2f2; }
        .summary { margin-top: 20px; padding-top: 10px; border-top: 2px solid #333; text-align: right; font-weight: bold;}
        .footer { margin-top: 30px; font-size: 0.8em; color: #777; text-align: center; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Rapport de notes de frais - ${employeeName}</h2>
        <p>Voici un résumé des notes de frais soumises par <strong>${employeeName}</strong>. Le récapitulatif PDF complet est en pièce jointe.</p>
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Type</th>
              <th>Fournisseur / Motif</th>
              <th>Catégorie</th>
              <th>Associé à</th>
              <th>Montant TTC</th>
              <th>Montant TVA</th>
            </tr>
          </thead>
          <tbody>
            $expenseRows
          </tbody>
        </table>
        <div class="summary">
          <p>Total TTC: ${numberFormat.format(totalAmount)}</p>
          <p>Total TVA: ${numberFormat.format(totalVat)}</p>
        </div>
        <p class="footer">E-mail généré automatiquement par l'application Notes de Frais.</p>
      </div>
    </body>
    </html>
    ''';
  }

  Future<List<Attachment>> _getAttachmentsForBatch(List<ExpenseModel> expenses, String employeeName) async {
    final List<Attachment> attachments = [];
    int fileCounter = 1;

    final Uint8List pdfData = await _pdfService.generateExpenseReportPdf(expenses);
    attachments.add(StreamAttachment(Stream.value(pdfData), 'application/pdf', fileName: 'Rapport_de_Frais_${employeeName.replaceAll(' ', '_')}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf'));

    for (final expense in expenses) {
      if(expense.processedImagePaths.isEmpty) continue;

      final companyName = _sanitizeFileName(expense.company ?? 'Inconnu');
      final dateString = expense.date != null ? DateFormat('yyyy-MM-dd').format(expense.date!) : 'Date_Inconnue';

      for (final path in expense.processedImagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final extension = p.extension(path);
          final newFileName = '${dateString}_${companyName}_${fileCounter++}$extension';
          attachments.add(FileAttachment(file, fileName: newFileName));
        }
      }
    }
    return attachments;
  }

  Future<void> sendExpenseBatchEmail({
    required List<ExpenseModel> expenses,
    required String recipient,
    required String sender,
    required String password,
    required String employeeName,
    String? ccRecipient,
  }) async {
    if (expenses.isEmpty) return;
    final smtpServer = gmail(sender, password);
    final subject = 'Rapport de notes de frais - $employeeName - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}';

    final message = Message()
      ..from = Address(sender, 'Notes de Frais App ($employeeName)')
      ..recipients.add(recipient)
      ..subject = subject
      ..html = _formatBatchHtmlBody(expenses, employeeName)
      ..attachments = await _getAttachmentsForBatch(expenses, employeeName);

    if (ccRecipient != null && ccRecipient.isNotEmpty) {
      message.ccRecipients.add(Address(ccRecipient));
    }

    try {
      final sendReport = await send(message, smtpServer);
      print('Email de lot envoyé: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('L\'email de lot n\'a pas pu être envoyé.');
      for (var p in e.problems) {
        print('Problème: ${p.code}: ${p.msg}');
      }
      rethrow;
    }
  }
}