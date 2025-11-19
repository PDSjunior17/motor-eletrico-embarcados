import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/queue_service.dart';
import 'queue_screen.dart';
import 'entry_screen.dart';

class SessionEndedScreen extends StatelessWidget {
  final UserModel user;

  const SessionEndedScreen({super.key, required this.user});

  void _playAgain(BuildContext context) {
    // Reinserir na fila
    QueueService().init(user);
    
    // Voltar para a sala de espera
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const QueueScreen()),
    );
  }

  void _exit(BuildContext context) {
    // Sai do sistema de fila completamente
    QueueService().leave();
    
    // Volta para a tela de login (EntryScreen)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const EntryScreen()),
      (route) => false, // Remove todo o histórico de navegação anterior
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.timer_off_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              "Sessão Finalizada",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Obrigado por testar o protótipo, ${user.name}!\nOutras pessoas estão esperando na fila.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 48),
            
            // Botão Jogar Novamente
            ElevatedButton(
              onPressed: () => _playAgain(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Entrar na Fila Novamente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            
            const SizedBox(height: 16),
            
            // Botão Sair
            OutlinedButton(
              onPressed: () => _exit(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Sair / Logout", style: TextStyle(fontSize: 18, color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
