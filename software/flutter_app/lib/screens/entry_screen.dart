import 'package:flutter/material.dart';
import 'control_screen.dart';
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _showAvatarSelection = false;
  String? _selectedAvatar;
  String _userName = '';

  // Lista de avatares. Substituir pelos caminhos das imagens.
  // Ex: 'assets/avatars/fox.png', 'assets/avatars/panda.png', etc.
  final List<String> avatarOptions = [
    'fox', 'panda', 'giraffe', 'rabbit', 'bear', 'lion', 'cool'
  ];

  void _submitName() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        _userName = _nameController.text.trim();
        _showAvatarSelection = true;
      });
    }
  }

  void _navigateToControlScreen() {
    if (_userName.isNotEmpty && _selectedAvatar != null) {
      // Usamos pushReplacement para que o usuário não possa voltar para esta tela
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ControlScreen(
            userName: _userName,
            avatarIdentifier: _selectedAvatar!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _showAvatarSelection
                ? _buildAvatarSelection()
                : _buildNameInput(),
          ),
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      key: const ValueKey('nameInput'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Bem-vindo!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Para começar, digite seu nome abaixo.',
          style: TextStyle(fontSize: 18, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Seu Nome',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _submitName,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildAvatarSelection() {
    return Column(
      key: const ValueKey('avatarSelection'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Olá, $_userName!',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Escolha seu avatar para a sessão.',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 15.0,
          runSpacing: 15.0,
          alignment: WrapAlignment.center,
          children: avatarOptions.map((avatar) {
            final isSelected = _selectedAvatar == avatar;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatar = avatar;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                  border: Border.all(
                    color: isSelected ? Colors.blueAccent : Colors.transparent,
                    width: 3.0,
                  ),
                ),
                //child: Icon(Icons.pets, size: 40, color: isSelected ? Colors.blueAccent : Colors.grey), // Placeholder
                // --- PARA USAR IMAGENS, TROQUE O CHILD ACIMA POR ESTE: ---
                 child: Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Image.asset('assets/avatars/$avatar.png'),
                 ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          // O botão só fica ativo se um avatar for escolhido
          onPressed: _selectedAvatar != null ? _navigateToControlScreen : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAvatar != null ? Colors.green : Colors.grey,
          ),
          child: const Text('Iniciar Sessão'),
        ),
      ],
    );
  }
}
