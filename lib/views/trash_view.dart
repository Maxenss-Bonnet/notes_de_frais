import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/storage_service.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corbeille'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Vider la corbeille',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext ctx) => AlertDialog(
                  title: const Text('Vider la corbeille'),
                  content: const Text('Voulez-vous vraiment supprimer définitivement toutes les notes de la corbeille ?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        storageService.emptyTrash();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Vider', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<ExpenseModel>>(
        valueListenable: storageService.getExpenseBox().listenable(),
        builder: (context, box, _) {
          final trashedExpenses = box.values.where((e) => e.isInTrash).toList().reversed.toList();

          if (trashedExpenses.isEmpty) {
            return const Center(child: Text('La corbeille est vide.'));
          }

          return ListView.builder(
            itemCount: trashedExpenses.length,
            itemBuilder: (context, index) {
              final expense = trashedExpenses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(expense.company ?? 'Note de frais'),
                  subtitle: Text('Supprimée'),
                  trailing: IconButton(
                    icon: const Icon(Icons.restore_from_trash),
                    tooltip: 'Restaurer',
                    onPressed: () {
                      storageService.restoreFromTrash(expense.key);
                    },
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