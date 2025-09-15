# Sistema de Controle de Motor Elétrico - Sistemas Embarcados

Sistema de controle e monitoramento de motor elétrico via aplicativo web/mobile, desenvolvido para a disciplina Sistemas Embarcados.

## 🎯 Objetivos

- Controlar velocidade de rotação do motor via aplicativo
- Medir e visualizar métricas de rotação em tempo real
- Permitir acesso público controlado via WiFi
- Demonstrar integração hardware-software

## 🏗️ Estrutura do Projeto

```
motor-eletrico-embarcados/
├── software/
│   └── flutter_app/          # Aplicativo Flutter
├── hardware/
│   └── esp32-code/           # Código do ESP32
├── docs/                     # Documentação
├── assets/                   # Imagens, diagramas, etc.
└── README.md
```

## 🔧 Componentes Hardware

- **Motor:** GA25-370 (169 RPM @ 6V)
- **Driver:** BTS7960 H-Bridge
- **Microcontrolador:** ESP32-WROOM-32 DevKit
- **Sensor:** KY-003 Hall Effect Sensor
- **Alimentação:** Bateria 12V com reguladores

## 💻 Stack Software

- **Frontend:** Flutter
- **Backend:** Node.js (no ESP32)
- **Comunicação:** WebSockets/HTTP
- **Banco de Dados:** SQLite local

## 👥 Equipe

### Hardware
- **Talita** - Controle do motor e sensores
- **Charles** - Sistema de alimentação e WiFi

### Software
- **Paulo** - Interface de controle
- **Rafael** - Sistema de métricas e fila de usuários

## 🚀 Como Executar

### Hardware (ESP32)
```bash
cd hardware/esp32-code
# Instruções para upload do código
```

### Software (Flutter)
```bash
cd software/flutter_app
flutter pub get
flutter run
```

## 📋 Funcionalidades

### Controle
- ✅ Controle de velocidade via slider
- ✅ Botão de emergência/parada
- ✅ Direção (horária/anti-horária)

### Monitoramento
- ✅ RPM em tempo real
- ✅ Consumo de energia
- ✅ Gráficos históricos
- ✅ Eficiência energética

### Acesso
- ✅ Sistema de fila de usuários
- ✅ QR Code para acesso rápido
- ✅ Interface responsiva

## 🔄 Fluxo de Controle

```
App Flutter → WiFi → ESP32 → BTS7960 → Motor GA25-370 → Sensor → ESP32 → App Flutter
```

## 📊 Status do Projeto

- [x] Definição da arquitetura
- [ ] Desenvolvimento do hardware
- [ ] Desenvolvimento do software
- [ ] Integração hardware-software
- [ ] Testes finais

## 📄 Licença

Este projeto é desenvolvido para fins educacionais na disciplina de Sistemas Embarcados.
