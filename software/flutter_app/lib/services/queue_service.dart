import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import 'data_service.dart';

enum UserState { waiting, driving, finished }

class QueueState {
  final UserModel? currentDriver;
  final List<UserModel> queue;
  final int remainingSeconds;
  final UserState myState;
  final UserModel? localUser;

  QueueState({
    required this.currentDriver,
    required this.queue,
    required this.remainingSeconds,
    required this.myState,
    required this.localUser,
  });
}

class QueueService {
  static final QueueService _instance = QueueService._internal();
  factory QueueService() => _instance;
  QueueService._internal();

  final _controller = StreamController<QueueState>.broadcast();
  Stream<QueueState> get queueStream => _controller.stream;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final DataService _dataService = DataService();

  UserModel? _localUser;
  List<UserModel> _globalQueue = [];
  
  // Timer local apenas para quem está pilotando
  Timer? _driverTimer;
  int _localSecondsCounter = 0;

  // Configuração de Tempo
  static const int _baseTimeSeconds = 60;
  static const int _minTimeSeconds = 15;

  StreamSubscription? _queueSubscription;

  void init(UserModel me) {
    _localUser = me;
    
    // 1. Entrar na Fila Global (Escreve no Firebase)
    // Usamos o ID como chave para facilitar a remoção
    final userRef = _dbRef.child('queue/${me.id}');
    
    userRef.set({
      'name': me.name,
      'avatar': me.avatar,
      'joinedAt': ServerValue.timestamp, // Marca o horário do servidor
    });

    // 2. "Kill Switch": Se a internet cair ou fechar a aba, remove da fila
    userRef.onDisconnect().remove();

    // 3. Começar a ouvir as mudanças na fila
    _listenToQueue();
  }

  void _listenToQueue() {
    _queueSubscription?.cancel();
    
    // Escuta a lista inteira de 'queue'
    _queueSubscription = _dbRef.child('queue').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      List<UserModel> loadedQueue = [];

      if (data != null) {
        data.forEach((key, value) {
          // Recupera o timestamp para ordenar corretamente
          final joinedAt = value['joinedAt'] is int ? value['joinedAt'] : 0;
          
          loadedQueue.add(UserModel(
            id: key,
            name: value['name'],
            avatar: value['avatar'],
            // Podemos adicionar um campo timestamp no UserModel se quisermos ordenação precisa,
            // mas por enquanto a ordem de inserção/chave resolve na maioria dos casos simples.
          ));
        });
      }

      // ORDENAÇÃO: É crucial que todos concordem quem é o primeiro.
      // Como os IDs gerados têm timestamp, a ordem alfabética dos IDs serve como ordem cronológica
      loadedQueue.sort((a, b) => a.id.compareTo(b.id));
      
      _globalQueue = loadedQueue;
      _checkMyStatus();
    });
  }

  void _checkMyStatus() {
    if (_localUser == null) return;

    UserModel? driver;
    UserState state = UserState.waiting;
    int timeLimit = _calculateTimeLimit();

    if (_globalQueue.isNotEmpty) {
      driver = _globalQueue.first; // O primeiro da fila é o piloto

      // Sou eu?
      if (driver.id == _localUser!.id) {
        state = UserState.driving;
        _startDrivingTimer(timeLimit);
      } else {
        // Se não sou eu, paro meu timer se estiver rodando
        _stopDrivingTimer();
        // Zera a manete para garantir
        if (_globalQueue.any((u) => u.id == _localUser!.id)) {
           state = UserState.waiting;
        } else {
           state = UserState.finished;
        }
      }
    } else {
      // Fila vazia
      state = UserState.finished;
    }

    // Se sou espectador, mostro o tempo total estimado ou um placeholder
    // (Em um sistema real distribuído, o tempo restante idealmente viria do servidor,
    // aqui simplificamos para cada cliente saber o tempo total da vez)
    int displayTime = (_driverTimer != null && state == UserState.driving) 
        ? _localSecondsCounter 
        : timeLimit;

    _controller.add(QueueState(
      currentDriver: driver,
      queue: _globalQueue,
      remainingSeconds: displayTime,
      myState: state,
      localUser: _localUser,
    ));
  }

  int _calculateTimeLimit() {
    int count = _globalQueue.length;
    // Evita divisão por zero
    if (count == 0) return _baseTimeSeconds;
    int time = (_baseTimeSeconds / count).round();
    return max(time, _minTimeSeconds);
  }

  // Timer roda APENAS no cliente que é o motorista atual
  void _startDrivingTimer(int maxSeconds) {
    if (_driverTimer != null && _driverTimer!.isActive) return; // Já está rodando

    _localSecondsCounter = maxSeconds;
    
    _driverTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _localSecondsCounter--;
      
      // Atualiza a UI localmente
      _controller.add(QueueState(
        currentDriver: _globalQueue.isNotEmpty ? _globalQueue.first : null,
        queue: _globalQueue,
        remainingSeconds: _localSecondsCounter,
        myState: UserState.driving,
        localUser: _localUser,
      ));

      if (_localSecondsCounter <= 0) {
        leave(); // Tempo acabou, sai da fila
      }
    });
  }

  void _stopDrivingTimer() {
    _driverTimer?.cancel();
    _driverTimer = null;
  }

  void leave() {
    _stopDrivingTimer();
    _dataService.setThrottle(0.0); // Para o motor antes de sair
    
    if (_localUser != null) {
      // Remove do Firebase. Isso dispara o evento onValue para TODOS os usuários,
      // fazendo a fila andar automaticamente.
      _dbRef.child('queue/${_localUser!.id}').remove();
    }
  }
  
  void dispose() {
    _stopDrivingTimer();
    _queueSubscription?.cancel();
    _controller.close();
  }
}
