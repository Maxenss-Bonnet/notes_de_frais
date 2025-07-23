import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_de_frais/providers/providers.dart';

class CompanySettingsView extends ConsumerStatefulWidget {
  const CompanySettingsView({super.key});

  @override
  ConsumerState<CompanySettingsView> createState() =>
      _CompanySettingsViewState();
}

class _CompanySettingsViewState extends ConsumerState<CompanySettingsView> {
  late List<String> _companies;

  @override
  void initState() {
    super.initState();
    _companies = [];
  }

  void _addCompany() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Société'),
        content: TextField(
          controller: controller,
          decoration:
          const InputDecoration(hintText: 'Nom de la société'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _companies.add(controller.text);
                });
                _saveCompanies();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _removeCompany(int index) {
    setState(() {
      _companies.removeAt(index);
    });
    _saveCompanies();
  }

  Future<void> _saveCompanies() async {
    await ref.read(settingsServiceProvider).saveCompanyList(_companies);
    ref.invalidate(companyListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final companyList = ref.watch(companyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sociétés d\'Imputation'),
      ),
      body: companyList.when(
        data: (companies) {
          if (_companies.isEmpty) {
            _companies = List.from(companies);
          }
          if (_companies.isEmpty) {
            return const Center(child: Text('Aucune société configurée.'));
          }
          return ListView.builder(
            itemCount: _companies.length,
            itemBuilder: (context, index) {
              final company = _companies[index];
              return Dismissible(
                key: Key(company + index.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _removeCompany(index),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(company),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCompany,
        tooltip: 'Ajouter une société',
        child: const Icon(Icons.add),
      ),
    );
  }
}