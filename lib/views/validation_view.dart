import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/controllers/expense_controller.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/utils/constants.dart';

class ValidationView extends StatefulWidget {
  final List<String> imagePaths;

  const ValidationView({super.key, required this.imagePaths});

  @override
  State<ValidationView> createState() => _ValidationViewState();
}

class _ValidationViewState extends State<ValidationView> {
  final ExpenseController _controller = ExpenseController();
  Future<ExpenseModel>? _expenseFuture;
  String? _selectedCompany;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _expenseFuture = _controller.processImages(widget.imagePaths);
  }

  Future<void> _onValidate(ExpenseModel expense) async {
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une entreprise.')),
      );
      return;
    }
    expense.associatedTo = _selectedCompany;

    setState(() => _isSending = true);

    try {
      await _controller.saveExpense(expense);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note de frais envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valider la note de frais'),
      ),
      body: FutureBuilder<ExpenseModel>(
        future: _expenseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.processedImagePaths.isEmpty) {
            return const Center(child: Text('Aucune donnée extraite.'));
          }

          final expense = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: expense.processedImagePaths.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Image.file(File(expense.processedImagePaths[index])),
                      );
                    },
                  ),
                ),
                if (expense.processedImagePaths.length > 1)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Faites glisser pour voir les autres pages',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildInfoRow('Date', expense.date != null ? _dateFormat.format(expense.date!) : 'N/A'),
                _buildInfoRow('Montant', '${expense.amount?.toStringAsFixed(2) ?? 'N/A'} €'),
                _buildInfoRow('TVA', '${expense.vat?.toStringAsFixed(2) ?? 'N/A'} €'),
                _buildInfoRow('Entreprise', expense.company ?? 'N/A'),
                const SizedBox(height: 24),
                _buildCompanyDropdown(),
                const SizedBox(height: 24),
                if (_isSending)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _onValidate(expense),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Valider et envoyer'),
                  ),
              ],
            ),
          );
        },
      ),
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
      onChanged: (String? newValue) {
        setState(() {
          _selectedCompany = newValue;
        });
      },
      items: kCompanyList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}