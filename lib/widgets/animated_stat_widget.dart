import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedStatWidget extends StatelessWidget {
  final String title;
  final double beginValue;
  final double endValue;
  final IconData icon;
  final Color color;
  final bool isCurrency;
  final Duration duration;

  const AnimatedStatWidget({
    super.key,
    required this.title,
    required this.beginValue,
    required this.endValue,
    required this.icon,
    required this.color,
    this.isCurrency = false,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: beginValue, end: endValue),
          duration: duration,
          curve: Curves.easeOut,
          builder: (context, value, child) {
            String displayedValue = isCurrency
                ? currencyFormat.format(value)
                : value.toStringAsFixed(0);
            return Text(
              displayedValue,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
      ],
    );
  }
}