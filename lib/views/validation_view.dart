import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/controllers/expense_controller.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/providers/providers.dart';

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
  late ExpenseModel _editableExpense;
  String? _selectedCompany;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _amountController;
  late TextEditingController _vatController;
  late TextEditingController _companyController;
  late TextEditingController _categoryController;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _editableExpense = widget.expense;
    _selectedCompany = _editableExpense.associatedTo;

    _dateController = TextEditingController(
        text: _editableExpense.date != null
            ? _dateFormat.format(_editableExpense.date!)
            : '');
    _amountController = TextEditingController(
        text: _editableExpense.amount?.toStringAsFixed(2) ?? '');
    _vatController =
        TextEditingController(text: _editableExpense.vat?.toString() ?? '0.0');
    _companyController =
        TextEditingController(text: _editableExpense.company ?? '');
    _categoryController =
        TextEditingController(text: _editableExpense.category ?? '');
    _commentController =
        TextEditingController(text: _editableExpense.comment ?? '');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _vatController.dispose();
    _companyController.dispose();
    _categoryController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _updateExpenseFromControllers() {
    if (_formKey.currentState!.validate()) {
      _editableExpense.date = _dateFormat.tryParse(_dateController.text);
      _editableExpense.amount =
          double.tryParse(_amountController.text.replaceAll(',', '.'));
      _editableExpense.vat =
          double.tryParse(_vatController.text.replaceAll(',', '.'));
      _editableExpense.company = _companyController.text;
      _editableExpense.category = _categoryController.text;
    }
  }

  bool _validateInputs() {
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
    _editableExpense.comment = _commentController.text;
    _editableExpense.associatedTo = _selectedCompany;
    Navigator.of(context).pop(_editableExpense);
  }

  Future<void> _onSaveAndClose() async {
    if (!_validateInputs()) return;

    if (_isEditing) {
      _updateExpenseFromControllers();
    }
    _editableExpense.comment = _commentController.text;
    _editableExpense.associatedTo = _selectedCompany;

    await _controller.saveExpenseLocally(_editableExpense);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Note de frais enregistrée dans l\'historique.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMileageExpense = _editableExpense.category == 'Frais Kilométriques';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isMileageExpense ? 'Note Kilométrique' : 'Détail de la note'),
        leading: widget.isInBatchMode
            ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_editableExpense))
            : null,
        actions: [
          if (!isMileageExpense)
            IconButton(
              icon: Icon(_isEditing ? Icons.done : Icons.edit),
              tooltip: _isEditing
                  ? 'Terminer la modification'
                  : 'Modifier les données de l\'IA',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
              const SizedBox(height: 24),
              _buildEditableDateField(_editableExpense.dateConfidence),
              _buildEditableTextField(
                  _amountController,
                  'Montant',
                  _editableExpense.amountConfidence,
                  const TextInputType.numberWithOptions(decimal: true)),
              if (!isMileageExpense)
                _buildEditableTextField(
                    _vatController,
                    'TVA',
                    _editableExpense.vatConfidence,
                    const TextInputType.numberWithOptions(decimal: true)),
              _buildEditableTextField(
                  _companyController,
                  isMileageExpense
                      ? 'Motif du déplacement'
                      : 'Entreprise (Marchand)',
                  _editableExpense.companyConfidence),
              if (!isMileageExpense)
                _buildEditableTextField(_categoryController, 'Catégorie',
                    _editableExpense.categoryConfidence),
              const SizedBox(height: 16),
              _buildCommentField(),
              const SizedBox(height: 24),
              _buildCompanyDropdown(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: ElevatedButton.icon(
          onPressed: widget.isInBatchMode ? _onSaveForBatch : _onSaveAndClose,
          icon: Icon(widget.isInBatchMode
              ? Icons.save
              : Icons.check_circle_outline),
          label: Text(widget.isInBatchMode
              ? 'Sauvegarder les modifications'
              : 'Sauvegarder et Fermer'),
          style: ElevatedButton.styleFrom(
              backgroundColor:
              widget.isInBatchMode ? Colors.blue : Colors.green,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildCommentField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _commentController,
        decoration: const InputDecoration(
          labelText: 'Libellé',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.edit_note_outlined),
        ),
      ),
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

  Widget _buildEditableTextField(TextEditingController controller, String label,
      double? confidence, [TextInputType? keyboardType]) {
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
          if (keyboardType?.toString().contains('number') ?? false) {
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Veuillez entrer un nombre valide.';
            }
          }
          return null;
        },
      )
          : _buildInfoRow(
          label,
          controller.text.isEmpty ? 'N/A' : controller.text,
          confidence),
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
              child: Text(value,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    final companyListAsync = ref.watch(companyListProvider);
    return companyListAsync.when(
      data: (companies) => DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Associer à l\'entreprise',
          border: OutlineInputBorder(),
        ),
        value: _selectedCompany,
        onChanged: (String? newValue) =>
            setState(() => _selectedCompany = newValue),
        items: companies.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        validator: (value) =>
        value == null ? 'Veuillez sélectionner une entreprise' : null,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Text('Erreur de chargement des sociétés'),
    );
  }
}