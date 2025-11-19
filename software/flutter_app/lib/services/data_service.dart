import 'dart:async';
import 'dart:math';
import '../models/motor_data.dart';

class DataService {
  // Singleton: Garante que só existe UM serviço de dados rodando no app inteiro
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Stream: É como uma "rádio". Quem sintonizar (ouvir) recebe dados novos o tempo todo.
  final _controller = StreamController<MotorData>.broadcast();
  Stream<MotorData> get motorDataStream => _controller.stream;

  // Variáveis de Estado Interno (Simulação)
  double _targetRPM = 0.0;
  double _currentRPM = 0.0;
  final double _maxRPM = 169.0;
  Timer? _simulationTimer;

  // Inicia o serviço (simulado ou real)
  void init() {
    _startSimulation();
  }

  // Envia comando de velocidade (0.0 a 1.0)
  // No futuro, isso escreverá no Firebase
  void setThrottle(double value) {
    // Clamp garante que nunca passe de 0 ou 1
    double safeValue = value.clamp(0.0, 1.0);
    _targetRPM = safeValue * _maxRPM;
  }

  void dispose() {
    _simulationTimer?.cancel();
    _controller.close();
  }

  // --- SIMULAÇÃO FÍSICA (MOCK) ---
  // Quando tivermos o ESP32, apagaremos essa função e usaremos dados reais.
  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      // 1. Física de Inércia
      double diff = _targetRPM - _currentRPM;
      // Se a diferença for pequena, "cola" no valor alvo para evitar oscilação
      if (diff.abs() < 0.5) {
        _currentRPM = _targetRPM;
      } else {
        // Fator 0.15 = suavidade do motor ganhando giro
        _currentRPM += diff * 0.15;
      }

      // 2. Cálculo de Métricas (Física Simulada)
      double loadFactor = _currentRPM / _maxRPM; // 0.0 a 1.0
      
      // Potência: Sobe exponencialmente com a velocidade + ruído elétrico
      double power = 0.0;
      if (_currentRPM > 1) {
        power = (loadFactor * 2.5) + (Random().nextDouble() * 0.1);
      }

      // Eficiência: Curva senoidal (melhor em médias rotações)
      double efficiency = 0.0;
      if (_currentRPM > 1) {
        efficiency = 85.0 + (10 * sin(loadFactor * pi)) - (Random().nextDouble() * 1.5);
      }

      // 3. Emite o dado novo para quem estiver ouvindo (a tela)
      _controller.add(MotorData(
        rpm: _currentRPM,
        power: power,
        efficiency: efficiency,
        temperature: 35.0 + (loadFactor * 10), // Simula aquecimento
        timestamp: DateTime.now(),
      ));
    });
  }
}
