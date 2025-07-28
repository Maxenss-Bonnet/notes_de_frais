import 'package:flutter/material.dart';
import 'package:notes_de_frais/models/expense_model.dart';

class ConfidenceReminderWidget extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onRetakePhoto;

  const ConfidenceReminderWidget({
    super.key,
    required this.expense,
    this.onRetakePhoto,
  });

  // Vérifie si au moins un champ a une confiance < 80% (seuil cohérent avec les indicateurs visuels)
  bool _hasLowConfidence() {
    final confidences = [
      expense.amountConfidence,
      expense.dateConfidence,
      expense.companyConfidence,
      expense.vatConfidence,
      expense.categoryConfidence,
      expense.normalizedMerchantNameConfidence,
    ];

    // Debug: Afficher les valeurs de confiance
    // Note: Pour désactiver en production, remplacer debugPrint par
    // if (kDebugMode) debugPrint(...)
    debugPrint('=== CONFIDENCE VALUES ===');
    debugPrint('Amount: ${expense.amountConfidence}');
    debugPrint('Date: ${expense.dateConfidence}');
    debugPrint('Company: ${expense.companyConfidence}');
    debugPrint('VAT: ${expense.vatConfidence}');
    debugPrint('Category: ${expense.categoryConfidence}');
    debugPrint(
        'Normalized Merchant: ${expense.normalizedMerchantNameConfidence}');

    // Utiliser un seuil de 0.799 pour éviter les problèmes d'arrondi flottant
    // et être cohérent avec les indicateurs visuels (vert >= 0.8)
    const double confidenceThreshold = 0.799;

    bool hasLowConfidence = confidences.any(
        (confidence) => confidence != null && confidence < confidenceThreshold);

    debugPrint(
        'Has low confidence: $hasLowConfidence (threshold: $confidenceThreshold)');
    debugPrint('=========================');

    return hasLowConfidence;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLowConfidence()) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Certaines données ont été extraites avec une confiance limitée. Considérez reprendre la photo pour une meilleure précision.',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
              ),
            ),
          ),
          if (onRetakePhoto != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetakePhoto,
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Reprendre',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
