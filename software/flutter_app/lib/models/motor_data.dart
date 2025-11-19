class MotorData {
  final double rpm;
  final double power;      // Em Watts
  final double efficiency; // Em %
  final double temperature; // Em Celsius (previsão para futuro sensor)
  final DateTime timestamp;

  MotorData({
    required this.rpm,
    required this.power,
    required this.efficiency,
    required this.temperature,
    required this.timestamp,
  });

  // Estado inicial "zerado"
  factory MotorData.zero() {
    return MotorData(
      rpm: 0.0,
      power: 0.0,
      efficiency: 0.0,
      temperature: 25.0, // Temp ambiente
      timestamp: DateTime.now(),
    );
  }
}
