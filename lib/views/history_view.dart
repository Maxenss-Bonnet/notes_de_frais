import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/storage_service.dart';
import 'package:notes_de_frais/views/trash_view.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final StorageService _storageService = StorageService();
  final List<ExpenseModel> _expenses = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 15;

  @override
  void initState() {
    super.initState();
    _loadMoreExpenses();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _loadMoreExpenses();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreExpenses() async {
    if (!_hasMore || _isLoading) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    final newExpenses = _storageService.getExpenses(page: _page, limit: _limit);

    if (newExpenses.length < _limit) {
      _hasMore = false;
    }

    if (mounted) {
      setState(() {
        _expenses.addAll(newExpenses);
        _page++;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des notes de frais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Corbeille',
            onPressed: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(builder: (context) => const TrashView()),
              )
                  .then((_) {
                if (mounted) {
                  setState(() {
                    _page = 1;
                    _expenses.clear();
                    _hasMore = true;
                    _loadMoreExpenses();
                  });
                }
              });
            },
          )
        ],
      ),
      body: _expenses.isEmpty && !_isLoading
          ? const Center(
        child: Text(
          'Aucune note de frais dans l\'historique.',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        controller: _scrollController,
        itemCount: _expenses.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _expenses.length) {
            return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ));
          }

          final expense = _expenses[index];
          return Dismissible(
            key: Key(expense.key.toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              final removedExpense = _expenses[index];

              if (mounted) {
                setState(() {
                  _expenses.removeAt(index);
                });
              }

              _storageService.moveToTrash(removedExpense.key);
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  expense.amount != null
                      ? currencyFormat.format(expense.amount)
                      : 'N/A',
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
      ),
    );
  }
}