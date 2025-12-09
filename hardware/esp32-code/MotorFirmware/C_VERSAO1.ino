// ========================================
// CÓDIGO FUNCIONANDO - ESP32-C6
// ========================================

const int PWM_PIN = 4;      // PWM - velocidade
const int LWM_PIN = 5;      // NÃO VAMOS USAR (deixar em LOW)
const int HALL_PIN = 22;     // Sensor Hall KY-003

// Configurações PWM
const int freq = 1000;      // 1 kHz
const int resolution = 8;   // 0-255

// Motor
const int RPM_MAX = 169;

// Variáveis
volatile unsigned long pulsos = 0;
unsigned long ultimaMedida = 0;
int velocidadeAtual = 0;

// Interrupção do sensor Hall
void ARDUINO_ISR_ATTR contarPulso() {
  pulsos++;
}

void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n========================================");
  Serial.println("   CONTROLE DE MOTOR + RPM");
  Serial.println("========================================");
  Serial.println("Comandos:");
  Serial.println("  0-100 : Velocidade (%)");
  Serial.println("  T     : Testa Hall (gire motor manual)");
  Serial.println("  H     : Estado atual do Hall");
  Serial.println("========================================\n");
  
  // Configuração dos pinos
  pinMode(PWM_PIN, OUTPUT);
  pinMode(LWM_PIN, OUTPUT);
  digitalWrite(LWM_PIN, LOW);  // IMPORTANTE: LOW para funcionar!
  
  // PWM
  if (ledcAttach(PWM_PIN, freq, resolution)) {
    Serial.println("✓ PWM OK no pino 4");
  } else {
    Serial.println("✗ ERRO no PWM");
  }
  
  // Sensor Hall
  pinMode(HALL_PIN, INPUT_PULLUP);
  int estado = digitalRead(HALL_PIN);
  Serial.print("✓ Hall pino 6 - Estado inicial: ");
  Serial.println(estado ? "HIGH" : "LOW");
  
  attachInterrupt(digitalPinToInterrupt(HALL_PIN), contarPulso, FALLING);
  Serial.println("✓ Interrupção FALLING configurada");
  
  // Motor parado
  ledcWrite(PWM_PIN, 0);
  
  Serial.println("\n✓ Sistema pronto!");
  Serial.println("Digite 50 para testar motor a 50%\n");
  
  ultimaMedida = millis();
}

void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    cmd.toUpperCase();
    
    // TESTE DO HALL
    if (cmd == "T") {
      Serial.println("\n===== TESTE HALL (10 seg) =====");
      Serial.println("GIRE O MOTOR MANUALMENTE!\n");
      
      pulsos = 0;
      unsigned long inicio = millis();
      int anterior = digitalRead(HALL_PIN);
      int mudancas = 0;
      
      while (millis() - inicio < 10000) {
        int atual = digitalRead(HALL_PIN);
        if (atual != anterior) {
          mudancas++;
          Serial.print(mudancas);
          Serial.print(". [");
          Serial.print((millis() - inicio) / 1000.0, 1);
          Serial.print("s] ");
          Serial.print(anterior ? "HIGH" : "LOW");
          Serial.print(" → ");
          Serial.println(atual ? "HIGH" : "LOW");
          anterior = atual;
        }
        delay(1);
      }
      
      Serial.println("\n===== RESULTADO =====");
      Serial.print("Mudanças: ");
      Serial.println(mudancas);
      Serial.print("Pulsos (interrupção): ");
      Serial.println(pulsos);
      
      if (mudancas == 0) {
        Serial.println("\n✗ PROBLEMA NO SENSOR!");
        Serial.println("Verifique:");
        Serial.println("  • Pino 6 conectado?");
        Serial.println("  • VCC do sensor ligado?");
        Serial.println("  • GND comum?");
      } else {
        Serial.println("\n✓ SENSOR FUNCIONA!");
        if (pulsos < mudancas / 3) {
          Serial.println("Poucos pulsos capturados");
          Serial.println("Troque FALLING → RISING");
        }
      }
      Serial.println("=====================\n");
      pulsos = 0;
    }
    // ESTADO ATUAL DO HALL
    else if (cmd == "H") {
      int e = digitalRead(HALL_PIN);
      Serial.print("Hall agora: ");
      Serial.println(e ? "HIGH (1)" : "LOW (0)");
    }
    // VELOCIDADE 0-100
    else {
      int valor = cmd.toInt();
      if (valor >= 0 && valor <= 100) {
        velocidadeAtual = valor;
        int pwm = map(valor, 0, 100, 0, 255);
        ledcWrite(PWM_PIN, pwm);
        
        Serial.print("✓ Velocidade: ");
        Serial.print(valor);
        Serial.print("% (PWM=");
        Serial.print(pwm);
        Serial.println(")");
      } else {
        Serial.println("✗ Digite: 0-100, T ou H");
      }
    }
  }
  
  // RPM a cada 1 segundo
  if (millis() - ultimaMedida >= 1000) {
    noInterrupts();
    unsigned long p = pulsos;
    pulsos = 0;
    interrupts();
    
    if (velocidadeAtual > 0) {
      float rpmReal = p * 60.0;
      float rpmIdeal = (velocidadeAtual / 100.0) * RPM_MAX;
      
      Serial.print("RPM Ideal: ");
      Serial.print(rpmIdeal, 1);
      Serial.print(" | Real: ");
      Serial.print(rpmReal, 1);
      Serial.print(" | Pulsos/s: ");
      Serial.println(p);
      
      if (p == 0 && velocidadeAtual > 30) {
        Serial.println("MOTOR GIRANDO MAS SEM PULSOS!");
        Serial.println("   Digite T para testar sensor");
      }
    }
    
    ultimaMedida = millis();
  }
}