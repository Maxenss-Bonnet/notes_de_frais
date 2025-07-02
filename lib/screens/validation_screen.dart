import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notes_de_frais/services/ocr_service.dart';

class ValidationScreen extends StatefulWidget {
  final String imagePath;

  const ValidationScreen({super.key, required this.imagePath});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;

  Future<void> _onValidate() async {
    setState(() {
      _isProcessing = true;
    });

    final extractedText = await _ocrService.getTextFromImage(widget.imagePath);

    setState(() {
      _isProcessing = false;
    });

    // Pour l'instant, nous allons juste afficher le texte dans une boîte de dialogue
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Texte extrait'),
        content: SingleChildScrollView(
          child: Text(extractedText.isEmpty ? "Aucun texte n'a pu être extrait." : extractedText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Valider la photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.file(File(widget.imagePath)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Reprendre'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isProcessing ? null : _onValidate,
                  icon: _isProcessing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.check_circle),
                  label: Text(_isProcessing ? 'Analyse...' : 'Valider'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}