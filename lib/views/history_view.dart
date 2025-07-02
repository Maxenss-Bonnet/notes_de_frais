import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/storage_service.dart';
import 'package:notes_de_frais/views/trash_view.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();
    final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des notes de frais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Corbeille',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TrashView()),
              );
            },
          )
        ],
      ),
      body: ValueListenableBuilder<Box<ExpenseModel>>(
        valueListenable: storageService.getExpenseBox().listenable(),
        builder: (context, box, _) {
          final expenses = box.values.where((e) => !e.isInTrash).toList().reversed.toList();

          if (expenses.isEmpty) {
            return const Center(
              child: Text(
                'Aucune note de frais dans l\'historique.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Dismissible(
                key: Key(expense.key.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  storageService.moveToTrash(expense.key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note de frais déplacée dans la corbeille')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: FileImage(File(expense.imagePath)),
                    ),
                    title: Text(
                      expense.company ?? 'Fournisseur inconnu',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Associé à : ${expense.associatedTo ?? 'N/A'}\n${expense.date != null ? dateFormat.format(expense.date!) : 'Date inconnue'}',
                    ),
                    trailing: Text(
                      expense.amount != null ? currencyFormat.format(expense.amount) : 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}