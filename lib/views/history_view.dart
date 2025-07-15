import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/providers/providers.dart';
import 'package:notes_de_frais/services/storage_service.dart';
import 'package:notes_de_frais/services/task_queue_service.dart';
import 'package:notes_de_frais/views/trash_view.dart';
import 'package:notes_de_frais/views/validation_view.dart';

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({super.key});

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  final StorageService _storageService = StorageService();
  final TaskQueueService _taskQueueService = TaskQueueService();
  final Set<int> _selectedKeys = <int>{};

  // Le reste de la logique de pagination reste inchangé
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
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading) {
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
    if (newExpenses.length < _limit) _hasMore = false;
    if (mounted) {
      setState(() {
        _expenses.addAll(newExpenses);
        _page++;
        _isLoading = false;
      });
    }
  }

  void _onSelectionChanged(bool? isSelected, ExpenseModel expense) {
    if (expense.isSent) return;
    setState(() {
      if (isSelected ?? false) {
        _selectedKeys.add(expense.key);
      } else {
        _selectedKeys.remove(expense.key);
      }
    });
  }

  void _sendSelectedExpenses() {
    final selectedExpenses = _expenses.where((e) => _selectedKeys.contains(e.key)).toList();
    if (selectedExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner au moins une note à envoyer.')));
      return;
    }
    final task = TaskModel(type: TaskType.sendExpenseBatch, payload: selectedExpenses);
    _taskQueueService.enqueueTask(task);

    // Déclencher le traitement et afficher la progression
    ref.read(backgroundTaskServiceProvider).processQueue();
    _showProgressDialog();

    setState(() => _selectedKeys.clear());
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // J'utilise le même widget de progression que vous aviez dans ValidationView
        return const _ProgressDialogAnimator();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedKeys.isEmpty ? 'Historique' : '${_selectedKeys.length} sélectionnée(s)'),
        actions: [/* ... IconButton Corbeille ... */],
      ),
      body: _expenses.isEmpty && !_isLoading
          ? const Center(child: Text('Aucune note de frais dans l\'historique.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: _expenses.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _expenses.length) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));

          final expense = _expenses[index];
          final bool isSelected = _selectedKeys.contains(expense.key);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: expense.isSent ? Colors.grey.shade300 : Colors.white,
            child: ListTile(
              leading: Checkbox(
                value: isSelected,
                onChanged: expense.isSent ? null : (bool? value) => _onSelectionChanged(value, expense),
              ),
              title: Text(expense.company ?? 'Fournisseur inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Associé à : ${expense.associatedTo ?? 'N/A'}\n${dateFormat.format(expense.date!)}'),
              trailing: expense.isSent
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : Text(currencyFormat.format(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              isThreeLine: true,
              onTap: expense.isSent ? null : () async {
                final result = await Navigator.of(context).push<ExpenseModel>(
                  MaterialPageRoute(builder: (context) => ValidationView(expense: expense, isInBatchMode: true)),
                );
                if (result != null && mounted) {
                  setState(() {
                    _expenses[index] = result;
                  });
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: _selectedKeys.isNotEmpty ? FloatingActionButton.extended(
        onPressed: _sendSelectedExpenses,
        label: const Text('Envoyer la sélection'),
        icon: const Icon(Icons.send),
      ) : null,
    );
  }
}

// Ajouter le widget _ProgressDialogAnimator ici, copié depuis l'ancienne ValidationView
class _ProgressDialogAnimator extends ConsumerStatefulWidget {
  const _ProgressDialogAnimator();

  @override
  ConsumerState<_ProgressDialogAnimator> createState() => __ProgressDialogAnimatorState();
}

class __ProgressDialogAnimatorState extends ConsumerState<_ProgressDialogAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _lastProgressTarget = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getDialogTitle(TaskExecutionStatus status) {
    switch (status) {
      case TaskExecutionStatus.processing: return 'Envoi en cours...';
      case TaskExecutionStatus.success: return 'Terminé !';
      case TaskExecutionStatus.error: return 'Erreur';
      default: return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TaskStatus>(taskStatusProvider, (previous, next) {
      if (next.executionStatus == TaskExecutionStatus.success || next.executionStatus == TaskExecutionStatus.error) {
        _controller.animateTo(1.0, duration: const Duration(milliseconds: 500), curve: Curves.easeIn).whenComplete(() {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pop();
              // Optionnel: rafraîchir la liste historique
            }
          });
        });
      } else {
        if (next.progress > _lastProgressTarget) {
          final begin = _animation.value;
          final end = next.progress;
          _animation = Tween<double>(begin: begin, end: end).animate(
              CurvedAnimation(parent: _controller, curve: Curves.linear)
          );
          _controller.duration = const Duration(seconds: 2);
          _controller.forward(from: 0.0);
          _lastProgressTarget = end;
        }
      }
    });

    final status = ref.watch(taskStatusProvider);

    Widget content;
    switch (status.executionStatus) {
      case TaskExecutionStatus.success:
        content = Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 20),
          Text(status.message ?? 'Opération réussie.'),
        ]);
        break;
      case TaskExecutionStatus.error:
        content = Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 20),
          Text(status.message ?? 'Une erreur est survenue.'),
        ]);
        break;
      default:
        content = AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _animation.value,
                  minHeight: 6,
                ),
                const SizedBox(height: 20),
                Text(status.message ?? 'Veuillez patienter.'),
                const SizedBox(height: 10),
                if (status.stepMessage != null)
                  Text(
                    status.stepMessage!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            );
          },
        );
    }

    return AlertDialog(
      title: Text(_getDialogTitle(status.executionStatus)),
      content: content,
    );
  }
}