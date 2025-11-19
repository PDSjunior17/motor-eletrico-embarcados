import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../models/motor_data.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final _controller = StreamController<MotorData>.broadcast();
  Stream<MotorData> get motorDataStream => _controller.stream;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription? _telemetrySubscription;
  
  // Simulação Host (Quando não há ESP32, o App do motorista gera os dados)
  Timer? _simulationTimer;
  bool _isHost = false;
  double _currentThrottle = 0.0;
  double _simulatedRPM = 0.0;

  void init() {
    // ESCUTA (Leitura): Todos leem a telemetria para atualizar o gráfico
    _telemetrySubscription = _dbRef.child('telemetry').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final motorData = MotorData(
          rpm: (data['rpm'] as num?)?.toDouble() ?? 0.0,
          power: (data['power'] as num?)?.toDouble() ?? 0.0,
          efficiency: (data['efficiency'] as num?)?.toDouble() ?? 0.0,
          temperature: (data['temperature'] as num?)?.toDouble() ?? 25.0,
          timestamp: DateTime.now(),
        );
        _controller.add(motorData);
      }
    });
  }

  // Ativa/Desativa o modo onde ESTE celular finge ser o ESP32
  void enableHostSimulation(bool enable) {
    if (_isHost == enable) return;
    _isHost = enable;

    if (enable) {
      _startSimulationLoop();
    } else {
      _simulationTimer?.cancel();
    }
  }

  void _startSimulationLoop() {
    _simulationTimer?.cancel();
    // Roda a cada 100ms para gerar dados suaves
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isHost) {
        timer.cancel();
        return;
      }

      // Física simples
      double targetRPM = _currentThrottle * 169.0;
      double diff = targetRPM - _simulatedRPM;
      _simulatedRPM += diff * 0.1; // Inércia

      // Envia para o Firebase (Para os espectadores verem)
      // Isso substitui o papel do ESP32
      _dbRef.child('telemetry').set({
        'rpm': _simulatedRPM,
        'power': (_simulatedRPM / 169.0) * 2.5,
        'efficiency': 85.0 + (Random().nextDouble() * 2),
        'timestamp': ServerValue.timestamp,
      });
    });
  }

  Future<void> setThrottle(double value) async {
    _currentThrottle = value.clamp(0.0, 1.0);
    
    // 1. Envia comando para o ESP32 (se ele existir)
    try {
      await _dbRef.child('control/throttle').set(_currentThrottle);
    } catch (e) {
      print("Erro: $e");
    }
    
    // O loop de simulação (acima) vai ler o _currentThrottle e atualizar o banco
    // se o modo Host estiver ativo.
  }

  void dispose() {
    _simulationTimer?.cancel();
    _telemetrySubscription?.cancel();
    _controller.close();
  }
}
