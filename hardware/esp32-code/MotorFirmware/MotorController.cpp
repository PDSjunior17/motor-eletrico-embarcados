#include "MotorController.h"

MotorController::MotorController(int rpwm, int lpwm, int en, int sensor) {
  _rpwm_pin = rpwm;
  _lpwm_pin = lpwm;
  _en_pin = en;
  _sensor_pin = sensor;
  _pulse_count = 0;
  _current_rpm = 0.0;
  _last_time = 0;
}

void MotorController::begin() {
  pinMode(_rpwm_pin, OUTPUT);
  pinMode(_lpwm_pin, OUTPUT);
  pinMode(_en_pin, OUTPUT);
  pinMode(_sensor_pin, INPUT_PULLUP);
  
  // Ativa o driver
  digitalWrite(_en_pin, HIGH);
  digitalWrite(_lpwm_pin, LOW); // Vamos girar apenas em um sentido por enquanto
}

void MotorController::setThrottle(float value) {
  // Garante limites entre 0.0 e 1.0
  if (value < 0) value = 0;
  if (value > 1) value = 1;
  
  // Converte 0.0-1.0 para 0-255 (PWM do Arduino)
  int pwmValue = (int)(value * 255);
  
  // Aplica ao pino de rotação direita
  analogWrite(_rpwm_pin, pwmValue);
}

void MotorController::handleInterrupt() {
  _pulse_count++;
}

float MotorController::getRPM() {
  unsigned long current_time = millis();
  
  // Calcula RPM a cada 100ms para ter estabilidade
  if (current_time - _last_time >= 100) {
    // GA25-370 com encoder: Quantos pulsos por volta? 
    // Geralmente ~11 pulsos x Redução. Vamos assumir 1 pulso por volta (Hall simples com ímã no eixo)
    // Ajuste PULSES_PER_REV conforme seu hardware real!
    float PULSES_PER_REV = 1.0; 
    
    // Fórmula: (Pulsos / PulsosPorVolta) / (TempoMinutos)
    float revolutions = (float)_pulse_count / PULSES_PER_REV;
    float time_minutes = (current_time - _last_time) / 60000.0;
    
    _current_rpm = revolutions / time_minutes;
    
    // Reseta contadores
    _pulse_count = 0;
    _last_time = current_time;
  }
  
  return _current_rpm;
}

float MotorController::estimatePower() {
  // Simulação baseada na curva do GA25-370 (aprox. 3W em carga máxima)
  if (_current_rpm < 5) return 0.0;
  return (_current_rpm / 169.0) * 2.5; 
}
