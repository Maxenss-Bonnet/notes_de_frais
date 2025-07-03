import 'package:flutter/material.dart';
import 'package:notes_de_frais/controllers/expense_controller.dart';
import 'package:notes_de_frais/models/expense_model.dart';
import 'package:notes_de_frais/views/batch_result_view.dart';
import 'package:notes_de_frais/views/validation_view.dart';

class ProcessingView extends StatefulWidget {
  final List<String> imagePaths;
  const ProcessingView({super.key, required this.imagePaths});

  @override
  State<ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<ProcessingView> {
  @override
  void initState() {
    super.initState();
    _processAndNavigate();
  }

  Future<void> _processAndNavigate() async {
    final controller = ExpenseController();
    final List<ExpenseModel> expenses = await controller.processImageBatch(widget.imagePaths);

    if (mounted) {
      if (expenses.length == 1) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ValidationView(expense: expenses.first, isInBatchMode: false),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BatchResultView(expenses: expenses),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Analyse en cours...',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}