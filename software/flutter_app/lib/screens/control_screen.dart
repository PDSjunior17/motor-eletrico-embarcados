import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:intl/intl.dart';

// Widgets
import '../widgets/metric_display.dart';
import '../widgets/throttle_lever.dart';

// Services & Models
import '../services/data_service.dart';
import '../models/motor_data.dart';
import '../services/queue_service.dart';

// Screens
import 'session_ended_screen.dart'; // Importante para a navegação final

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
  // Estado visual da manete (0.0 a 1.0)
  double _throttleValue = 0.0; 
  
  // Serviços
  final DataService _dataService = DataService();
  final QueueService _queueService = QueueService();

  // Controle de navegação para evitar múltiplas chamadas
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Garante que o serviço de dados esteja rodando
    _dataService.init();
  }

  @override
  Widget build(BuildContext context) {
    // 1. StreamBuilder EXTERNO: Monitora a Fila e o Tempo Restante
    return StreamBuilder<QueueState>(
      stream: _queueService.queueStream,
      builder: (context, queueSnapshot) {
        
        // --- LÓGICA DE SAÍDA (CORREÇÃO DA TELA PRETA) ---
        // Se o estado mudou para 'finished', navegamos para a tela de fim de sessão
        if (queueSnapshot.hasData && 
            queueSnapshot.data!.myState == UserState.finished && 
            !_hasNavigated) {
           
           // Marca como navegado para não chamar duas vezes
           _hasNavigated = true;
           
           // Agenda a navegação para logo após o build atual
           Future.microtask(() {
             if (mounted) {
               Navigator.of(context).pushReplacement(
                 MaterialPageRoute(
                   builder: (context) => SessionEndedScreen(
                     // Passamos o usuário atual para personalizar a mensagem de tchau
                     user: queueSnapshot.data!.localUser! 
                   )
                 ),
               );
             }
           });
        }
        
        // Pega o tempo restante (ou 0 se ainda não carregou)
        int timeLeft = queueSnapshot.hasData ? queueSnapshot.data!.remainingSeconds : 0;

        // 2. StreamBuilder INTERNO: Monitora os dados do Motor (RPM, etc)
        return StreamBuilder<MotorData>(
          stream: _dataService.motorDataStream,
          initialData: MotorData.zero(),
          builder: (context, motorSnapshot) {
            final data = motorSnapshot.data!;

            return Scaffold(
              backgroundColor: const Color(0xFFF5F5F7),
              appBar: AppBar(
                automaticallyImplyLeading: false, // Remove botão de voltar padrão
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    // Fica vermelho quando faltam menos de 10 segundos
                    color: timeLeft < 10 ? Colors.redAccent : Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "TEMPO: ${timeLeft}s", 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
                actions: [
                   // Botão de Sair / Desistir da vez
                   Padding(
                     padding: const EdgeInsets.only(right: 8.0),
                     child: IconButton(
                       icon: const Icon(Icons.logout, color: Colors.black54),
                       tooltip: "Sair da Sessão",
                       onPressed: () {
                         _queueService.leave(); // Avisa o serviço que sai
                         // A navegação será tratada automaticamente pelo listener acima (UserState.finished)
                       },
                     ),
                   )
                ],
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- COLUNA DA ESQUERDA: CONTROLES (MANETE) ---
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "POTÊNCIA",
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: Colors.black45,
                              letterSpacing: 1.2
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ThrottleLever(
                              value: _throttleValue,
                              onChanged: (val) {
                                setState(() {
                                  _throttleValue = val;
                                });
                                // Envia o comando para o serviço de dados (Simulado ou Real)
                                _dataService.setThrottle(val);
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${(_throttleValue * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),

                      const SizedBox(width: 20),

                      // --- COLUNA DA DIREITA: INSTRUMENTOS E MÉTRICAS ---
                      Expanded(
                        child: Column(
                          children: [
                            // Cabeçalho do usuário atual
                            _buildUserInfo(),
                            const SizedBox(height: 20),

                            // Métricas (Potência e Eficiência)
                            Row(
                              children: [
                                Expanded(
                                  child: MetricDisplay(
                                    label: "Consumo",
                                    value: "${data.power.toStringAsFixed(2)} W",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: MetricDisplay(
                                    label: "Eficiência",
                                    value: "${data.efficiency.toStringAsFixed(1)} %",
                                    valueColor: data.efficiency > 90 ? Colors.green : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            
                            const Spacer(),
                            
                            // Velocímetro Grande
                            SizedBox(
                              height: 280,
                              child: _buildSpeedometer(data.rpm),
                            ),
                            
                            const Spacer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: AssetImage('assets/avatars/${widget.avatarIdentifier}.png'),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 10),
          Text(
            widget.userName,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16, 
              fontWeight: FontWeight.w600
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedometer(double currentRPM) {
    const double maxRPM = 169.0; 

    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: maxRPM,
          startAngle: 140,
          endAngle: 40,
          showLabels: true,
          showTicks: true,
          axisLineStyle: const AxisLineStyle(
            thickness: 20,
            cornerStyle: CornerStyle.bothCurve,
            color: Color(0xFFE0E0E0),
          ),
          // Formatação para números inteiros no eixo, para limpar o visual
          numberFormat: NumberFormat("##0"), 
          ranges: <GaugeRange>[
            GaugeRange(startValue: 0, endValue: maxRPM * 0.7, color: Colors.greenAccent, startWidth: 20, endWidth: 20),
            GaugeRange(startValue: maxRPM * 0.7, endValue: maxRPM * 0.9, color: Colors.orangeAccent, startWidth: 20, endWidth: 20),
            GaugeRange(startValue: maxRPM * 0.9, endValue: maxRPM, color: Colors.redAccent, startWidth: 20, endWidth: 20),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: currentRPM,
              enableAnimation: true,
              animationType: AnimationType.easeOutBack,
              animationDuration: 100,
              needleStartWidth: 1,
              needleEndWidth: 6,
              needleColor: const Color(0xFF2C3E50),
              knobStyle: const KnobStyle(
                knobRadius: 0.08,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentRPM.toStringAsFixed(1), // Casas decimais aqui
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const Text(
                    'RPM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              angle: 90,
              positionFactor: 0.5,
            ),
          ],
        ),
      ],
    );
  }
}
