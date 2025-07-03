import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/controllers/expense_controller.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/statistics_service.dart';
import 'package:notes_de_frais/utils/constants.dart';
import 'package:notes_de_frais/widgets/animated_stat_widget.dart';

class ValidationView extends StatefulWidget {
  final ExpenseModel expense;
  final bool isInBatchMode;

  const ValidationView({super.key, required this.expense, this.isInBatchMode = false});

  @override
  State<ValidationView> createState() => _ValidationViewState();
}

class _ValidationViewState extends State<ValidationView> {
  final ExpenseController _controller = ExpenseController();
  final StatisticsService _statsService = StatisticsService();
  late ExpenseModel _editableExpense;
  String? _selectedCompany;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _editableExpense = widget.expense;
    _selectedCompany = _editableExpense.associatedTo;
  }

  void _onSaveForBatch() {
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une entreprise.')),
      );
      return;
    }
    _editableExpense.associatedTo = _selectedCompany;
    Navigator.of(context).pop(_editableExpense);
  }

  Future<void> _onValidateAndSend() async {
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une entreprise.')),
      );
      return;
    }
    _editableExpense.associatedTo = _selectedCompany;

    final beforeVat = _statsService.getTotalVatSaved();
    final beforeWeeklyVat = _statsService.getVatSavedThisWeek();
    final beforeCount = _statsService.getExpensesThisWeekCount();

    await _controller.saveExpenseLocally(_editableExpense);
    _controller.performBackgroundTasks(_editableExpense);

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
                  const Text('Note de frais enregistrée !', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la note'),
        leading: widget.isInBatchMode
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop(_editableExpense))
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
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
                    child: Image.file(File(_editableExpense.processedImagePaths[index])),
                  ),
                ),
              ),
            if (_editableExpense.processedImagePaths.length > 1)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Faites glisser pour voir les autres pages', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ),
            const SizedBox(height: 24),
            _buildInfoRow('Date', _editableExpense.date != null ? _dateFormat.format(_editableExpense.date!) : 'N/A'),
            _buildInfoRow('Montant', '${_editableExpense.amount?.toStringAsFixed(2) ?? 'N/A'} €'),
            _buildInfoRow('TVA', '${_editableExpense.vat?.toStringAsFixed(2) ?? 'N/A'} €'),
            _buildInfoRow('Entreprise', _editableExpense.company ?? 'N/A'),
            _buildInfoRow('Catégorie', _editableExpense.category ?? 'N/A'),
            const SizedBox(height: 24),
            _buildCompanyDropdown(),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          onPressed: widget.isInBatchMode ? _onSaveForBatch : _onValidateAndSend,
          icon: Icon(widget.isInBatchMode ? Icons.save : Icons.check_circle),
          label: Text(widget.isInBatchMode ? 'Sauvegarder' : 'Valider et Envoyer'),
          style: ElevatedButton.styleFrom(
              backgroundColor: widget.isInBatchMode ? Colors.blue : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18)
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
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
      onChanged: (String? newValue) => setState(() => _selectedCompany = newValue),
      items: kCompanyList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
  }
}