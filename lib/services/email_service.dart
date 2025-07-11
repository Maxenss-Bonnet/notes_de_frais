import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:path/path.dart' as p;

class EmailService {

  String _formatHtmlBody(ExpenseModel expense) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    final date = expense.date != null ? dateFormat.format(expense.date!) : 'N/A';
    final amount = expense.amount != null ? numberFormat.format(expense.amount) : 'N/A';
    final vat = expense.vat != null ? numberFormat.format(expense.vat) : 'N/A';
    final company = expense.company ?? 'N/A';
    final associatedTo = expense.associatedTo ?? 'N/A';
    final creditCard = expense.creditCard ?? 'N/A';

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
        <h2>Nouvelle note de frais</h2>
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
          <tr>
            <th>Payé avec</th>
            <td>$creditCard</td>
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

  Future<void> sendExpenseEmail({
    required ExpenseModel expense,
    required String recipient,
    required String sender,
    required String password,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final date = expense.date != null ? dateFormat.format(expense.date!) : 'Ticket';
    final subject = 'Note de frais - ${expense.company ?? 'N/A'} - $date';
    final body = _formatHtmlBody(expense);
    final smtpServer = gmail(sender, password);

    final List<Attachment> attachments = [];
    final companyName = _sanitizeFileName(expense.company ?? 'Inconnu');
    final dateString = expense.date != null ? DateFormat('yyyy-MM-dd').format(expense.date!) : 'Date_Inconnue';
    int i = 1;
    for (final path in expense.processedImagePaths) {
      final file = File(path);
      final extension = p.extension(path);
      final newFileName = '${dateString}_${companyName}_${i++}$extension';
      attachments.add(FileAttachment(file, fileName: newFileName));
    }

    final message = Message()
      ..from = Address(sender, 'Notes de Frais App')
      ..recipients.add(recipient)
      ..subject = subject
      ..html = body
      ..attachments = attachments;

    try {
      final sendReport = await send(message, smtpServer);
      print('Message envoyé: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Le message n\'a pas pu être envoyé.');
      for (var p in e.problems) {
        print('Problème: ${p.code}: ${p.msg}');
      }
      rethrow;
    }
  }

  String _formatBatchHtmlBody(List<ExpenseModel> expenses) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final totalAmount = expenses.map((e) => e.amount ?? 0).fold(0.0, (a, b) => a + b);
    final totalVat = expenses.map((e) => e.vat ?? 0).fold(0.0, (a, b) => a + b);

    final expenseRows = expenses.map((expense) {
      final date = expense.date != null ? dateFormat.format(expense.date!) : 'N/A';
      final amount = expense.amount != null ? numberFormat.format(expense.amount) : 'N/A';
      final vat = expense.vat != null ? numberFormat.format(expense.vat) : 'N/A';
      final company = expense.company ?? 'N/A';
      final associatedTo = expense.associatedTo ?? 'N/A';
      final creditCard = expense.creditCard ?? 'N/A';
      return '''
        <tr>
          <td>$date</td>
          <td>$company</td>
          <td>$associatedTo</td>
          <td>$amount</td>
          <td>$vat</td>
          <td>$creditCard</td>
        </tr>
      ''';
    }).join('');

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
        .summary { margin-top: 20px; padding-top: 10px; border-top: 2px solid #333; text-align: right; font-weight: bold;}
        .footer { margin-top: 30px; font-size: 0.8em; color: #777; text-align: center; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Rapport de notes de frais combiné</h2>
        <p>Voici un résumé des dernières notes de frais soumises.</p>
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Fournisseur</th>
              <th>Associé à</th>
              <th>Montant TTC</th>
              <th>Montant TVA</th>
              <th>Payé avec</th>
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

  Future<List<Attachment>> _getAttachmentsForBatch(List<ExpenseModel> expenses) async {
    final List<Attachment> attachments = [];
    int fileCounter = 1;
    for (final expense in expenses) {
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
  }) async {
    if (expenses.isEmpty) return;
    final smtpServer = gmail(sender, password);
    final subject = 'Rapport de notes de frais combiné - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}';

    final message = Message()
      ..from = Address(sender, 'Notes de Frais App')
      ..recipients.add(recipient)
      ..subject = subject
      ..html = _formatBatchHtmlBody(expenses)
      ..attachments = await _getAttachmentsForBatch(expenses);

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