# Olhos na Estrada
### Sistema de Navegação Assistida para Motociclistas com Head-Up Display e Integração IoT

Este repositório contém o código-fonte do aplicativo móvel desenvolvido em **Flutter** e **Dart** para o projeto de fim de curso (TCC).

## 🚀 Funcionalidades Implementadas
* **Cálculo de Rotas em Tempo Real:** Integração com as APIs do Google Maps e Google Directions.
* **Modo Offline:** Sistema de cache de rotas para navegação estável sem cobertura de internet.
* **Comunicação BLE:** Transmissão de instruções de navegação a cada 3 segundos via Bluetooth Low Energy para o microcontrolador ESP32-C3.
* **Serviço em Segundo Plano:** Utilização de Foreground Service para manter o app operacional com a tela apagada.
* **Internacionalização (i18n):** Suporte nativo para 4 idiomas (Português, Inglês, Espanhol e Mandarim).
* **Sistema de LEDs Funcionais:** Lógica para controle redundante de 10 LEDs com cores indicativas para aumentar a segurança do motociclista.

## 🛠️ Tecnologias Utilizadas
* **Software:** Flutter, Dart, Android SDK, Git.
* **Hardware Integrado:** ESP32-C3, Displays OLED (SSD1306/SSD1309).
