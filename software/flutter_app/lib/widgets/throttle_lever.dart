import 'package:flutter/material.dart';

class ThrottleLever extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const ThrottleLever({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ThrottleLever> createState() => _ThrottleLeverState();
}

class _ThrottleLeverState extends State<ThrottleLever> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[400]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Marcador de 100%
          _buildMark("100", Colors.red),
          
          Expanded(
            child: RotatedBox(
              quarterTurns: 3, // Rotaciona o slider para ficar vertical
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 20,
                  activeTrackColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Colors.blue[800],
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
                  overlayColor: Colors.blue.withOpacity(0.2),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
                ),
                child: Slider(
                  value: widget.value,
                  min: 0.0,
                  max: 1.0,
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ),
          
          // Marcador de 0%
          _buildMark("STOP", Colors.grey),
        ],
      ),
    );
  }

  Widget _buildMark(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
