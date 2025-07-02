import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';

class EmailService {

  String _formatHtmlBody(ExpenseModel expense) {
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
        </table>
        <p class="footer">E-mail généré automatiquement par l'application Notes de Frais.</p>
      </div>
    </body>
    </html>
    ''';
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

    final message = Message()
      ..from = Address(sender, 'Notes de Frais App')
      ..recipients.add(recipient)
      ..subject = subject
      ..html = body
      ..attachments = [
        for (final path in expense.processedImagePaths)
          FileAttachment(File(path)),
      ];

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
}