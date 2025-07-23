import 'package:flutter/material.dart';
import 'package:notes_de_frais/views/advanced_settings_view.dart';

class PinCodeView extends StatefulWidget {
  const PinCodeView({super.key});

  @override
  State<PinCodeView> createState() => _PinCodeViewState();
}

class _PinCodeViewState extends State<PinCodeView> {
  String _enteredPin = '';
  final String _correctPin = '2912';
  String _feedbackMessage = '';

  void _onNumberPressed(String number) {
    if (_enteredPin.length >= 4) return;

    final newPin = _enteredPin + number;
    setState(() {
      _enteredPin = newPin;
      _feedbackMessage = '';
    });

    if (newPin.length == 4) {
      // Ajout d'un court délai pour laisser l'interface afficher le 4ème point
      // et éviter tout conflit d'état avant la navigation.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _verifyPin();
        }
      });
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _feedbackMessage = '';
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == _correctPin) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdvancedSettingsView()),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _feedbackMessage = 'Code incorrect. Veuillez réessayer.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès sécurisé'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Veuillez entrer le code PIN',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          _buildPinDots(),
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: _feedbackMessage.isNotEmpty ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              _feedbackMessage,
              style: TextStyle(
                color: _feedbackMessage.startsWith('Code correct')
                    ? Colors.green
                    : Colors.red,
                fontSize: 16,
              ),
            ),
          ),
          const Spacer(),
          _buildNumericKeypad(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.length
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('1'),
            _buildNumberButton('2'),
            _buildNumberButton('3'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('4'),
            _buildNumberButton('5'),
            _buildNumberButton('6'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('7'),
            _buildNumberButton('8'),
            _buildNumberButton('9'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80, height: 80),
            _buildNumberButton('0'),
            SizedBox(
              width: 80,
              height: 80,
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined, size: 30),
                onPressed: _onDeletePressed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.grey.shade200,
        ),
        onPressed: () => _onNumberPressed(number),
        child: Text(
          number,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}