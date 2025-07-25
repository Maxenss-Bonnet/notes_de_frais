import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/controllers/expense_controller.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/models/task_model.dart';
import 'package:notes_de_frais/providers/providers.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:notes_de_frais/utils/constants.dart';
import 'package:notes_de_frais/widgets/animated_stat_widget.dart';
import 'package:notes_de_frais/widgets/confidence_reminder_widget.dart';
import 'package:notes_de_frais/views/camera_view.dart';
import 'package:shimmer/shimmer.dart';

class ValidationView extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  final bool isInBatchMode;

  const ValidationView(
      {super.key, required this.expense, this.isInBatchMode = false});

  @override
  ConsumerState<ValidationView> createState() => _ValidationViewState();
}

class _ValidationViewState extends ConsumerState<ValidationView> {
  final ExpenseController _controller = ExpenseController();
  final StatisticsService _statsService = StatisticsService();
  late ExpenseModel _editableExpense;
  String? _selectedCompany;
  String? _selectedCard;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  OverlayEntry? _overlayEntry;

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _amountController;
  late TextEditingController _vatController;
  late TextEditingController _companyController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _editableExpense = widget.expense;
    _selectedCompany = _editableExpense.associatedTo;
    _selectedCard = _editableExpense.creditCard;

    _dateController = TextEditingController(
        text: _editableExpense.date != null
            ? _dateFormat.format(_editableExpense.date!)
            : '');
    _amountController =
        TextEditingController(text: _editableExpense.amount?.toString() ?? '');
    _vatController =
        TextEditingController(text: _editableExpense.vat?.toString() ?? '');
    _companyController =
        TextEditingController(text: _editableExpense.company ?? '');
    _categoryController =
        TextEditingController(text: _editableExpense.category ?? '');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _vatController.dispose();
    _companyController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _updateExpenseFromControllers() {
    if (_formKey.currentState!.validate()) {
      _editableExpense.date = _dateFormat.tryParse(_dateController.text);
      _editableExpense.amount = double.tryParse(_amountController.text);
      _editableExpense.vat = double.tryParse(_vatController.text);
      _editableExpense.company = _companyController.text;
      _editableExpense.category = _categoryController.text;
    }
  }

  bool _validateInputs() {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner une carte de crédit.')),
      );
      return false;
    }
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une entreprise.')),
      );
      return false;
    }
    return true;
  }

  void _onSaveForBatch() {
    if (!_validateInputs()) return;

    if (_isEditing) {
      _updateExpenseFromControllers();
    }
    _editableExpense.associatedTo = _selectedCompany;
    _editableExpense.creditCard = _selectedCard;
    Navigator.of(context).pop(_editableExpense);
  }

  Future<void> _onValidateAndSend() async {
    if (!_validateInputs()) return;

    if (_isEditing) {
      _updateExpenseFromControllers();
    }
    _editableExpense.associatedTo = _selectedCompany;
    _editableExpense.creditCard = _selectedCard;

    final beforeVat = _statsService.getTotalVatSaved();
    final beforeWeeklyVat = _statsService.getVatSavedThisWeek();
    final beforeCount = _statsService.getExpensesThisWeekCount();

    await _controller.saveExpenseLocally(_editableExpense);
    _controller.performBackgroundTasks(_editableExpense);

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
                      'Note de frais enregistrée !',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la note'),
        leading: widget.isInBatchMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(_editableExpense))
            : null,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.done : Icons.edit),
            tooltip: _isEditing ? 'Terminer' : 'Modifier',
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _updateExpenseFromControllers();
                }
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_editableExpense.processedImagePaths.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: _editableExpense.processedImagePaths.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Image.file(
                          File(_editableExpense.processedImagePaths[index])),
                    ),
                  ),
                ),
              if (_editableExpense.processedImagePaths.length > 1)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Faites glisser pour voir les autres pages',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ),

              // Bouton discret pour reprendre la photo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _onRetakePhoto,
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Reprendre la photo'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),

              // Rappel de confiance
              ConfidenceReminderWidget(
                expense: _editableExpense,
                onRetakePhoto: _onRetakePhoto,
              ),

              const SizedBox(height: 16),
              _buildEditableDateField(_editableExpense.dateConfidence),
              _buildEditableTextField(
                  _amountController,
                  'Montant TTC',
                  _editableExpense.amountConfidence,
                  const TextInputType.numberWithOptions(decimal: true)),
              _buildEditableTextField(
                  _vatController,
                  'TVA',
                  _editableExpense.vatConfidence,
                  const TextInputType.numberWithOptions(decimal: true)),
              _buildEditableTextField(_companyController,
                  'Entreprise (Marchand)', _editableExpense.companyConfidence),
              _buildEditableTextField(_categoryController, 'Catégorie',
                  _editableExpense.categoryConfidence),
              const SizedBox(height: 24),
              _buildCreditCardSelection(),
              const SizedBox(height: 16),
              _buildCompanyDropdown(),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          onPressed:
              widget.isInBatchMode ? _onSaveForBatch : _onValidateAndSend,
          icon: Icon(widget.isInBatchMode ? Icons.save : Icons.check_circle),
          label:
              Text(widget.isInBatchMode ? 'Sauvegarder' : 'Valider et Envoyer'),
          style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.isInBatchMode ? Colors.blue : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCreditCardSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payé avec la carte :',
            style: Theme.of(context).textTheme.titleMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('American Express'),
                value: 'American Express',
                groupValue: _selectedCard,
                onChanged: (value) => setState(() => _selectedCard = value),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Personnel'),
                value: 'Personnel',
                groupValue: _selectedCard,
                onChanged: (value) => setState(() => _selectedCard = value),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator(double? confidence) {
    if (confidence == null) return const SizedBox.shrink();

    Color color;
    IconData icon;

    if (confidence >= 0.8) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (confidence >= 0.5) {
      color = Colors.orange;
      icon = Icons.warning;
    } else {
      color = Colors.red;
      icon = Icons.error;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEditableTextField(
      TextEditingController controller, String label, double? confidence,
      [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _isEditing
          ? TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                suffixIcon: _buildConfidenceIndicator(confidence),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ce champ ne peut pas être vide';
                }
                return null;
              },
            )
          : _buildInfoRow(label,
              controller.text.isEmpty ? 'N/A' : controller.text, confidence),
    );
  }

  Widget _buildEditableDateField(double? confidence) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _isEditing
          ? TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Date',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildConfidenceIndicator(confidence),
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              readOnly: true,
              onTap: () async {
                DateTime initialDate =
                    _dateFormat.tryParse(_dateController.text) ??
                        DateTime.now();
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _dateController.text = _dateFormat.format(pickedDate);
                  });
                }
              },
            )
          : _buildInfoRow(
              'Date',
              _dateController.text.isEmpty ? 'N/A' : _dateController.text,
              confidence),
    );
  }

  Widget _buildInfoRow(String label, String value, double? confidence) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              _buildConfidenceIndicator(confidence),
            ],
          ),
          Flexible(
              child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.right,
          )),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Associer à l\'entreprise',
        border: OutlineInputBorder(),
      ),
      value: _selectedCompany,
      onChanged: (String? newValue) =>
          setState(() => _selectedCompany = newValue),
      items: kCompanyList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
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
