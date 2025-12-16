// ================================
// PINOS
// ================================
#define PWM_PIN   4
#define LWM_PIN   5
#define HALL_PIN  10

// ================================
// CONFIGURAÇÕES
// ================================
#define PWM_FREQ  1000
#define PWM_RES   8
#define RPM_MAX   169
#define TEMPO_MEDICAO_MS 3000   // 3 segundos

// ================================
// VARIÁVEIS
// ================================
volatile unsigned long pulsos = 0;

int velocidadeSet = -1;
bool medindo = false;
unsigned long inicioMedicao = 0;

// ================================
// INTERRUPÇÃO HALL
// ================================
void ARDUINO_ISR_ATTR contarPulso() {
  pulsos++;
}

// ================================
// SETUP
// ================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(PWM_PIN, OUTPUT);
  pinMode(LWM_PIN, OUTPUT);
  digitalWrite(LWM_PIN, LOW);

  pinMode(HALL_PIN, INPUT_PULLUP);

  ledcAttach(PWM_PIN, PWM_FREQ, PWM_RES);
  ledcWrite(PWM_PIN, 0);

  attachInterrupt(digitalPinToInterrupt(HALL_PIN), contarPulso, FALLING);

  Serial.println("Digite a velocidade (0 a 100):");
}

// ================================
// LOOP
// ================================
void loop() {

  // ---- Entrada do usuário ----
  if (Serial.available()) {
    int v = Serial.parseInt();
    while (Serial.available()) Serial.read();

    if (v >= 0 && v <= 100 && v != velocidadeSet) {
      velocidadeSet = v;

      int pwm = map(v, 0, 100, 0, 255);
      ledcWrite(PWM_PIN, pwm);

      // prepara medição
      pulsos = 0;
      inicioMedicao = millis();
      medindo = true;

      Serial.print("\nVelocidade definida: ");
      Serial.print(v);
      Serial.println("%");
      Serial.println("Medindo por 3 segundos...");
    }
  }

  // ---- Fim da medição ----
  if (medindo && millis() - inicioMedicao >= TEMPO_MEDICAO_MS) {

    noInterrupts();
    unsigned long p = pulsos;
    interrupts();

    // RPM médio em 3s
    float rpmReal = (p * 60.0) / (TEMPO_MEDICAO_MS / 1000.0);
    float rpmIdeal = (velocidadeSet / 100.0) * RPM_MAX;

    float eficiencia = 0;
    if (rpmIdeal > 0) {
      eficiencia = (rpmReal / rpmIdeal) * 100.0;
    }

    Serial.println("\n--- RESULTADO ---");
    Serial.print("RPM Real (medio): ");
    Serial.println(rpmReal, 1);
    Serial.print("RPM Ideal: ");
    Serial.println(rpmIdeal, 1);
    Serial.print("Eficiencia: ");
    Serial.print(eficiencia, 1);
    Serial.println("%");
    Serial.println("-----------------\n");

    medindo = false; // só mede novamente se mudar a porcentagem
  }
}

