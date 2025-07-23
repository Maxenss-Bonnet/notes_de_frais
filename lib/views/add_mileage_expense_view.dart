import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/providers/providers.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:notes_de_frais/views/validation_view.dart';

class AddMileageExpenseView extends ConsumerStatefulWidget {
  const AddMileageExpenseView({super.key});

  @override
  ConsumerState<AddMileageExpenseView> createState() =>
      _AddMileageExpenseViewState();
}

class _AddMileageExpenseViewState extends ConsumerState<AddMileageExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService();
  final _distanceController = TextEditingController();
  final _reasonController = TextEditingController();
  final _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()));

  String? _fiscalHorsepower;
  final ValueNotifier<double> _calculatedAmountNotifier =
      ValueNotifier<double>(0.0);
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
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Configuration requise'),
            content: const Text(
                'Veuillez configurer la puissance fiscale de votre véhicule dans les paramètres avant de créer une note kilométrique.'),
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
    final mileageRates = ref.read(mileageRatesProvider).asData?.value;
    if (mileageRates == null) return;

    final distance = double.tryParse(_distanceController.text);
    if (distance != null && _fiscalHorsepower != null) {
      final rate = mileageRates[_fiscalHorsepower];
      if (rate != null) {
        _calculatedAmountNotifier.value = distance * rate;
      }
    } else {
      _calculatedAmountNotifier.value = 0.0;
    }
  }

  void _createAndValidateExpense() {
    if (_formKey.currentState!.validate()) {
      final expense = ExpenseModel(
          imagePath: '',
          date: DateFormat('dd/MM/yyyy').tryParse(_dateController.text),
          amount: _calculatedAmountNotifier.value,
          vat: 0,
          company: _reasonController.text,
          category: 'Frais Kilométriques',
          distance: double.tryParse(_distanceController.text));

      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ValidationView(expense: expense)));
    }
  }

  @override
  void dispose() {
    _distanceController.removeListener(_calculateAmount);
    _distanceController.dispose();
    _reasonController.dispose();
    _dateController.dispose();
    _calculatedAmountNotifier.dispose();
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
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                child: Column(
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
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          _dateController.text =
                              DateFormat('dd/MM/yyyy').format(pickedDate);
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
                      validator: (value) => value == null || value.isEmpty
                          ? 'Veuillez entrer un motif.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _distanceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Distance parcourue (km)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.social_distance_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une distance.';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ValueListenableBuilder<double>(
                      valueListenable: _calculatedAmountNotifier,
                      builder: (context, calculatedAmount, child) {
                        return Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Montant du remboursement',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(height: 8),
                                Text(
                                  NumberFormat.currency(
                                          locale: 'fr_FR', symbol: '€')
                                      .format(calculatedAmount),
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                                const SizedBox(height: 4),
                                if (_fiscalHorsepower != null)
                                  Text('Basé sur $_fiscalHorsepower',
                                      style:
                                          const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: ElevatedButton.icon(
          onPressed: _createAndValidateExpense,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continuer vers la validation'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

// Exemple : extraire la section bouton en widget stateless privé avec RepaintBoundary
class _AddMileageButtonSection extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  const _AddMileageButtonSection(
      {required this.onPressed, required this.isLoading});
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: const Icon(Icons.save),
        label: const Text('Enregistrer'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
