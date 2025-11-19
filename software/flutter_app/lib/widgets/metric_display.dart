import 'package:flutter/material.dart';

class MetricDisplay extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const MetricDisplay({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontSize: 18, // Levemente reduzido para acomodar decimais
              fontWeight: FontWeight.w800,
              fontFamily: 'Monospace', // Fonte monoespaçada ajuda a evitar "pulos" nos números
            ),
          ),
        ],
      ),
    );
  }
}
