import 'package:flutter/material.dart';
import 'package:notes_de_frais/services/settings_service.dart';
import 'package:notes_de_frais/utils/constants.dart';
import 'package:notes_de_frais/views/pin_code_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  final SettingsService _settingsService = SettingsService();
  late TextEditingController _recipientEmailController;
  late TextEditingController _recipientFirstNameController;
  late TextEditingController _recipientLastNameController;
  late TextEditingController _employeeEmailController;
  late TextEditingController _employeeFirstNameController;
  late TextEditingController _employeeLastNameController;
  late TextEditingController _employeeEmployerController;
  String? _selectedCv;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _recipientEmailController = TextEditingController();
    _recipientFirstNameController = TextEditingController();
    _recipientLastNameController = TextEditingController();
    _employeeEmailController = TextEditingController();
    _employeeFirstNameController = TextEditingController();
    _employeeLastNameController = TextEditingController();
    _employeeEmployerController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final recipientInfo = await _settingsService.getRecipientInfo();
    final employeeInfo = await _settingsService.getEmployeeInfo();

    _recipientEmailController.text = recipientInfo['email']!;
    _recipientFirstNameController.text = recipientInfo['firstName']!;
    _recipientLastNameController.text = recipientInfo['lastName']!;

    _employeeEmailController.text = employeeInfo['email']!;
    _employeeFirstNameController.text = employeeInfo['firstName']!;
    _employeeLastNameController.text = employeeInfo['lastName']!;
    _employeeEmployerController.text = employeeInfo['employer']!;
    final savedCv = employeeInfo['fiscalHorsepower'];
    if (savedCv != null && kMileageRatesDefaults.keys.contains(savedCv)) {
      _selectedCv = savedCv;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _recipientEmailController.dispose();
    _recipientFirstNameController.dispose();
    _recipientLastNameController.dispose();
    _employeeEmailController.dispose();
    _employeeFirstNameController.dispose();
    _employeeLastNameController.dispose();
    _employeeEmployerController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      await _settingsService.saveRecipientInfo(
        email: _recipientEmailController.text,
        firstName: _recipientFirstNameController.text,
        lastName: _recipientLastNameController.text,
      );
      await _settingsService.saveEmployeeInfo(
        email: _employeeEmailController.text,
        firstName: _employeeFirstNameController.text,
        lastName: _employeeLastNameController.text,
        fiscalHorsepower: _selectedCv,
        employer: _employeeEmployerController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres enregistrés !')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Informations de l\'employé',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeFirstNameController,
                decoration: const InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez entrer un prénom.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeLastNameController,
                decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez entrer un nom.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeEmailController,
                decoration: const InputDecoration(
                    labelText: 'Adresse e-mail personnelle',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.alternate_email)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                (value == null || !value.contains('@'))
                    ? 'Veuillez entrer une adresse e-mail valide.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeEmployerController,
                decoration: const InputDecoration(
                    labelText: 'Employeur (Nom de l\'entreprise)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business_center_outlined)),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez entrer un employeur.'
                    : null,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCv,
                onChanged: (value) => setState(() => _selectedCv = value),
                items: kMileageRatesDefaults.keys
                    .map((cv) => DropdownMenuItem(value: cv, child: Text(cv)))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Puissance Fiscale (CV) du véhicule',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
                validator: (value) => value == null
                    ? 'Veuillez sélectionner une puissance fiscale.'
                    : null,
              ),
              const SizedBox(height: 32),
              Text('Informations du destinataire (comptabilité)',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientFirstNameController,
                decoration: const InputDecoration(
                    labelText: 'Prénom du destinataire',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_pin_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientLastNameController,
                decoration: const InputDecoration(
                    labelText: 'Nom du destinataire',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_pin_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientEmailController,
                decoration: const InputDecoration(
                    labelText: 'Adresse e-mail du destinataire',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                (value == null || !value.contains('@'))
                    ? 'Veuillez entrer une adresse e-mail valide.'
                    : null,
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings_suggest_outlined),
                title: const Text('Paramètres avancés'),
                subtitle: const Text(
                    'Gestion des sociétés et des taux kilométriques'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const PinCodeView(),
                  ));
                },
              ),
              const Divider(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
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