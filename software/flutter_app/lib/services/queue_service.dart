import 'dart:async';
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
  
  static const int _sessionDuration = 45;

  StreamSubscription? _queueSubscription;
  Timer? _timeUpdateTimer;
  bool _hasSetStartTime = false;

  // Cache dos startTimes (Esta é a variável que o Timer lê)
  final Map<String, int?> _cachedStartTimes = {}; 

  void init(UserModel me) {
    _localUser = me;
    _hasSetStartTime = false;
    
    final userRef = _dbRef.child('queue/${me.id}');
    
    // Define prioridade para garantir ordem correta
    userRef.set({
      'name': me.name,
      'avatar': me.avatar,
      'joinedAt': ServerValue.timestamp,
      '.priority': ServerValue.timestamp,
    });

    userRef.onDisconnect().remove();
    _listenToQueue();
    
    // Timer para atualizar UI a cada segundo
    _startTimeUpdateTimer();
  }

  void _startTimeUpdateTimer() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // O Timer usa _cachedStartTimes para calcular a diferença de tempo
      if (_localUser != null && _globalQueue.isNotEmpty) {
        _processCurrentQueueState();
      }
    });
  }

  void _processCurrentQueueState() {
    // Chama a checagem usando os dados cacheados globais
    _checkMyStatus(_cachedStartTimes);
  }

  void _listenToQueue() {
    _queueSubscription?.cancel();
    
    // Ordena por prioridade (timestamp de entrada)
    _queueSubscription = _dbRef
        .child('queue')
        .orderByPriority()
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      List<UserModel> loadedQueue = [];
      
      // --- CORREÇÃO AQUI ---
      // Limpamos o cache global antes de preencher com dados novos do Firebase
      _cachedStartTimes.clear();

      if (data != null && data is Map) {
        // Converte para Map<String, dynamic> para facilitar manipulação
        final queueMap = Map<String, dynamic>.from(data as Map);
        
        // Ordena as chaves pela prioridade (joinedAt)
        final sortedKeys = queueMap.keys.toList()..sort((a, b) {
          final aPriority = queueMap[a] is Map && (queueMap[a] as Map).containsKey('joinedAt')
              ? (queueMap[a] as Map)['joinedAt'] as int
              : 0;
          final bPriority = queueMap[b] is Map && (queueMap[b] as Map).containsKey('joinedAt')
              ? (queueMap[b] as Map)['joinedAt'] as int
              : 0;
          return aPriority.compareTo(bPriority);
        });
        
        for (var key in sortedKeys) {
          final value = queueMap[key] as Map;
          
          final user = UserModel(
            id: key,
            name: value['name']?.toString() ?? 'Unknown',
            avatar: value['avatar']?.toString() ?? 'fox',
          );
          loadedQueue.add(user);
          
          // --- CORREÇÃO AQUI ---
          // Atualizamos a variável GLOBAL, não uma local
          if (value['startedAt'] != null) {
            _cachedStartTimes[key] = value['startedAt'] as int;
          }
        }
      }

      _globalQueue = loadedQueue;
      // Passamos o cache global atualizado
      _checkMyStatus(_cachedStartTimes);
    });
  }

  void _checkMyStatus(Map<String, int?> startTimes) {
    if (_localUser == null) return;

    UserModel? driver;
    UserState state = UserState.waiting;
    int timeLeft = _sessionDuration;

    if (_globalQueue.isEmpty) {
      state = UserState.finished;
      _dataService.enableHostSimulation(false);
      _emitState(driver, state, timeLeft);
      return;
    }

    driver = _globalQueue.first;
    
    // Verifica se ainda estou na fila
    bool amInQueue = _globalQueue.any((u) => u.id == _localUser!.id);
    if (!amInQueue) {
      state = UserState.finished;
      _dataService.enableHostSimulation(false);
      _emitState(driver, state, timeLeft);
      return;
    }

    // Sou o motorista?
    if (driver.id == _localUser!.id) {
      state = UserState.driving;
      int? myStartTime = startTimes[driver.id];
      
      if (myStartTime == null && !_hasSetStartTime) {
        // Primeira vez como motorista - registra início no Firebase
        _hasSetStartTime = true;
        _dbRef.child('queue/${driver.id}').update({
          'startedAt': ServerValue.timestamp
        }).then((_) {
          print('StartedAt registrado com sucesso');
        }).catchError((error) {
          print('Erro ao registrar startedAt: $error');
          _hasSetStartTime = false;
        });
        timeLeft = _sessionDuration;
      } else if (myStartTime != null) {
        // Se já tem horário de início, calcula o tempo restante
        timeLeft = _calculateTimeLeft(myStartTime);
        
        if (timeLeft <= 0) {
          print('Tempo esgotado - saindo automaticamente');
          leave();
          return;
        }
      }
      
      _dataService.enableHostSimulation(true);
    } else {
      // Sou espectador
      state = UserState.waiting;
      _dataService.enableHostSimulation(false);
      
      int? driverStartTime = startTimes[driver.id];
      if (driverStartTime != null) {
        timeLeft = _calculateTimeLeft(driverStartTime);
      } else {
        timeLeft = _sessionDuration;
      }
    }

    _emitState(driver, state, timeLeft);
  }

  void _emitState(UserModel? driver, UserState state, int timeLeft) {
    _controller.add(QueueState(
      currentDriver: driver,
      queue: _globalQueue,
      remainingSeconds: timeLeft > 0 ? timeLeft : 0,
      myState: state,
      localUser: _localUser,
    ));
  }

  int _calculateTimeLeft(int startTimeMillis) {
    int endTime = startTimeMillis + (_sessionDuration * 1000);
    // Ajuste importante: Adiciona um pequeno buffer de sincronização se necessário
    // mas geralmente a diferença entre clocks não é crítica para este tipo de app
    int now = DateTime.now().millisecondsSinceEpoch;
    int remaining = ((endTime - now) / 1000).round();
    return remaining;
  }

  void leave() {
    _hasSetStartTime = false;
    _dataService.enableHostSimulation(false);
    _dataService.setThrottle(0.0);
    
    if (_localUser != null) {
      _dbRef.child('queue/${_localUser!.id}').remove().then((_) {
        print('Usuário removido da fila com sucesso');
      }).catchError((error) {
        print('Erro ao remover da fila: $error');
      });
    }
  }
  
  void dispose() {
    _timeUpdateTimer?.cancel();
    _queueSubscription?.cancel();
    _controller.close();
  }
}
