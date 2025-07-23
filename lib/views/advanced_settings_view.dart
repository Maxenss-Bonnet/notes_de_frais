import 'package:flutter/material.dart';
import 'package:notes_de_frais/views/company_settings_view.dart';
import 'package:notes_de_frais/views/mileage_settings_view.dart';

class AdvancedSettingsView extends StatelessWidget {
  const AdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres Avancés'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.directions_car_filled_outlined),
            title: const Text('Gérer les taux kilométriques'),
            subtitle: const Text('Modifier les montants de remboursement par CV'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const MileageSettingsView(),
              ));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('Gérer les sociétés d\'imputation'),
            subtitle: const Text('Ajouter ou supprimer des entreprises'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CompanySettingsView(),
              ));
            },
          ),
        ],
      ),
    );
  }
}