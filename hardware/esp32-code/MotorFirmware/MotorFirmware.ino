#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "MotorController.h"
#include "secrets.h" // <--- Importa suas senhas seguras

// --- PINAGEM DO HARDWARE ---
// Ajuste estes pinos conforme a sua montagem física no ESP32
#define PIN_RPWM 26  // Rotação Direita (PWM)
#define PIN_LPWM 27  // Rotação Esquerda (PWM)
#define PIN_EN   14  // Enable (Habilita a ponte H)
#define PIN_HALL 34  // Sensor Hall (Entrada de pulso)

// --- OBJETOS GLOBAIS ---
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Inicializa o controlador do motor (definido nos outros arquivos da biblioteca)
MotorController motor(PIN_RPWM, PIN_LPWM, PIN_EN, PIN_HALL);

// Variáveis de controle de tempo e estado
unsigned long sendDataPrevMillis = 0;
float currentThrottle = 0.0;

// --- INTERRUPÇÃO ---
// Esta função é chamada automaticamente sempre que o ímã passa pelo sensor
void IRAM_ATTR isr() {
  motor.handleInterrupt();
}

void setup() {
  Serial.begin(115200);
  
  // 1. Inicializa Hardware
  motor.begin();
  attachInterrupt(digitalPinToInterrupt(PIN_HALL), isr, RISING);

  // 2. Conecta ao WiFi (Usando credenciais do secrets.h)
  WiFi.begin(SECRET_WIFI_SSID, SECRET_WIFI_PASS);
  Serial.print("Conectando ao WiFi");
  
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Conectado! IP: ");
  Serial.println(WiFi.localIP());

  // 3. Configura Firebase (Usando credenciais do secrets.h)
  config.api_key = SECRET_API_KEY;
  config.database_url = SECRET_DATABASE_URL;
  
  // Tenta fazer login anônimo
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase conectado com sucesso!");
  } else {
    Serial.printf("Erro na conexão Firebase: %s\n", config.signer.tokens.error.message.c_str());
  }
  
  // Inicializa biblioteca do Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // O ESP32 precisa "manter" a conexão viva
  if (!Firebase.ready()) return;

  // --- TAREFA 1: LER COMANDOS (Do App para o Motor) ---
  // Verifica se o valor do acelerador mudou no banco de dados
  if (Firebase.RTDB.getFloat(&fbdo, "/control/throttle")) {
    float newThrottle = fbdo.floatData();
    
    // Só atualiza o motor se houver mudança real (evita processamento inútil)
    // O threshold 0.01 evita jitter (pequenas variações de ruído)
    if (abs(newThrottle - currentThrottle) > 0.01) {
      currentThrottle = newThrottle;
      motor.setThrottle(currentThrottle);
      
      Serial.print("Comando recebido - Throttle: ");
      Serial.println(currentThrottle * 100); // Mostra em % no serial
    }
  }

  // --- TAREFA 2: ENVIAR TELEMETRIA (Do Motor para o App) ---
  // Envia dados a cada 200ms (5 vezes por segundo) para não travar a rede
  if (millis() - sendDataPrevMillis > 200) {
    sendDataPrevMillis = millis();
    
    // Coleta dados reais da biblioteca do motor
    float rpm = motor.getRPM();
    float power = motor.estimatePower();
    
    // Prepara o pacote JSON
    FirebaseJson json;
    json.set("rpm", rpm);
    json.set("power", power);
    // Eficiência por enquanto é simulada ou calculada fixo, pois precisa de sensor de torque
    json.set("efficiency", (rpm > 10) ? 88.5 : 0.0); 
    json.set("timestamp", millis()); // Útil para debugar latência

    // Envia para o caminho /telemetry
    if (Firebase.RTDB.setJSON(&fbdo, "/telemetry", &json)) {
      // Sucesso no envio
    } else {
      // Se falhar, imprime o motivo (ex: sem internet)
      Serial.print("Erro envio: ");
      Serial.println(fbdo.errorReason());
    }
  }
}
