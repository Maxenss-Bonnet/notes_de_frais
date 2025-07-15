import 'package:flutter/material.dart';
import 'package:notes_de_frais/services/settings_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  final SettingsService _settingsService = SettingsService();
  late TextEditingController _recipientEmailController;
  late TextEditingController _employeeEmailController;
  late TextEditingController _employeeFirstNameController;
  late TextEditingController _employeeLastNameController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _recipientEmailController = TextEditingController();
    _employeeEmailController = TextEditingController();
    _employeeFirstNameController = TextEditingController();
    _employeeLastNameController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final recipientEmail = await _settingsService.getRecipientEmail();
    final employeeInfo = await _settingsService.getEmployeeInfo();
    _recipientEmailController.text = recipientEmail;
    _employeeEmailController.text = employeeInfo['email']!;
    _employeeFirstNameController.text = employeeInfo['firstName']!;
    _employeeLastNameController.text = employeeInfo['lastName']!;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _recipientEmailController.dispose();
    _employeeEmailController.dispose();
    _employeeFirstNameController.dispose();
    _employeeLastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      await _settingsService.saveRecipientEmail(_recipientEmailController.text);
      await _settingsService.saveEmployeeInfo(
        email: _employeeEmailController.text,
        firstName: _employeeFirstNameController.text,
        lastName: _employeeLastNameController.text,
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
              Text('Informations de l\'employé', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeFirstNameController,
                decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un prénom.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeLastNameController,
                decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un nom.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeEmailController,
                decoration: const InputDecoration(labelText: 'Adresse e-mail personnelle', border: OutlineInputBorder(), prefixIcon: Icon(Icons.alternate_email)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Veuillez entrer une adresse e-mail valide.' : null,
              ),
              const SizedBox(height: 32),
              Text('E-mail du destinataire (comptabilité)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientEmailController,
                decoration: const InputDecoration(labelText: 'Adresse e-mail', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Veuillez entrer une adresse e-mail valide.' : null,
              ),
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