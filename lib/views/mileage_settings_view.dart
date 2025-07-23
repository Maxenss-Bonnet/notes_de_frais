import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_de_frais/providers/providers.dart';

class MileageSettingsView extends ConsumerStatefulWidget {
  const MileageSettingsView({super.key});

  @override
  ConsumerState<MileageSettingsView> createState() =>
      _MileageSettingsViewState();
}

class _MileageSettingsViewState extends ConsumerState<MileageSettingsView> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveRates() {
    if (_formKey.currentState!.validate()) {
      final newRates = {
        for (var entry in _controllers.entries)
          entry.key: double.parse(entry.value.text.replaceAll(',', '.'))
      };
      ref.read(settingsServiceProvider).saveMileageRates(newRates).then((_) {
        ref.invalidate(mileageRatesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Taux kilométriques enregistrés.')),
        );
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mileageRates = ref.watch(mileageRatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taux Kilométriques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRates,
            tooltip: 'Enregistrer',
          )
        ],
      ),
      body: mileageRates.when(
        data: (rates) {
          if (_controllers.isEmpty) {
            _controllers = {
              for (var key in rates.keys)
                key: TextEditingController(text: rates[key].toString())
            };
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: rates.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _controllers[entry.key],
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.speed_outlined),
                      suffixText: '€ / km',
                    ),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une valeur.';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) ==
                          null) {
                        return 'Veuillez entrer un nombre valide.';
                      }
                      return null;
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}