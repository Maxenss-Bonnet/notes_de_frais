import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:notes_de_frais/utils/constants.dart';
import 'package:notes_de_frais/views/validation_view.dart';

class AddMileageExpenseView extends StatefulWidget {
  const AddMileageExpenseView({super.key});

  @override
  State<AddMileageExpenseView> createState() => _AddMileageExpenseViewState();
}

class _AddMileageExpenseViewState extends State<AddMileageExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService();
  final _distanceController = TextEditingController();
  final _reasonController = TextEditingController();
  final _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));

  String? _fiscalHorsepower;
  double _calculatedAmount = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _distanceController.addListener(_calculateAmount);
  }

  Future<void> _loadSettings() async {
    final info = await _settingsService.getEmployeeInfo();
    final cv = info['fiscalHorsepower'];
    if (cv == null || cv.isEmpty) {
      if (mounted) {
        // Alerte si les CV ne sont pas configurés
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Configuration requise'),
            content: const Text('Veuillez configurer la puissance fiscale de votre véhicule dans les paramètres avant de créer une note kilométrique.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() {
        _fiscalHorsepower = cv;
        _isLoading = false;
      });
    }
  }

  void _calculateAmount() {
    final distance = double.tryParse(_distanceController.text);
    if (distance != null && _fiscalHorsepower != null) {
      final rate = kMileageRates[_fiscalHorsepower];
      if (rate != null) {
        setState(() {
          _calculatedAmount = distance * rate;
        });
      }
    }
  }

  void _createAndValidateExpense() {
    if (_formKey.currentState!.validate()) {
      final expense = ExpenseModel(
        imagePath: '', // Pas d'image pour ce type de note
        date: DateFormat('dd/MM/yyyy').tryParse(_dateController.text),
        amount: _calculatedAmount,
        vat: 0, // Pas de TVA sur les frais kilométriques
        company: _reasonController.text,
        category: 'Frais Kilométriques',
      );

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ValidationView(expense: expense))
      );
    }
  }

  @override
  void dispose() {
    _distanceController.removeListener(_calculateAmount);
    _distanceController.dispose();
    _reasonController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle note kilométrique'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif du déplacement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un motif.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Distance parcourue (km)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.social_distance_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Veuillez entrer une distance.';
                  if (double.tryParse(value) == null) return 'Veuillez entrer un nombre valide.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Montant du remboursement', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(_calculatedAmount),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text('Basé sur $_fiscalHorsepower', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _createAndValidateExpense,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuer vers la validation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}