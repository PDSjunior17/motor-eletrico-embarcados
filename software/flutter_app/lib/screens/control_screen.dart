import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../widgets/metric_display.dart';

class ControlScreen extends StatefulWidget {
  final String userName;
  final String avatarIdentifier;

  const ControlScreen({
    super.key,
    required this.userName,
    required this.avatarIdentifier,
  });

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  double _currentRPM = 0;
  final double _maxRPM = 169.0; // Velocidade máxima do motor GA25-370 [cite: 52, 44]
  Timer? _timer;

  // Métricas geradas aleatoriamente
  double _consumedPower = 0.0;
  double _efficiency = 0.0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateMetrics() {
    if (_currentRPM > 0) {
      // Potência: aumenta com o RPM, com uma pequena variação.
      // A 6V e ~0.45A, a potência máxima é de 2.7W. [cite: 52]
      _consumedPower = (_currentRPM / _maxRPM) * 2.5 + (Random().nextDouble() * 0.2);

      // Eficiência: geralmente maior em rotações médias. Usamos uma curva senoidal.
      // O valor máximo será ~95% e o mínimo ~83%.
      _efficiency = 85.0 + (10 * sin((_currentRPM / _maxRPM) * pi)) - (Random().nextDouble() * 2);
    } else {
      _consumedPower = 0.0;
      _efficiency = 0.0;
    }
  }

  void _startAccelerating() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_currentRPM < _maxRPM) {
          _currentRPM += 1.5;
        } else {
          _currentRPM = _maxRPM;
        }
        _updateMetrics();
      });
    });
  }

  void _stopAccelerating() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        if (_currentRPM > 0) {
          _currentRPM -= 1.8;
        } else {
          _currentRPM = 0;
          _timer?.cancel();
        }
        _updateMetrics();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUserInfo(),
              _buildSpeedometerAndMetrics(),
              _buildControlButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blueAccent.withOpacity(0.2),
          //child: Icon(Icons.pets, size: 28, color: Colors.blueAccent), // Placeholder
          // --- PARA USAR IMAGENS, TROQUE O CHILD ACIMA POR ESTE: ---
          backgroundImage: AssetImage('assets/avatars/${widget.avatarIdentifier}.png'),
        ),
        const SizedBox(width: 12),
        Text(
          widget.userName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSpeedometerAndMetrics() {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Métrica Esquerda
          Positioned(
            left: 0,
            top: 20,
            child: MetricDisplay(
              label: "Potência Consumida",
              value: "${_consumedPower.toStringAsFixed(2)} W", // Métrica do projeto [cite: 127]
            ),
          ),
          // Métrica Direita
          Positioned(
            right: 0,
            top: 20,
            child: MetricDisplay(
              label: "Eficiência",
              value: "${_efficiency.toStringAsFixed(1)} %", // Métrica do projeto [cite: 128]
            ),
          ),
          // Velocímetro
          Center(
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: _maxRPM + 11, // Um pouco a mais para visualização
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.15,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  ranges: <GaugeRange>[
                    GaugeRange(startValue: 0, endValue: 60, color: Colors.green, startWidth: 0.15, endWidth: 0.15, sizeUnit: GaugeSizeUnit.factor),
                    GaugeRange(startValue: 60, endValue: 120, color: Colors.orange, startWidth: 0.15, endWidth: 0.15, sizeUnit: GaugeSizeUnit.factor),
                    GaugeRange(startValue: 120, endValue: _maxRPM + 11, color: Colors.red, startWidth: 0.15, endWidth: 0.15, sizeUnit: GaugeSizeUnit.factor),
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(
                      value: _currentRPM,
                      enableAnimation: true,
                      animationDuration: 100,
                      needleStartWidth: 1,
                      needleEndWidth: 5,
                      knobStyle: KnobStyle(knobRadius: 0.08, sizeUnit: GaugeSizeUnit.factor),
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text(
                            'RPM ATUAL', // Métrica do projeto [cite: 103, 126]
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _currentRPM.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      angle: 90,
                      positionFactor: 0.6,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTapDown: (_) => _startAccelerating(),
        onTapUp: (_) => _stopAccelerating(),
        onTapCancel: () => _stopAccelerating(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 80),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            "Acelerar",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
