import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/providers/providers.dart';
import 'package:notes_de_frais/services/storage_service.dart';
import 'package:notes_de_frais/services/task_queue_service.dart';
import 'package:notes_de_frais/views/add_mileage_expense_view.dart';
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
  final Set<dynamic> _selectedKeys = <dynamic>{};

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

  Future<void> _refreshHistory() async {
    setState(() {
      _page = 1;
      _expenses.clear();
      _selectedKeys.clear();
      _hasMore = true;
      _isLoading = false;
    });
    await _loadMoreExpenses();
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

    ref.read(backgroundTaskServiceProvider).processQueue();
    _showProgressDialog();

    setState(() => _selectedKeys.clear());
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // La boîte de dialogue notifie la page parente de rafraîchir via le .then()
        return const _ProgressDialogAnimator();
      },
    ).then((_) => _refreshHistory()); // Rafraîchir l'historique après la fermeture de la pop-up
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedKeys.isEmpty ? 'Historique des notes' : '${_selectedKeys.length} sélectionnée(s)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Corbeille',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TrashView()),
              ).then((_) => _refreshHistory());
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
          : RefreshIndicator(
        onRefresh: _refreshHistory,
        child: ListView.builder(
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
            final bool isSelected = _selectedKeys.contains(expense.key);
            final bool isMileage = expense.category == 'Frais Kilométriques';

            return Dismissible(
              key: Key(expense.key.toString()),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _storageService.moveToTrash(expense.key);
                if (mounted) {
                  setState(() {
                    _expenses.removeAt(index);
                  });
                }
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: expense.isSent ? Colors.grey.shade200 : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(4.0, 8.0, 16.0, 8.0),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: expense.isSent ? null : (bool? value) => _onSelectionChanged(value, expense),
                      ),
                      Icon(isMileage ? Icons.directions_car_outlined : Icons.receipt_long_outlined),
                      const SizedBox(width: 4),
                    ],
                  ),
                  title: Text(expense.company ?? 'Motif ou Fournisseur inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${expense.date != null ? dateFormat.format(expense.date!) : 'Date inconnue'}\nAssocié à : ${expense.associatedTo ?? 'N/A'}'),
                  trailing: expense.isSent
                      ? const Tooltip(message: 'Envoyée', child: Icon(Icons.check_circle, color: Colors.green))
                      : Text(
                    expense.amount != null ? currencyFormat.format(expense.amount) : 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                  isThreeLine: true,
                  onTap: expense.isSent
                      ? null
                      : () async {
                    final result = await Navigator.of(context).push<ExpenseModel>(
                      MaterialPageRoute(
                        builder: (context) => ValidationView(expense: expense, isInBatchMode: true),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _expenses[index] = result;
                      });
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedKeys.isNotEmpty)
            FloatingActionButton.extended(
              onPressed: _sendSelectedExpenses,
              label: const Text('Envoyer la sélection'),
              icon: const Icon(Icons.send),
              heroTag: 'send',
            ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddMileageExpenseView()),
              ).then((_) => _refreshHistory());
            },
            label: const Text('Note kilométrique'),
            icon: const Icon(Icons.add_road_outlined),
            heroTag: 'add_mileage',
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

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
      case TaskExecutionStatus.processing:
        return 'Envoi en cours...';
      case TaskExecutionStatus.success:
        return 'Terminé !';
      case TaskExecutionStatus.error:
        return 'Erreur';
      default:
        return 'En attente';
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
              // Le .then() sur le showDialog s'occupera du rafraîchissement
            }
          });
        });
      } else {
        if (next.progress > _lastProgressTarget) {
          final begin = _animation.value;
          final end = next.progress;
          _animation = Tween<double>(begin: begin, end: end).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
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