import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:intl/intl.dart';

import '../widgets/metric_display.dart';
import '../widgets/throttle_lever.dart';
import '../services/data_service.dart';
import '../models/motor_data.dart';
import '../services/queue_service.dart';
import 'session_ended_screen.dart';

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
  double _throttleValue = 0.0; 
  final DataService _dataService = DataService();
  final QueueService _queueService = QueueService();
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _dataService.init();
  }

  @override
  Widget build(BuildContext context) {
    // Detecta tamanho da tela para responsividade
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return StreamBuilder<QueueState>(
      stream: _queueService.queueStream,
      builder: (context, queueSnapshot) {
        
        if (queueSnapshot.hasData && 
            queueSnapshot.data!.myState == UserState.finished && 
            !_hasNavigated) {
           _hasNavigated = true;
           Future.microtask(() {
             if (mounted) {
               Navigator.of(context).pushReplacement(
                 MaterialPageRoute(
                   builder: (context) => SessionEndedScreen(
                     user: queueSnapshot.data!.localUser! 
                   )
                 ),
               );
             }
           });
        }
        
        int timeLeft = queueSnapshot.hasData ? queueSnapshot.data!.remainingSeconds : 0;

        return StreamBuilder<MotorData>(
          stream: _dataService.motorDataStream,
          initialData: MotorData.zero(),
          builder: (context, motorSnapshot) {
            final data = motorSnapshot.data!;

            return Scaffold(
              backgroundColor: const Color(0xFFF5F5F7),
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
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
                   Padding(
                     padding: const EdgeInsets.only(right: 8.0),
                     child: IconButton(
                       icon: const Icon(Icons.logout, color: Colors.black54),
                       onPressed: () {
                         _queueService.leave();
                         Navigator.of(context).pop(); // Pode dar erro se popar a unica rota, mas o listener acima trata
                       },
                     ),
                   )
                ],
              ),
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10.0 : 20.0, 
                    vertical: 10
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- CONTROLES (Manete) ---
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "POTÊNCIA",
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: Colors.black45,
                              fontSize: isSmallScreen ? 10 : 14,
                              letterSpacing: 1.2
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: SizedBox(
                              // Reduz largura da manete em telas pequenas
                              width: isSmallScreen ? 60 : 80,
                              child: ThrottleLever(
                                value: _throttleValue,
                                onChanged: (val) {
                                  setState(() {
                                    _throttleValue = val;
                                  });
                                  _dataService.setThrottle(val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${(_throttleValue * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),

                      SizedBox(width: isSmallScreen ? 10 : 20),

                      // --- INSTRUMENTOS ---
                      Expanded(
                        child: Column(
                          children: [
                            _buildUserInfo(),
                            const SizedBox(height: 20),

                            // Métricas
                            Row(
                              children: [
                                Expanded(
                                  child: MetricDisplay(
                                    label: "Consumo",
                                    value: "${data.power.toStringAsFixed(2)} W",
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 8 : 12),
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
                            
                            // Velocímetro Responsivo
                            Expanded(
                              flex: 4,
                              child: _buildSpeedometer(data.rpm, isSmallScreen),
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
          Flexible(
            child: Text(
              widget.userName,
              overflow: TextOverflow.ellipsis, // Corta nome se for muito longo
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16, 
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedometer(double currentRPM, bool isSmall) {
    const double maxRPM = 169.0; 
    
    // Ajusta tamanho da fonte baseado na tela
    final double annotationSize = isSmall ? 30.0 : 45.0;
    final double labelSize = isSmall ? 10.0 : 14.0;

    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: maxRPM,
          startAngle: 140,
          endAngle: 40,
          showLabels: true,
          showTicks: true,
          // Labels menores
          axisLabelStyle: GaugeTextStyle(fontSize: labelSize),
          axisLineStyle: const AxisLineStyle(
            thickness: 20,
            cornerStyle: CornerStyle.bothCurve,
            color: Color(0xFFE0E0E0),
          ),
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
              needleEndWidth: isSmall ? 4 : 6,
              needleColor: const Color(0xFF2C3E50),
              knobStyle: KnobStyle(
                knobRadius: 0.08,
                color: const Color(0xFF2C3E50),
              ),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentRPM.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: annotationSize, // Fonte dinâmica
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    'RPM',
                    style: TextStyle(
                      fontSize: isSmall ? 10 : 14,
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
