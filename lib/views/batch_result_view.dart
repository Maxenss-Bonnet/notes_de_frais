import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/controllers/expense_controller.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/views/validation_view.dart';

class BatchResultView extends StatefulWidget {
  final List<ExpenseModel> expenses;
  const BatchResultView({super.key, required this.expenses});

  @override
  State<BatchResultView> createState() => _BatchResultViewState();
}

class _BatchResultViewState extends State<BatchResultView> {
  final ExpenseController _controller = ExpenseController();
  late List<ExpenseModel> _expenses;

  @override
  void initState() {
    super.initState();
    _expenses = widget.expenses;
  }

  Future<void> _onSaveAll() async {
    final bool allAssociated = _expenses.every((e) => e.associatedTo != null);

    if (!allAssociated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez associer chaque note à une entreprise.')),
      );
      return;
    }

    await _controller.saveExpenseBatchLocally(_expenses);

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_expenses.length} notes de frais ont été enregistrées dans l\'historique.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final bool allValidated = _expenses.every((e) => e.associatedTo != null);

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
          final bool hasComment = expense.comment != null && expense.comment!.isNotEmpty;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDataComplete ? Colors.white : Colors.orange.shade50,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: const Icon(Icons.receipt_long, size: 40),
              title: Text(expense.normalizedMerchantName ?? expense.company ?? 'Analyse incomplète', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.category ?? "Non catégorisé"),
                  Text(
                    isAssociated ? "Associé à : ${expense.associatedTo}" : "Aucune société associée",
                    style: TextStyle(color: isAssociated ? Colors.green : Colors.red, fontSize: 12),
                  ),
                  if (hasComment)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Libellé : ${expense.comment}',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              trailing: Text(
                expense.amount != null ? currencyFormat.format(expense.amount) : 'N/A',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDataComplete ? Colors.blue : Colors.red, fontSize: 16),
              ),
              isThreeLine: hasComment,
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
          onPressed: allValidated ? _onSaveAll : null,
          icon: const Icon(Icons.done_all),
          label: const Text('Tout sauvegarder'),
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