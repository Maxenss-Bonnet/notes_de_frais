import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:notes_de_frais/controllers/expense_controller.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:notes_de_frais/views/validation_view.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/widgets/animated_stat_widget.dart';

class BatchResultView extends StatefulWidget {
  final List<ExpenseModel> expenses;
  const BatchResultView({super.key, required this.expenses});

  @override
  State<BatchResultView> createState() => _BatchResultViewState();
}

class _BatchResultViewState extends State<BatchResultView> {
  final ExpenseController _controller = ExpenseController();
  final StatisticsService _statsService = StatisticsService();
  late List<ExpenseModel> _expenses;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _expenses = widget.expenses;
  }

  Future<void> _onValidateAll() async {
    final validExpenses = _expenses.where((e) => e.associatedTo != null).toList();

    if (validExpenses.length != _expenses.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez associer toutes les notes à une entreprise avant de valider.')),
      );
      return;
    }

    final beforeVat = _statsService.getTotalVatSaved();
    final beforeWeeklyVat = _statsService.getVatSavedThisWeek();
    final beforeCount = _statsService.getExpensesThisWeekCount();

    await _controller.saveExpenseBatchLocally(validExpenses);
    _controller.performBackgroundTasksForBatch(validExpenses);

    final afterVat = _statsService.getTotalVatSaved();
    final afterWeeklyVat = _statsService.getVatSavedThisWeek();
    final afterCount = _statsService.getExpensesThisWeekCount();

    _showRewardOverlay(
        beforeVat: beforeVat, afterVat: afterVat,
        beforeWeeklyVat: beforeWeeklyVat, afterWeeklyVat: afterWeeklyVat,
        beforeCount: beforeCount, afterCount: afterCount
    );

    await Future.delayed(const Duration(seconds: 4));
    _hideRewardOverlay();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showRewardOverlay({
    required double beforeVat, required double afterVat,
    required double beforeWeeklyVat, required double afterWeeklyVat,
    required int beforeCount, required int afterCount
  }) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Notes de frais enregistrées !', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(child: AnimatedStatWidget(title: 'Notes (semaine)', beginValue: beforeCount.toDouble(), endValue: afterCount.toDouble(), icon: Icons.note_add_outlined, color: Colors.orange)),
                      Flexible(child: AnimatedStatWidget(title: 'TVA (semaine)', beginValue: beforeWeeklyVat, endValue: afterWeeklyVat, icon: Icons.calendar_today, color: Colors.purple, isCurrency: true)),
                      Flexible(child: AnimatedStatWidget(title: 'TVA (Total)', beginValue: beforeVat, endValue: afterVat, icon: Icons.shield_outlined, color: Colors.green, isCurrency: true)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideRewardOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final bool allAssociated = _expenses.every((e) => e.associatedTo != null);

    return Scaffold(
      appBar: AppBar(
        title: Text('Valider les notes (${_expenses.length})'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          final bool isDataComplete = expense.date != null && expense.amount != null && expense.company != null;
          final bool isAssociated = expense.associatedTo != null;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDataComplete ? Colors.white : Colors.orange.shade50,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: const Icon(Icons.receipt_long, size: 40),
              title: Text(expense.normalizedMerchantName ?? expense.company ?? 'Analyse incomplète', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${expense.category ?? "Non catégorisé"}\n${isAssociated ? "Associé à : ${expense.associatedTo}" : "Aucune société associée"}',
                  style: TextStyle(color: isAssociated ? Colors.green : Colors.red)),
              trailing: Text(
                expense.amount != null ? currencyFormat.format(expense.amount) : 'N/A',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDataComplete ? Colors.blue : Colors.red, fontSize: 16),
              ),
              isThreeLine: true,
              onTap: () async {
                final updatedExpense = await Navigator.of(context).push<ExpenseModel>(
                  MaterialPageRoute(
                    builder: (context) => ValidationView(expense: expense, isInBatchMode: true),
                  ),
                );
                if (updatedExpense != null) {
                  setState(() => _expenses[index] = updatedExpense);
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: _expenses.isNotEmpty ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          onPressed: allAssociated ? _onValidateAll : null,
          icon: const Icon(Icons.done_all),
          label: const Text('Tout valider et Envoyer'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18)
          ),
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}