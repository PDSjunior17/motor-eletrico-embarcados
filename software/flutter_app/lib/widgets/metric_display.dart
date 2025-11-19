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
    // Pega a largura da tela para ajustes finos
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : 10, 
        horizontal: isSmallScreen ? 8 : 16
      ),
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
          // Rótulo (Título)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isSmallScreen ? 9 : 11, // Fonte menor no celular
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Valor
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: isSmallScreen ? 16 : 18, // Fonte adaptativa
                fontWeight: FontWeight.w800,
                fontFamily: 'Monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
