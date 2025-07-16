import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  final SettingsService _settingsService = SettingsService();

  Future<Uint8List> generateExpenseReportPdf(List<ExpenseModel> expenses) async {
    final pdf = pw.Document();

    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final italicFont = await rootBundle.load("assets/fonts/Roboto-Italic.ttf");
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(font),
      bold: pw.Font.ttf(boldFont),
      italic: pw.Font.ttf(italicFont),
    );

    final employeeInfo = await _settingsService.getEmployeeInfo();
    final recipientInfo = await _settingsService.getRecipientInfo();

    final logo = pw.MemoryImage((await rootBundle.load('assets/logo.png')).buffer.asUint8List());

    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    final dateFrom = expenses.map((e) => e.date).whereType<DateTime>().reduce((a, b) => a.isBefore(b) ? a : b);
    final dateTo = expenses.map((e) => e.date).whereType<DateTime>().reduce((a, b) => a.isAfter(b) ? a : b);

    final double totalKm = expenses.map((e) => e.distance ?? 0).fold(0.0, (a, b) => a + b);
    final double totalHt = expenses.map((e) => (e.amount ?? 0) - (e.vat ?? 0)).fold(0.0, (a, b) => a + b);
    final double totalVat = expenses.map((e) => e.vat ?? 0).fold(0.0, (a, b) => a + b);
    final double totalTtc = expenses.map((e) => e.amount ?? 0).fold(0.0, (a, b) => a + b);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logo, employeeInfo['employer'] ?? 'N/A'),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildReportInfo(dateFormat, dateFrom, dateTo, employeeInfo, recipientInfo),
          pw.SizedBox(height: 25),
          _buildExpensesTable(expenses, dateFormat, currencyFormat),
          pw.SizedBox(height: 10),
          _buildTotals(currencyFormat, totalKm, totalHt, totalVat, totalTtc),
          pw.SizedBox(height: 40),
          _buildObservationsSection(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.ImageProvider logo, String employer) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 1.5)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.SizedBox(height: 50, width: 50, child: pw.Image(logo)),
          pw.Text('Note de Frais - $employer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} sur ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildReportInfo(DateFormat dateFormat, DateTime dateFrom, DateTime dateTo, Map<String, String> employeeInfo, Map<String, String> recipientInfo) {
    return pw.Column(children: [
      pw.Text('Frais du ${dateFormat.format(dateFrom)} au ${dateFormat.format(dateTo)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      pw.SizedBox(height: 20),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Flexible(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoLine('Nom :', '${employeeInfo['lastName']} ${employeeInfo['firstName']}'),
                _buildInfoLine('Employeur :', employeeInfo['employer']),
                _buildInfoLine('Mail du salarié :', employeeInfo['email']),
                _buildInfoLine('Puissance fiscale :', employeeInfo['fiscalHorsepower']),
              ],
            ),
          ),
          pw.SizedBox(width: 40),
          pw.Flexible(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Validé et envoyé par le salarié le : ${dateFormat.format(DateTime.now())}'),
                pw.SizedBox(height: 10),
                pw.Text('Coordonnées du responsable :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                _buildInfoLine('Nom :', '${recipientInfo['lastName']} ${recipientInfo['firstName']}'),
                _buildInfoLine('Mail :', recipientInfo['email']),
              ],
            ),
          ),
        ],
      )
    ]);
  }

  pw.Widget _buildInfoLine(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 5),
          pw.Text(value ?? 'N/A'),
        ],
      ),
    );
  }

  pw.Widget _buildExpensesTable(List<ExpenseModel> expenses, DateFormat dateFormat, NumberFormat currencyFormat) {
    const tableHeaders = ['Date', 'Objet - Motif', 'Catégorie', 'Société Imputation', 'Distance\n(KM)', 'Montant\nHT', 'TVA', 'TTC'];
    final cellTextStyle = const pw.TextStyle(fontSize: 9);

    return pw.Table.fromTextArray(
      headers: tableHeaders,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      cellAlignment: pw.Alignment.center,
      cellAlignments: {
        1: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
        7: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(2.8),
        2: const pw.FlexColumnWidth(1.6),
        3: const pw.FlexColumnWidth(1.6),
        4: const pw.FlexColumnWidth(1.0),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.1),
        7: const pw.FlexColumnWidth(1.2),
      },
      data: expenses.map((e) {
        final motif = e.category == 'Frais Kilométriques' ? e.company : e.normalizedMerchantName;
        final distance = e.category == 'Frais Kilométriques' ? e.distance?.toStringAsFixed(1) ?? '-' : '-';

        return [
          pw.Text(e.date != null ? dateFormat.format(e.date!) : 'N/A', style: cellTextStyle),
          pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(motif ?? 'N/A', style: cellTextStyle),
                if (e.comment != null && e.comment!.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text("Libellé: ${e.comment!}", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700, fontSize: 8)),
                  )
              ]
          ),
          pw.Text(e.category ?? 'N/A', style: cellTextStyle),
          pw.Text(e.associatedTo ?? 'N/A', style: cellTextStyle),
          pw.Text(distance, style: cellTextStyle),
          pw.Text(currencyFormat.format((e.amount ?? 0) - (e.vat ?? 0)), style: cellTextStyle),
          pw.Text(currencyFormat.format(e.vat ?? 0), style: cellTextStyle),
          pw.Text(currencyFormat.format(e.amount ?? 0), style: cellTextStyle),
        ];
      }).toList(),
    );
  }

  pw.Widget _buildTotals(NumberFormat currencyFormat, double totalKm, double totalHt, double totalVat, double totalTtc) {
    final cellTextStyle = const pw.TextStyle(fontSize: 9);
    final boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
    final totalLabelStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11);

    final columnWidths = {
      0: const pw.FlexColumnWidth(1.4),
      1: const pw.FlexColumnWidth(2.8),
      2: const pw.FlexColumnWidth(1.6),
      3: const pw.FlexColumnWidth(1.6),
      4: const pw.FlexColumnWidth(1.0),
      5: const pw.FlexColumnWidth(1.2),
      6: const pw.FlexColumnWidth(1.1),
      7: const pw.FlexColumnWidth(1.2),
    };

    return pw.Column(
        children: [
          pw.Divider(),
          pw.Table(
              columnWidths: columnWidths,
              children: [
                pw.TableRow(
                    children: [
                      pw.Container(), // Vide: Date
                      pw.Container(), // Vide: Objet
                      pw.Container(), // Vide: Catégorie
                      pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 5),
                          child: pw.Text('Sous-totaux :', style: boldStyle, textAlign: pw.TextAlign.right)
                      ),
                      pw.Text(totalKm > 0 ? totalKm.toStringAsFixed(1) : '-', style: cellTextStyle, textAlign: pw.TextAlign.right),
                      pw.Text(currencyFormat.format(totalHt), style: cellTextStyle, textAlign: pw.TextAlign.right),
                      pw.Text(currencyFormat.format(totalVat), style: cellTextStyle, textAlign: pw.TextAlign.right),
                      pw.Text(currencyFormat.format(totalTtc), style: boldStyle, textAlign: pw.TextAlign.right),
                    ]
                )
              ]
          ),
          pw.SizedBox(height: 20),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(5)),
                    child: pw.Row(
                        children: [
                          pw.Text('Total de la demande :', style: totalLabelStyle),
                          pw.SizedBox(width: 25),
                          pw.Text(currencyFormat.format(totalTtc), style: totalLabelStyle),
                        ]
                    )
                )
              ]
          )
        ]
    );
  }

  pw.Widget _buildObservationsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Observations :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Container(
          height: 80,
          width: double.infinity,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey), borderRadius: pw.BorderRadius.circular(5)),
        ),
      ],
    );
  }
}