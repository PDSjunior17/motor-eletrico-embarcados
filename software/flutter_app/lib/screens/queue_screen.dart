import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../models/motor_data.dart';
import '../services/data_service.dart';
import '../services/queue_service.dart';
import 'control_screen.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final QueueService _queueService = QueueService();
  final DataService _dataService = DataService();
  bool _hasNavigated = false; // Previne múltiplas navegações

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueueState>(
      stream: _queueService.queueStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Conectando à fila...'),
                ],
              ),
            ),
          );
        }

        final queueState = snapshot.data!;

        // Navegação segura para tela de controle
        if (queueState.myState == UserState.driving && !_hasNavigated) {
          _hasNavigated = true;
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && queueState.currentDriver != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ControlScreen(
                    userName: queueState.currentDriver!.name,
                    avatarIdentifier: queueState.currentDriver!.avatar,
                  ),
                ),
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          appBar: AppBar(
            title: const Text(
              "Sala de Espera",
              style: TextStyle(color: Colors.black87),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              // Botão para sair da fila
              IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                tooltip: 'Sair da Fila',
                onPressed: () {
                  _showExitDialog(context);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildCurrentDriverHeader(queueState),
              
              Expanded(
                flex: 2,
                child: _buildSpectatorView(),
              ),

              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Próximos na Fila",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${queueState.queue.length} aguardando",
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: queueState.queue.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum usuário na fila',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: queueState.queue.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final user = queueState.queue[index];
                                  final isMe = user.id == queueState.localUser?.id;
                                  final isFirst = index == 0;
                                  
                                  return ListTile(
                                    leading: Stack(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: AssetImage(
                                            'assets/avatars/${user.avatar}.png',
                                          ),
                                          backgroundColor: Colors.grey[200],
                                        ),
                                        if (isFirst)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.drive_eta,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(
                                      isMe ? "${user.name} (Você)" : user.name,
                                      style: TextStyle(
                                        fontWeight: isMe
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isMe ? Colors.blue : Colors.black87,
                                      ),
                                    ),
                                    subtitle: isFirst
                                        ? const Text(
                                            'Pilotando agora',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                    trailing: Text(
                                      "#${index + 1}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    tileColor: isMe
                                        ? Colors.blue.withOpacity(0.05)
                                        : null,
                                    shape: isMe
                                        ? RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          )
                                        : null,
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
    if (state.currentDriver == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[300],
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Aguardando primeiro piloto...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    final isUrgent = state.remainingSeconds < 10;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.redAccent : Colors.blueAccent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage(
              'assets/avatars/${state.currentDriver!.avatar}.png',
            ),
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PILOTANDO AGORA",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  state.currentDriver!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(
                isUrgent ? Icons.warning : Icons.timer,
                color: Colors.white,
              ),
              Text(
                "${state.remainingSeconds}s",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpectatorView() {
    return StreamBuilder<MotorData>(
      stream: _dataService.motorDataStream,
      initialData: MotorData.zero(),
      builder: (context, snapshot) {
        final data = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Monitor em Tempo Real',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: 169,
                        showLabels: false,
                        showTicks: false,
                        axisLineStyle: const AxisLineStyle(
                          thickness: 0.2,
                          thicknessUnit: GaugeSizeUnit.factor,
                        ),
                        pointers: <GaugePointer>[
                          NeedlePointer(
                            value: data.rpm,
                            needleEndWidth: 5,
                            animationDuration: 100,
                          ),
                        ],
                        annotations: <GaugeAnnotation>[
                          GaugeAnnotation(
                            widget: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  data.rpm.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'RPM',
                                  style: TextStyle(
                                    fontSize: 12,
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
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Fila?'),
        content: const Text(
          'Você perderá sua posição na fila. Deseja realmente sair?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _queueService.leave();
              Navigator.pop(context); // Fecha o dialog
              Navigator.pop(context); // Volta para entry screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hasNavigated = false;
    super.dispose();
  }
}
