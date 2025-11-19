import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:intl/intl.dart';

import '../models/motor_data.dart';
import '../services/data_service.dart';
import '../services/queue_service.dart';
import 'control_screen.dart'; // Para navegar quando for a vez

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final QueueService _queueService = QueueService();
  final DataService _dataService = DataService(); // Para ver o velocímetro como espectador

  @override
  void initState() {
    super.initState();
    // DataService já deve estar iniciado
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueueState>(
      stream: _queueService.queueStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final queueState = snapshot.data!;

        // Se chegou a minha vez, navega AUTOMATICAMENTE para o Controle
        if (queueState.myState == UserState.driving) {
          // Usamos Future.microtask para evitar erro de build durante renderização
          Future.microtask(() {
             Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => ControlScreen(
                userName: queueState.currentDriver!.name,
                avatarIdentifier: queueState.currentDriver!.avatar,
              )),
            );
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          appBar: AppBar(
            title: const Text("Sala de Espera", style: TextStyle(color: Colors.black87)),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: Column(
            children: [
              // 1. Cabeçalho: Quem está pilotando agora?
              _buildCurrentDriverHeader(queueState),
              
              // 2. Monitoramento (Spectator Mode)
              Expanded(
                flex: 2,
                child: _buildSpectatorView(),
              ),

              // 3. A Fila
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Próximos na Fila", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                              child: Text("${queueState.queue.length} aguardando", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: queueState.queue.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final user = queueState.queue[index];
                            final isMe = user.id == queueState.localUserId;
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage('assets/avatars/${user.avatar}.png'),
                                backgroundColor: Colors.grey[200],
                              ),
                              title: Text(
                                isMe ? "${user.name} (Você)" : user.name,
                                style: TextStyle(
                                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                  color: isMe ? Colors.blue : Colors.black87,
                                ),
                              ),
                              trailing: Text("#${index + 1}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                              tileColor: isMe ? Colors.blue.withOpacity(0.05) : null,
                              shape: isMe ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)) : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentDriverHeader(QueueState state) {
    if (state.currentDriver == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blueAccent,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/avatars/${state.currentDriver!.avatar}.png'),
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PILOTANDO AGORA", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
                Text(state.currentDriver!.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.timer, color: Colors.white),
              Text("${state.remainingSeconds}s", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSpectatorView() {
    // Reutiliza o DataService para mostrar o velocímetro sem controle
    return StreamBuilder<MotorData>(
      stream: _dataService.motorDataStream,
      initialData: MotorData.zero(),
      builder: (context, snapshot) {
        final data = snapshot.data!;
        // Simplificação do velocímetro para o modo espectador (menor)
        return Center(
          child: SizedBox(
            height: 180,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0, maximum: 169, showLabels: false, showTicks: false,
                  axisLineStyle: const AxisLineStyle(thickness: 0.2, thicknessUnit: GaugeSizeUnit.factor),
                  pointers: <GaugePointer>[
                    NeedlePointer(value: data.rpm, needleEndWidth: 5, animationDuration: 100)
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Text("${data.rpm.toStringAsFixed(0)} RPM", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      angle: 90, positionFactor: 0.5
                    )
                  ]
                )
              ],
            ),
          ),
        );
      }
    );
  }
}
