#ifndef MOTOR_CONTROLLER_H
#define MOTOR_CONTROLLER_H

#include <Arduino.h>

class MotorController {
  private:
    // Pinos do Driver BTS7960
    int _rpwm_pin; // Rotação Direita (PWM)
    int _lpwm_pin; // Rotação Esquerda (PWM)
    int _en_pin;   // Enable (R_EN e L_EN juntos)
    
    // Sensor Hall
    int _sensor_pin;
    
    // Variáveis para cálculo de RPM
    volatile long _pulse_count;
    unsigned long _last_time;
    float _current_rpm;

  public:
    MotorController(int rpwm, int lpwm, int en, int sensor);
    
    void begin();
    
    // Define a potência (0.0 a 1.0)
    void setThrottle(float value);
    
    // Função de interrupção (chamar na ISR)
    void handleInterrupt();
    
    // Calcula e retorna o RPM atual
    float getRPM();
    
    // Estima a potência consumida (baseada no modelo do motor GA25-370)
    float estimatePower();
};

#endif
