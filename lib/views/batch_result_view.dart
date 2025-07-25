import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_de_frais/controllers/expense_controller.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/providers/providers.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:notes_de_frais/views/validation_view.dart';
import 'package:notes_de_frais/views/camera_view.dart';
import 'package:notes_de_frais/widgets/confidence_reminder_widget.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/widgets/animated_stat_widget.dart';
import 'package:shimmer/shimmer.dart';

class BatchResultView extends ConsumerStatefulWidget {
  final List<ExpenseModel> expenses;
  const BatchResultView({super.key, required this.expenses});

  @override
  ConsumerState<BatchResultView> createState() => _BatchResultViewState();
}

class _BatchResultViewState extends ConsumerState<BatchResultView> {
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
    final bool allAssociated = _expenses.every((e) => e.associatedTo != null);
    final bool allCardsSelected = _expenses.every((e) => e.creditCard != null);

    if (!allAssociated || !allCardsSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Veuillez associer chaque note à une entreprise et sélectionner une carte de crédit.')),
      );
      return;
    }

    final beforeVat = _statsService.getTotalVatSaved();
    final beforeWeeklyVat = _statsService.getVatSavedThisWeek();
    final beforeCount = _statsService.getExpensesThisWeekCount();

    await _controller.saveExpenseBatchLocally(_expenses);
    _controller.performBackgroundTasksForBatch(_expenses);

    final afterVat = _statsService.getTotalVatSaved();
    final afterWeeklyVat = _statsService.getVatSavedThisWeek();
    final afterCount = _statsService.getExpensesThisWeekCount();

    _showRewardOverlay(
        beforeVat: beforeVat,
        afterVat: afterVat,
        beforeWeeklyVat: beforeWeeklyVat,
        afterWeeklyVat: afterWeeklyVat,
        beforeCount: beforeCount,
        afterCount: afterCount);

    await Future.delayed(const Duration(seconds: 4));
    _hideRewardOverlay();

    if (mounted) {
      _showProgressDialog();
      ref.read(backgroundTaskServiceProvider).processQueue();
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _ProgressDialogAnimator();
      },
    );
  }

  void _showRewardOverlay(
      {required double beforeVat,
      required double afterVat,
      required double beforeWeeklyVat,
      required double afterWeeklyVat,
      required int beforeCount,
      required int afterCount}) {
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
                  Shimmer.fromColors(
                    baseColor: Colors.white,
                    highlightColor: Colors.grey.shade400,
                    period: const Duration(milliseconds: 2500),
                    child: const Text(
                      'Notes de frais enregistrées !',
                      style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                              child: AnimatedStatWidget(
                                  title: 'Notes (semaine)',
                                  beginValue: beforeCount.toDouble(),
                                  endValue: afterCount.toDouble(),
                                  icon: Icons.note_add_outlined,
                                  color: Colors.orange)),
                          Flexible(
                              child: AnimatedStatWidget(
                                  title: 'TVA (semaine)',
                                  beginValue: beforeWeeklyVat,
                                  endValue: afterWeeklyVat,
                                  icon: Icons.calendar_today,
                                  color: Colors.purple,
                                  isCurrency: true)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AnimatedStatWidget(
                          title: 'TVA (Total)',
                          beginValue: beforeVat,
                          endValue: afterVat,
                          icon: Icons.shield_outlined,
                          color: Colors.green,
                          isCurrency: true),
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

  void _onRetakePhoto() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const CameraView(),
      ),
      (route) => route.isFirst,
    );
  }

  // Vérifie si au moins un champ a une confiance < 100%
  bool _hasLowConfidence(ExpenseModel expense) {
    final confidences = [
      expense.amountConfidence,
      expense.dateConfidence,
      expense.companyConfidence,
      expense.vatConfidence,
      expense.categoryConfidence,
      expense.normalizedMerchantNameConfidence,
    ];

    return confidences
        .any((confidence) => confidence != null && confidence < 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final bool allValidated =
        _expenses.every((e) => e.associatedTo != null && e.creditCard != null);

    return Scaffold(
      appBar: AppBar(
        title: Text('Valider les notes (${_expenses.length})'),
        actions: [
          // Bouton discret pour reprendre la photo
          TextButton.icon(
            onPressed: _onRetakePhoto,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Reprendre'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Rappel de confiance global
          if (_expenses.any((expense) => _hasLowConfidence(expense)))
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Certaines notes ont des données extraites avec une confiance limitée. Considérez reprendre les photos.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _onRetakePhoto,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Reprendre',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                final bool isDataComplete = expense.date != null &&
                    expense.amount != null &&
                    expense.company != null;
                final bool isAssociated = expense.associatedTo != null;
                final bool isCardSelected = expense.creditCard != null;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isDataComplete ? Colors.white : Colors.orange.shade50,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: const Icon(Icons.receipt_long, size: 40),
                    title: Text(
                        expense.normalizedMerchantName ??
                            expense.company ??
                            'Analyse incomplète',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.category ?? "Non catégorisé"),
                        Text(
                          isAssociated
                              ? "Associé à : ${expense.associatedTo}"
                              : "Aucune société associée",
                          style: TextStyle(
                              color: isAssociated ? Colors.green : Colors.red,
                              fontSize: 12),
                        ),
                        Text(
                          isCardSelected
                              ? "Carte : ${expense.creditCard}"
                              : "Aucune carte sélectionnée",
                          style: TextStyle(
                              color: isCardSelected
                                  ? Colors.blueAccent
                                  : Colors.red,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Text(
                      expense.amount != null
                          ? currencyFormat.format(expense.amount)
                          : 'N/A',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDataComplete ? Colors.blue : Colors.red,
                          fontSize: 16),
                    ),
                    isThreeLine: true,
                    onTap: () async {
                      final updatedExpense =
                          await Navigator.of(context).push<ExpenseModel>(
                        MaterialPageRoute(
                          builder: (context) => ValidationView(
                              expense: expense, isInBatchMode: true),
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
          ),
        ],
      ),
      floatingActionButton: _expenses.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: allValidated ? _onValidateAll : null,
                icon: const Icon(Icons.done_all),
                label: const Text('Tout valider et Envoyer'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18)),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _ProgressDialogAnimator extends ConsumerStatefulWidget {
  const _ProgressDialogAnimator();

  @override
  ConsumerState<_ProgressDialogAnimator> createState() =>
      __ProgressDialogAnimatorState();
}

class __ProgressDialogAnimatorState
    extends ConsumerState<_ProgressDialogAnimator>
    with SingleTickerProviderStateMixin {
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
      if (next.executionStatus == TaskExecutionStatus.success ||
          next.executionStatus == TaskExecutionStatus.error) {
        _controller
            .animateTo(1.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn)
            .whenComplete(() {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pop();
              if (next.executionStatus == TaskExecutionStatus.success) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            }
          });
        });
      } else {
        if (next.progress > _lastProgressTarget) {
          final begin = _animation.value;
          final end = next.progress;
          _animation = Tween<double>(begin: begin, end: end).animate(
              CurvedAnimation(parent: _controller, curve: Curves.linear));
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
